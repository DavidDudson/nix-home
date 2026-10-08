{
  lib,
  pkgs,
  fenix,
  ...
}:

let
  fenixPkgs = fenix.packages.${pkgs.stdenv.hostPlatform.system};
  rust-toolchain = fenixPkgs.combine [
    (fenixPkgs.stable.withComponents [
      "cargo"
      "clippy"
      "rust-src"
      "rustc"
      "rustfmt"
    ])
    fenixPkgs.targets.wasm32-unknown-unknown.stable.rust-std
    fenixPkgs.targets.wasm32-wasip2.stable.rust-std
  ];

  # nixpkgs' tracy_latest is still 0.13.1, which no longer compiles: its
  # vendored robin_hood header never includes <cstdint> and GCC 16 stopped
  # providing it transitively. Upstream fixed that in 0.14.1, so bump to the
  # release instead of backporting the include. 0.14.1 keeps the same
  # subproject layout, so only src and the vendored CPM pins move — per
  # cmake/vendor.cmake: ImGui v1.92.5 -> v1.92.9b, capstone Alpha5 -> Alpha10,
  # usearch v2.21.3 -> v2.26.0. Drop once nixpkgs ships tracy >= 0.14.1.
  tracyCpmSrcs = [
    (pkgs.fetchFromGitHub {
      name = "ImGui";
      owner = "ocornut";
      repo = "imgui";
      rev = "v1.92.9b-docking";
      hash = "sha256-PknWLxYuXQ73TCFN+eKOJDNLGbg/ZqKSF6mFxkJG6vI=";
    })
    # Must be the exact rev vendor.cmake pins: tracy applies its own
    # cmake/nfd-xdg-foreign-v2.patch on top, and that patch does not apply to
    # the rev nixpkgs' nativefiledialog-extended ships.
    (pkgs.fetchFromGitHub {
      name = "nfd";
      owner = "btzy";
      repo = "nativefiledialog-extended";
      rev = "3cd252a8f7ca32419b1ca235c2990ba6a0ecba7c";
      # The patch builds xdg-foreign-unstable-v2.xml out of nfd's own
      # 3ps/wayland-protocols submodule, so the submodules are required.
      fetchSubmodules = true;
      hash = "sha256-BV4FdH+AfNXAbLfipBPMGkJmggo59Kf4NIgKQ0hsB9g=";
    })
    (pkgs.fetchFromGitHub {
      name = "PPQSort";
      owner = "GabTux";
      repo = "PPQSort";
      rev = "v1.0.6";
      hash = "sha256-HgM+p2QGd9C8A8l/VaEB+cLFDrY2HU6mmXyTNh7xd0A=";
    })
    # Transitive from PPQSort
    (pkgs.fetchFromGitHub {
      name = "PackageProject.cmake";
      owner = "TheLartians";
      repo = "PackageProject.cmake";
      rev = "v1.11.1";
      hash = "sha256-E7WZSYDlss5bidbiWL1uX41Oh6JxBRtfhYsFU19kzIw=";
    })
    # 0.13.1 resolved md4c with find_package against nixpkgs' md4c; 0.14.1's
    # newer bundled CPM no longer finds it, so vendor the pinned rev instead.
    (pkgs.fetchFromGitHub {
      name = "md4c";
      owner = "mity";
      repo = "md4c";
      rev = "65c6c9d72cebd9a731aaa5597414ce04d9ea5de3";
      hash = "sha256-UMIebye8pQkiTjhbz3btTqPapzoqOnPHrtbPitc717A=";
    })
    (pkgs.fetchFromGitHub {
      name = "capstone";
      owner = "capstone-engine";
      repo = "capstone";
      rev = "6.0.0-Alpha10";
      hash = "sha256-b+QPfS/EhTulAZSvBNw5LTcnM2Wo/Fk8xXYxoeu6S80=";
    })
    (pkgs.fetchFromGitHub {
      name = "base64";
      owner = "aklomp";
      repo = "base64";
      rev = "v0.5.2";
      hash = "sha256-dIaNfQ/znpAdg0/vhVNTfoaG7c8eFrdDTI0QDHcghXU=";
    })
    (pkgs.fetchFromGitHub {
      name = "usearch";
      owner = "unum-cloud";
      repo = "usearch";
      rev = "v2.26.0";
      fetchSubmodules = true;
      hash = "sha256-FsU/e8Aq+ARWV94c8MNJPL/edkde1Lj0cA3dOVrrm/0=";
    })
  ];

  # Shadows pkgs.tracy inside the `with pkgs` list below.
  tracy = pkgs.tracy.overrideAttrs (old: {
    version = "0.14.1";

    # 0.14.1 changed the desktop entry to `Exec=tracy-profiler %f`, so the
    # --replace-fail for `Exec=/usr/bin/tracy` in nixpkgs' postInstall no
    # longer matches. Normalise it back so that substitution still resolves to
    # the installed binary name, which is `tracy`.
    postPatch = (old.postPatch or "") + ''
      substituteInPlace extra/desktop/tracy.desktop \
        --replace-fail "Exec=tracy-profiler %f" "Exec=/usr/bin/tracy %f"
    '';
    src = pkgs.fetchFromGitHub {
      # postUnpack reads ./tracy/cmake/CPM.cmake, so the source root must
      # still unpack as `tracy` rather than the default `source`.
      name = "tracy";
      owner = "wolfpld";
      repo = "tracy";
      rev = "v0.14.1";
      hash = "sha256-vcLI9jb7eYcR162LgBQ2P4A0oiZuYRfYRQiDhlAk5TI=";
    };
    postUnpack = lib.concatLines (
      map (
        s:
        ''
          cp -R ${s.out} ${s.name}
          chmod -R u+w ${s.name}
          appendToVar cmakeFlags -DCPM_${s.name}_SOURCE=$(pwd)/${s.name}
        ''
        # PPQSort tries to download CPM.cmake; give it tracy's copy instead
        + lib.optionalString (s.name == "PPQSort") ''
          cp ./tracy/cmake/CPM.cmake PPQSort/cmake/CPM.cmake
        ''
      ) tracyCpmSrcs
    );
  });
in
{
  environment.systemPackages = with pkgs; [
    # Editors & IDEs
    vim
    helix
    zed-editor

    # Version Control
    git
    lazygit

    # Language Servers & Tools
    mcp-language-server # Universal LSP-to-MCP bridge (configure per-project via .mcp.json)
    nixd
    nil
    marksman
    taplo
    vscode-langservers-extracted
    wgsl-analyzer # WGSL shader LSP

    # Rust Development
    rust-toolchain
    fenixPkgs.rust-analyzer
    clang
    llvmPackages.bintools

    # Cargo Tools
    cargo-audit # Security vulnerability checker
    cargo-bloat # Binary size analyzer
    cargo-deny # Dependency linter (licenses, advisories, duplicates)
    cargo-edit # cargo add/rm/upgrade
    cargo-expand # Macro expansion viewer
    cargo-flamegraph # Profiling flamegraphs
    cargo-generate # Project scaffolding from templates
    cargo-machete # Detect unused dependencies
    cargo-make # Task runner
    cargo-nextest # Faster test runner
    cargo-outdated # Show outdated dependencies
    cargo-release # Release workflow automation
    cargo-udeps # Find unused dependencies (thorough, needs nightly)
    cargo-update # Keep cargo-installed binaries up to date
    cargo-criterion # Rigorous benchmarking for performance-critical systems
    cargo-watch # Auto-rebuild on file changes

    # Game Development
    tracy # Frame profiler with first-class Bevy integration
    renderdoc # GPU frame debugger for custom shaders and render passes

    # WASM Tooling
    trunk # WASM dev server with hot reload
    wasm-bindgen-cli
    wasm-pack
    # wasm-server-runner: not in nixpkgs, install via `cargo install wasm-server-runner`

    # Document Conversion
    pandoc

    # JavaScript/TypeScript
    bun

    # AI Tools
    amazon-q-cli
    antigravity-cli
    claude-code
  ];

  environment.sessionVariables = {
    LIBCLANG_PATH = "${pkgs.llvmPackages_latest.libclang.lib}/lib";
  };
}
