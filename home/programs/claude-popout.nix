{ pkgs, config, ... }:

let
  # Source repo lives outside the flake — kept editable so the TUI can
  # iterate without a rebuild. The wrapper just runs bun against it.
  repoPath = "${config.home.homeDirectory}/repos/claude-popout";

  claude-popout = pkgs.writeShellApplication {
    name = "claude-popout";
    runtimeInputs = with pkgs; [ bun ];
    text = ''
      cd "${repoPath}"
      [ -d node_modules ] || bun install --frozen-lockfile >&2
      exec bun run src/index.tsx "$@"
    '';
  };

  claude-popout-toggle = pkgs.writeShellApplication {
    name = "claude-popout-toggle";
    runtimeInputs = with pkgs; [
      jq
      ghostty
    ];
    text = ''
      # Ghostty's --class must be a valid GTK app-id (reverse-DNS form);
      # plain "claude-popout" is silently rejected and the window inherits
      # the default ghostty class. Use a namespaced id and match on it.
      if hyprctl clients -j | jq -e '.[] | select(.class == "com.popout.claude")' >/dev/null; then
        hyprctl dispatch togglespecialworkspace claude
      else
        setsid ghostty --class=com.popout.claude --title=claude-popout -e claude-popout >/dev/null 2>&1 < /dev/null &
        disown
      fi
    '';
  };
in
{
  home.packages = [
    claude-popout
    claude-popout-toggle
  ];
}
