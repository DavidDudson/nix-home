_:

{
  programs.git = {
    enable = true;
    includes = [ { path = ./config; } ];
  };

  programs.delta = {
    enable = true;
    enableGitIntegration = true;
  };
}
