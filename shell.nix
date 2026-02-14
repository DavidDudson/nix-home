{
  pkgs ? import <nixpkgs> { },
}:

pkgs.mkShell {
  packages = with pkgs; [
    deadnix
    nixfmt
    shellcheck
    statix
  ];

  shellHook = ''
    git config core.hooksPath .githooks
  '';
}
