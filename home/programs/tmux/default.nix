{ pkgs, overbridge, ... }:

{
  programs.tmux = {
    enable = true;
    mouse = true;
    terminal = "tmux-256color";
    baseIndex = 0;
    escapeTime = 10;
    # No prefix, no status bar: no key is taken from the apps in the panes.
    extraConfig = builtins.readFile ./tmux.conf;
  };

  # Multi-repo workspaces laid out in tmux (github.com/DavidDudson/overbridge; `ws` is an alias)
  home.packages = [ overbridge.packages.${pkgs.stdenv.hostPlatform.system}.default ];

  # Nushell does not load home.sessionVariables, so it gets its own copy.
  home.sessionVariables.OVERBRIDGE_MUX = "tmux";
  programs.nushell.environmentVariables.OVERBRIDGE_MUX = "tmux";
}
