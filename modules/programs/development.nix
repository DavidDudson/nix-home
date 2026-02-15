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

    # JavaScript/TypeScript
    bun

    # AI Tools
    amazon-q-cli
    claude-code
  ];

  environment.sessionVariables = {
    LIBCLANG_PATH = "${pkgs.llvmPackages_latest.libclang.lib}/lib";
  };
}
