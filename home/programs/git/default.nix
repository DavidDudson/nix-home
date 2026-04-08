_:

{
  programs.git = {
    enable = true;
    signing.format = null;
    includes = [ { path = ./config; } ];
  };

  programs.delta = {
    enable = true;
    enableGitIntegration = true;
  };
}
