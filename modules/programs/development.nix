{ config, lib, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # Editors & IDEs
    vim
    helix
    zed-editor
    code-cursor

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
    jetbrains.rust-rover

    # AI Tools
    amazon-q-cli
    claude-code
  ];
}
