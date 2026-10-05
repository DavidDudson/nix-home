{ pkgs, ... }:

let
  pythonEnv = pkgs.python3.withPackages (
    ps: with ps; [
      mcp
      httpx
      websockets
      # Palette conforming and pixel-grid downscaling run on the CPU here
      # rather than as ComfyUI nodes — it is exact integer work, and keeping it
      # local means it also applies to art that came from anywhere else.
      pillow
      numpy
    ]
  );

  gameart-mcp = pkgs.writeShellApplication {
    name = "gameart-mcp";
    runtimeInputs = [ pythonEnv ];
    text = ''
      export GAMEART_PALETTES="''${GAMEART_PALETTES:-${./palettes.json}}"
      exec ${pythonEnv}/bin/python ${./server.py} "$@"
    '';
  };
in
{
  home.packages = [ gameart-mcp ];
}
