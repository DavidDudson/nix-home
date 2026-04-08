{ pkgs, fenix, ... }:

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
  ];
in
{
  environment.systemPackages = with pkgs; [
    # Editors & IDEs
    vim
    helix
    zed-editor

    # Version Control
    git
    gh
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
    jetbrains.rust-rover

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
    claude-code
    gemini-cli
  ];

  environment.sessionVariables = {
    LIBCLANG_PATH = "${pkgs.llvmPackages_latest.libclang.lib}/lib";
  };
}
