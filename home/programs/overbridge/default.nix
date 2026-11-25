{ pkgs, ... }:

let
  yaml = pkgs.formats.yaml { };

  config = {
    version = 1;

    # @prs and @reviews only search these owners.
    github-orgs = [ "DavidDudson" ];

    skill-extensions = [ "~/.config/overbridge/skill-extensions" ];

    # Applies to every workspace's Claude. Activation is for the user.
    guard.deny = [
      {
        pattern = ''(^|[;&|(])\s*sudo\b'';
        reason = "sudo needs a password; hand the command to the user to run";
      }
    ];

    # Per-repo dev shells beat the direnv default below.
    repos = {
      nix-home.shell = "nix develop -f shell.nix --command";
      overbridge.shell = "nix develop --command";
    };

    defaults = {
      shell = "direnv exec .";

      # Applies to repos without their own overbridge.yml.
      ide = "zed";

      # 28 cores: the stock limits (70% load, 180s) would kill long nix
      # builds and leave most of the machine idle.
      check-queue = {
        max-load-percent = 200;
        max-parallel = 8;
        timeout-seconds = 1800;
        stall-seconds = 900;
        wait-seconds = 3600;
      };

      # Sidebar hint only; nothing is iceboxed automatically.
      icebox.idle-days = 7;

      hooks = {
        post-add = "if [ -f .envrc ]; then direnv allow; fi";

        # Refuse to remove a workspace holding commits that exist on no remote.
        # `overbridge rm --force` overrides.
        pre-remove = ''
          unpushed=$(git log --branches --not --remotes --oneline)
          if [ -n "$unpushed" ]; then
            echo "$OVERBRIDGE_REPO has unpushed commits:" >&2
            echo "$unpushed" >&2
            exit 1
          fi
        '';

        post-pr = ''notify-send "overbridge" "$OVERBRIDGE_REPO: PR #$OVERBRIDGE_PR recorded for $OVERBRIDGE_NAME"'';
      };

      buttons = [
        {
          id = "pr";
          label = "PR";
          side = "left";
          url = "https://github.com/DavidDudson/{repo}/pull/{pr}";
          # Hidden until the branch has a PR.
          status = ''[ -n "$OVERBRIDGE_PR" ] && echo "#$OVERBRIDGE_PR"'';
        }
        {
          id = "ci";
          label = "CI";
          side = "left";
          url = "https://github.com/DavidDudson/{repo}/pull/{pr}/checks";
          status = ''
            [ -n "$OVERBRIDGE_PR" ] || exit 0
            gh pr checks "$OVERBRIDGE_PR" --json bucket --jq '
              if any(.[]; .bucket == "fail") then {text: "failing", color: "red"}
              elif any(.[]; .bucket == "pending") then {text: "running", color: "yellow"}
              elif length > 0 then {text: "passing", color: "green"}
              else empty end'
          '';
        }
        {
          id = "check";
          label = "Check";
          run = ''
            cmd=$(overbridge config get commands.lint || overbridge config get commands.test) || exit 0
            if overbridge check -- sh -c "$cmd"; then
              notify-send "overbridge check" "$OVERBRIDGE_REPO passed"
            else
              notify-send -u critical "overbridge check" "$OVERBRIDGE_REPO failed"
            fi
          '';
        }
      ];
    };
  };
in
{
  # Root config for overbridge workspaces (OVERBRIDGE_ROOT defaults to ~/workspaces).
  home.file."workspaces/config.yml".source = yaml.generate "overbridge-config.yml" config;

  # Skill extensions kept in the dots; see ext/README.md.
  xdg.configFile."overbridge/skill-extensions".source = ./ext;
}
