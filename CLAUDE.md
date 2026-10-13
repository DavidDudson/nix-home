# Claude Code Environment Guide

Welcome! This is a modular NixOS configuration for
DavidDudsonPC. This guide will help you work effectively
with this codebase.

## 🤖 Claude Code Setup

Claude Code is configured lean on purpose: no user-scope
MCP servers, and plugins that duplicate built-ins are off
(`home/mcp/servers.nix`). Use the built-in tools: `gh` and
`git` via Bash, Read/Edit, WebFetch/WebSearch, and
claude-in-chrome for the browser. Opt-in servers (e.g.
gameart) load per session with
`claude --mcp-config ~/.claude/mcp/<name>.json`.

## 📁 Configuration Structure

This is a **modular NixOS configuration** - NOT a single
monolithic file. Understanding this structure is critical:

```text
configuration.nix              ← Entry point (imports only, no config)
├── modules/                   ← System-level configuration
│   ├── programs/             ← All packages organized by category
│   │   ├── development.nix   ← Editors, IDEs, LSPs, dev tools
│   │   ├── terminal.nix      ← Terminal emulators, CLI tools
│   │   ├── browsers.nix      ← Web browsers
│   │   ├── media.nix         ← Media players and tools
│   │   ├── wayland.nix       ← Hyprland/Wayland specific
│   │   └── system-tools.nix  ← System utilities
│   ├── system/               ← Core system settings
│   ├── hardware/             ← Hardware-specific config
│   ├── desktop/              ← Desktop environment
│   └── services/             ← System services
└── home/                      ← User-level configuration (Home Manager)
    ├── programs/             ← User program configs
    │   ├── git.nix           ← Simple configs (single .nix file)
    │   ├── nushell/          ← Programs with config files use directories
    │   │   ├── default.nix   ← Nix module
    │   │   ├── config.nu     ← Config file (real file extension)
    │   │   └── env.nu
    │   ├── zed/
    │   │   ├── default.nix
    │   │   └── settings.json
    │   └── zellij/
    │       ├── default.nix
    │       └── config.kdl
    ├── desktop/              ← User desktop settings
    │   ├── gtk.nix
    │   ├── hyprland/
    │   │   ├── default.nix
    │   │   └── hyprpaper.conf
    │   └── rofi/
    │       ├── default.nix
    │       ├── powermenu.sh
    │       └── audio-sink.sh
    ├── claude/               ← Claude Code global config
    │   └── CLAUDE.md
    └── mcp/                  ← MCP server definitions
```

## ✅ Best Practices

### When Adding Packages

**DO**:

- Add to the appropriate category in `modules/programs/`
- Keep packages alphabetically sorted within sections
- Add comments for non-obvious packages

**DON'T**:

- Add packages to `configuration.nix` directly
- Create new categories without discussion
- Add duplicate packages (check all program files first)

### When Using `home.file` or Program Config Files

**DO**:

- Use `.source` pointing to a sibling file rather than
  inlining content with `.text`
- When a program has config files, convert its `.nix`
  file to a directory with `default.nix` plus the config
  files alongside it
  (e.g. `home/programs/zed/default.nix` + `settings.json`)
- Use the real file extension for config files
  (`.json`, `.kdl`, `.nu`, `.conf`, `.sh`)
- Simple programs with no config files can stay as a single `.nix` file

**DON'T**:

- Inline large text blocks with `.text` — use a separate source file instead
- Put config files in a separate `files/` directory
  — keep them next to their `default.nix`

### When Modifying Configuration

**DO**:

- Edit the specific module file, not the main config
- Run `nh os test .` from the worktree after every change to verify
  it builds and activates
- If the test succeeds, commit the changes
- Keep changes focused and logical
- Format and lint from inside `nix-shell` before every commit — see
  [Formatting and Linting](#-formatting-and-linting)

**DON'T**:

- Make multiple unrelated changes in one commit
- Skip testing before committing
- Hardcode values that should be variables
- Commit without running the linters first
- Trust a passing pre-commit hook that was run outside `nix-shell`

## 🎯 Common Tasks

### Adding a New Package

1. **Determine category**: Is it dev, terminal, media, wayland, or system?
2. **Check if exists**: Use `grep -r "package-name" modules/programs/`
3. **Add to appropriate file**: Keep alphabetical order within sections
4. **Test**: `nh os test .`

### Adding a New MCP Server

Only add one for a capability Claude Code lacks; every
user-scope server costs context in every session. Prefer
an opt-in server: add it to `optInServers` in
`home/mcp/servers.nix`, which writes
`~/.claude/mcp/<name>.json`. For an always-on server,
add it to `userServers` there instead.

**After adding**, rebuild: `nh os test .`

### Modifying System Settings

1. **Identify the module**: Check the imports in `configuration.nix`
2. **Edit the specific module**: Not the main config
3. **Test thoroughly**: System changes can break boot

### Bumping the ws Flake Input

`ws` (the workspace manager) is the `ws` flake input, pinned in
`flake.lock`. It does not float. After every merge to ws `main`, bump
the lock in its own commit and PR:

```sh
nix flake update ws
```

`/upgrade-os` bumps it too, as part of updating every input.

## 🔧 Technical Details

### Package Management

- **System packages**: `modules/programs/*.nix`
- **User packages**: `home/programs/shell.nix` (currently just nodejs for MCP)
- **Home Manager**: Manages user-level configuration

### Shell Environment

- **Default shell**: Nushell
- **Prompt**: Starship
- **Completions**: Carapace

### Desktop Environment

- **Compositor**: Hyprland
- **Display Manager**: greetd
- **Theme**: Orchis-Dark-Compact with Bibata cursors

### Hardware

- **Form factor**: Desktop PC (not a laptop — no battery, lid,
  or mobile power concerns; always mains-powered)
- **Hostname**: DavidDudsonPC
- **GPU**: NVIDIA (latest drivers, open kernel module)
- **Audio**: PipeWire
- **Bluetooth**: Enabled

## 🚀 Encouraged Workflows

### Keep It Modular

- One concern per file
- Related settings grouped together
- Easy to find, easy to modify

## 🧹 Formatting and Linting

**Formatting and linting is a pre-commit step, always.** Never commit
first and clean up after — fix everything before the commit is created.

### The tools live in `nix-shell`

`shell.nix` provides `nixfmt`, `deadnix`, `statix`, `shellcheck`,
`prettier`, `markdownlint`, `jq`, and `yamllint`. Its `shellHook` also
runs `git config core.hooksPath .githooks`, which is what wires up the
pre-commit hook in the first place.

None of these tools are on the system PATH. Outside `nix-shell` they do
not exist.

### The pre-commit hook enters `nix-shell` for you

`.githooks/pre-commit` checks staged files only. If the lint tools are
not on PATH it re-enters `nix-shell` and re-runs itself there, so the
checks happen even when you commit from a plain shell. The first commit
after a `shell.nix` change pays the evaluation cost; after that it is
cached.

It still is not a substitute for running the tools yourself:

- The hook is **check-only** — `nixfmt --check` and `prettier --check`
  report problems but never write. Fixing is still your job.
- If `nix-shell` cannot be entered at all it prints
  `warning: could not enter nix-shell, checks will be limited` and falls
  back to per-tool skip warnings. Treat that line as a failed run, not a
  pass.

### Run this before every commit

Pass the files you actually changed rather than the whole tree:

```sh
nix-shell --run '
  nixfmt CHANGED.nix &&
  deadnix CHANGED.nix &&
  statix check . &&
  shellcheck CHANGED.sh &&
  prettier --write CHANGED.md &&
  markdownlint CHANGED.md
'
```

Notes:

- `statix check` accepts a single target — pass `.`, not a file list
- `prettier` covers `.md`, `.json`, `.yml`/`.yaml`; `.md` gets
  `markdownlint` on top
- Markdown is linted at 80 columns and every fenced block needs a
  language tag
- `prettier --write` rewrites files, so re-run the build afterwards if a
  rewritten file feeds into the config

### Never use `--no-verify`

If the hook fails, fix the cause. Bypassing it lands unformatted code
that the next contributor's hook will trip over.

## 📝 Commit Guidelines

When committing changes:

- **Always** format and lint from inside `nix-shell` first — see
  [Formatting and Linting](#-formatting-and-linting)
- Fix any issues found by the linters before proceeding with the commit
- Use descriptive commit messages
- Reference what was changed and why
- Group related changes together
- Keep the Claude Code co-author attribution

## ⚠️ Important Notes

1. **No local checkout**: the system builds from GitHub `main`
   (`NH_FLAKE=git+ssh://git@github.com/DavidDudson/nix-home`). Edit in a
   ws workspace (`ws checkout nix-home <branch>`); changes reach the
   system only once merged.
2. **State version**: 24.11 (don't change without research)
3. **Flakes enabled**: Experimental features are on
4. **Always test**: Before merging, run `nh os test .` from the worktree

## 🔨 Rebuilding with nh

This project uses **nh** (nix helper) instead of raw
`nixos-rebuild`. It provides colored build output,
automatic diff display, and confirmation prompts.

**Common commands** (`NH_FLAKE` points at GitHub `main`; pass `.` to
build the current worktree instead):

| Command                  | Description                                     |
| ------------------------ | ----------------------------------------------- |
| `nh os switch --refresh` | Build and activate GitHub `main`                |
| `nh os test .`           | Activate this worktree's branch, no boot entry  |
| `nh os build .`          | Build this worktree's branch without activating |
| `nh os boot`             | Build `main` and set as next boot entry         |
| `nh clean all`           | Garbage collect old generations                 |

`--refresh` matters: Nix caches a branch ref for `tarball-ttl` (1 h),
so without it a switch right after a merge can build the old `main`.

**Notes**:

- nh auto-detects the hostname (`DavidDudsonPC`)
- Shows a diff of what changed before applying
- Asks for sudo when needed (no need to prefix with sudo)
- After a merge, `nh os switch --refresh` activates the new `main`

## 💡 Pro Tips

- Use `nix search nixpkgs <package>` to find packages
- Use `nixos-option <option.path>` to see option documentation
- Check `man configuration.nix` for system options
- Check `man home-configuration.nix` for home-manager options
