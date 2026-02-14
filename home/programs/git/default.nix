_:

{
  programs.git = {
    enable = true;
    delta.enable = true;
    includes = [ { path = ./config; } ];
  };
}
