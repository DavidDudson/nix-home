{ pkgs, ... }:

let
  # nixpkgs lags upstream; 0.2.0 adds worktree-aware rebase/sync/navigation,
  # which ws workspaces (one worktree per repo) rely on.
  gh-stack = pkgs.gh-stack.overrideAttrs (
    finalAttrs: old: {
      version = "0.2.0";
      src = pkgs.fetchFromGitHub {
        owner = "github";
        repo = "gh-stack";
        tag = "v${finalAttrs.version}";
        hash = "sha256-70H1kOdvklTeB8OVFg7g6xQ4rn0gqv+zU7yjDYPd3vo=";
      };
      vendorHash = "sha256-Otstml5TSTJeYsP9o94aUperP1MgT2axa/wqALEnXYk=";
      # modifyview's insert-branch tests fail in the build sandbox.
      checkFlags = (old.checkFlags or [ ]) ++ [ "-skip=Insert" ];
      # The vendor FOD inherits the skill-install hook, which needs $pname.
      passthru = old.passthru // {
        overrideModAttrs = pkgs.lib.composeExtensions old.passthru.overrideModAttrs (
          _: _: { dontInstallAgentSkills = true; }
        );
      };
    }
  );
in
{
  programs.gh = {
    enable = true;
    extensions = [ gh-stack ];
    # Git uses ssh; keep gh out of the credential chain.
    gitCredentialHelper.enable = false;
    settings.git_protocol = "https";
  };

  # Upstream agent skill: teaches Claude the non-interactive gh stack flags.
  home.file.".claude/skills/gh-stack".source = "${gh-stack}/share/skills/gh-stack/gh-stack";
}
