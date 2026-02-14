{
  pkgs ? import <nixpkgs> { },
}:

pkgs.mkShell {
  packages = with pkgs; [
    deadnix
    jq
    nixfmt
    nodePackages.markdownlint-cli
    nodePackages.prettier
    shellcheck
    statix
    yamllint
  ];

  shellHook = ''
    git config core.hooksPath .githooks
  '';
}
