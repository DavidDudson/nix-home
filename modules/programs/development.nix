{ pkgs, ... }:

let
  fenix = import (fetchTarball "https://github.com/nix-community/fenix/archive/main.tar.gz") { };
  rust-toolchain = fenix.combine [
    (fenix.stable.withComponents [
      "cargo"
      "clippy"
      "rust-src"
      "rustc"
      "rustfmt"
    ])
    fenix.targets.wasm32-unknown-unknown.stable.rust-std
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
    nixd
    nil
    marksman
    taplo
    vscode-langservers-extracted

    # Rust Development
    rust-toolchain
    fenix.rust-analyzer
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
    cargo-watch # Auto-rebuild on file changes

    # WASM Tooling
    trunk # WASM dev server with hot reload
    wasm-bindgen-cli
    wasm-pack
    # wasm-server-runner: not in nixpkgs, install via `cargo install wasm-server-runner`

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
