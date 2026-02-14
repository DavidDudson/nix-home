_:

{
  programs.zellij = {
    enable = true;
  };

  # Zellij KDL config - Home Manager doesn't have native KDL support
  home.file.".config/zellij/config.kdl".source = ./config.kdl;
}
