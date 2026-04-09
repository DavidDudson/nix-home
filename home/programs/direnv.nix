_:

{
  programs.direnv = {
    enable = true;
    enableNushellIntegration = true;
    nix-direnv.enable = true;
    silent = true;
  };
}
