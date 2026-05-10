{ pkgs, ... }:

let
  pythonEnv = pkgs.python3.withPackages (
    ps: with ps; [
      mcp
      httpx
      websockets
    ]
  );

  gameart-mcp = pkgs.writeShellApplication {
    name = "gameart-mcp";
    runtimeInputs = [ pythonEnv ];
    text = ''
      exec ${pythonEnv}/bin/python ${./server.py} "$@"
    '';
  };
in
{
  home.packages = [ gameart-mcp ];
}
