{
  pkgs ? import <nixpkgs> { },
}:

pkgs.mkShell {
  packages = with pkgs; [
    deadnix
    jq
    nixfmt
    markdownlint-cli
    prettier
    shellcheck
    statix
    yamllint
  ];

  shellHook = ''
    git config core.hooksPath .githooks
  '';
}
