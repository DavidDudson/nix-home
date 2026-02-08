{ pkgs, ... }:

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
    rustup
    clang
    llvmPackages.bintools
    rust-analyzer
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
