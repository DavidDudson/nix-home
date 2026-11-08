{ pkgs, overbridge, ... }:

{
  programs.zellij = {
    enable = true;
  };

  # Multi-repo workspaces laid out in zellij (github.com/DavidDudson/overbridge; `ws` is an alias)
  home.packages = [ overbridge.packages.${pkgs.stdenv.hostPlatform.system}.default ];

  # Zellij KDL config - Home Manager doesn't have native KDL support
  home.file.".config/zellij/config.kdl".source = ./config.kdl;
}
