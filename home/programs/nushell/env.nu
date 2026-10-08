$env.EDITOR = "hx"
# Build from GitHub main, not a local checkout. Test a branch with `nh os test .` from its worktree.
$env.NH_FLAKE = "git+ssh://git@github.com/DavidDudson/nix-home"
$env.PATH = ($env.PATH | split row (char esep) | prepend /home/ddudson/.apps | append /usr/bin/env)

# Load secrets cached by fetch-secrets at session start (run via Hyprland exec-once)
let secrets_file = $"($env.HOME)/.config/secrets/secrets.json"
if ($secrets_file | path exists) {
    load-env (open $secrets_file)
}
