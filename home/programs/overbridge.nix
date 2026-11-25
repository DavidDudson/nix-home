{ pkgs, ... }:

let
  yaml = pkgs.formats.yaml { };

  config = {
    version = 1;

    # @prs and @reviews only search these owners.
    github-orgs = [ "DavidDudson" ];

    defaults = {
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
    };
  };
in
{
  # Root config for overbridge workspaces (OVERBRIDGE_ROOT defaults to ~/workspaces).
  home.file."workspaces/config.yml".source = yaml.generate "overbridge-config.yml" config;
}
