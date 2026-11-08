{ pkgs, ... }:

{
  programs.gh = {
    enable = true;
    extensions = [ pkgs.gh-stack ];
    # Git uses ssh; keep gh out of the credential chain.
    gitCredentialHelper.enable = false;
    settings.git_protocol = "https";
  };

  # Upstream agent skill: teaches Claude the non-interactive gh stack flags.
  home.file.".claude/skills/gh-stack".source = "${pkgs.gh-stack}/share/skills/gh-stack/gh-stack";
}
