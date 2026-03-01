{
  pkgs,
  ...
}:

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
    bat # Better cat
    eza # Better ls
    fd # Better find
    fzf # Fuzzy finder
    ripgrep # Better grep
    sd # Better sed
    procs # Better ps
    dust # Better du
    zoxide # Better cd
    just # Task runner
    oxipng # Lossless PNG optimizer for game assets
    tokei # Code statistics
    hyperfine # Benchmarking
    bandwhich # Network monitoring
    nethogs # Per-process network bandwidth

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
