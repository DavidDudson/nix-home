{ pkgs, overbridge, ... }:

{
  programs.tmux = {
    enable = true;
    mouse = true;
    terminal = "tmux-256color";
    baseIndex = 0;
    escapeTime = 10;
    # No prefix, no status bar: no key is taken from the apps in the panes.
    # HM's `prefix` option is left unset; it emits `bind None send-prefix`.
    extraConfig = builtins.readFile ./tmux.conf;
  };

  # Multi-repo workspaces laid out in tmux (github.com/DavidDudson/overbridge; `ws` is an alias)
  home.packages = [ overbridge.packages.${pkgs.stdenv.hostPlatform.system}.default ];

  # overbridge defaults to zellij unless told otherwise. Set through nushell:
  # it does not load home.sessionVariables (loadSessionVariables is false).
  programs.nushell.environmentVariables.OVERBRIDGE_MUX = "tmux";
}
