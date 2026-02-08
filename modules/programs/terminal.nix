{ config, lib, pkgs, ... }:

{
  users.defaultUserShell = pkgs.nushell;

  environment.systemPackages = with pkgs; [
    # Terminal Emulators
    rio

    # Terminal Multiplexers
    zellij

    # Shell & Prompt
    starship

    # CLI Utilities
    bat           # Better cat
    fd            # Better find
    ripgrep       # Better grep
    sd            # Better sed
    procs         # Better ps
    dust          # Better du
    zoxide        # Better cd
    tokei         # Code statistics
    hyperfine     # Benchmarking
    bandwhich     # Network monitoring

    # File Management
    ranger
    yazi

    # System Tools
    curl
    wget
    jq
    lshw
    parted
    nix-du
  ];
}
