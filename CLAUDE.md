# Claude Code Environment Guide

Welcome! This is a modular NixOS configuration for
DavidDudsonPC. This guide will help you work effectively
with this codebase.

## 🤖 Available MCP Servers

This environment has **7 MCP servers** configured.
**USE THEM AGGRESSIVELY** - they're here to make you
more effective!

### 🔍 Context7 MCP

**Use constantly for**: Documentation lookup for ANY
programming language, framework, or tool.

**Always use before**:

- Writing code in an unfamiliar API
- Adding Nix packages or options
- Configuring new tools
- Answering technical questions

**Examples**:

- "Use Context7 to check the latest Rust std::collections HashMap API"
- "Look up Bevy ECS system syntax via Context7"
- "Check the NixOS Hyprland module options"

### 🐙 GitHub MCP

**Use for**: Searching repositories, checking issues,
finding examples, exploring nixpkgs source.

**Great for**:

- Finding example NixOS configurations
- Checking package definitions in nixpkgs
- Looking up Rust crate source code
- Researching how others solve similar problems
- Finding issues/PRs related to bugs you encounter

### 📝 Memory MCP

**Use proactively to**: Persist important project information between sessions.

**Store**:

- Project architecture decisions
- Game mechanics and design choices
- Build/configuration issues and solutions
- Performance optimization notes
- TODOs and future work

**Critical**: At the end of significant work sessions,
explicitly save key learnings to memory!

### 🔀 Git MCP

**Use for**: Advanced git operations beyond basic commands.

**Capabilities**:

- Deep commit history analysis
- Finding when bugs were introduced (git bisect info)
- Analyzing blame and code evolution
- Branch comparison and analysis

### 🌐 Fetch MCP

**Use for**: Making HTTP requests and downloading resources.

**Great for**:

- Testing game APIs during development
- Downloading assets or resources
- Checking external service status
- Validating HTTP endpoints

### 🧠 Sequential Thinking MCP

**Use for**: Complex problem-solving requiring step-by-step reasoning.

**Perfect for**:

- Game architecture planning
- Algorithm design and optimization
- Debugging complex multi-system issues
- Performance analysis and improvements
- Planning major refactors

### 🐧 NixOS MCP

**Use for**: NixOS-specific configuration help and package management.

**Helpful for**:

- Finding the right NixOS options
- Understanding module structure
- Package configuration queries

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
- Use Context7 to verify package names in nixpkgs

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
- Run `nh os switch` after every change to verify it builds and activates
- If the switch succeeds, commit the changes
- Keep changes focused and logical
- Use MCP servers to research options before implementing
- Format and lint from inside `nix-shell` before every commit — see
  [Formatting and Linting](#-formatting-and-linting)

**DON'T**:

- Make multiple unrelated changes in one commit
- Skip testing before committing
- Hardcode values that should be variables
- Commit without running the linters first
- Trust a passing pre-commit hook that was run outside `nix-shell`

### When Using MCP Servers

**MANDATORY MCP USAGE** - Don't skip these:

**Before writing ANY code**:

1. ✅ Use Context7 to look up API documentation
2. ✅ Use GitHub MCP to find real-world examples
3. ✅ Use Sequential Thinking for complex design decisions

**During development**:

1. ✅ Use Git MCP to understand code history
2. ✅ Use Fetch MCP to test APIs
3. ✅ Use Memory MCP to record important decisions

**After completing features**:

1. ✅ Use Memory MCP to persist learnings
2. ✅ Document architectural choices in memory

**Example workflow - Adding tmux**:

1. User: "Add tmux to the system"
2. You: Use Context7 to check tmux NixOS module options
3. You: Use GitHub MCP to find example tmux configs in nixpkgs
4. You: Check `modules/programs/terminal.nix` for duplicates
5. You: Add with proper syntax
6. You: Save configuration pattern to Memory for future reference
7. You: Suggest rebuild and test

**Example workflow - Rust game development**:

1. User: "How should I structure the ECS for this game?"
2. You: Use Sequential Thinking to reason through architecture
3. You: Use Context7 to check Bevy ECS best practices
4. You: Use GitHub MCP to find similar game structures
5. You: Save the architectural decision to Memory
6. You: Implement with confidence

## 🎯 Common Tasks

### Adding a New Package

1. **Determine category**: Is it dev, terminal, media, wayland, or system?
2. **Check if exists**: Use `grep -r "package-name" modules/programs/`
3. **Use Context7**: Verify the package name and any special options
4. **Add to appropriate file**: Keep alphabetical order within sections
5. **Test**: `nh os switch`

### Adding a New MCP Server

Edit `home/mcp/servers.nix` and add to the `programs` section:

```nix
programs = {
  # ... existing servers ...

  # Add your new server
  yourServer.enable = true;

  # Or with custom args
  filesystem = {
    enable = true;
    args = [ "/path/to/allowed/directory" ];
  };
};
```

**Available MCP servers in mcp-servers-nix:**

- context7, github, git, fetch, memory,
  sequential-thinking, nixos (currently enabled)
- filesystem, playwright, terraform, time, notion, grafana, and more

**After adding**, rebuild: `nh os switch`

### Modifying System Settings

1. **Identify the module**: Check the imports in `configuration.nix`
2. **Use Context7**: Look up NixOS option documentation
3. **Edit the specific module**: Not the main config
4. **Test thoroughly**: System changes can break boot

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

### Research First, Implement Second

Before making changes:

1. Use Context7 to understand the option/package
2. Use GitHub MCP to find real-world examples
3. Implement with confidence

### Leverage MCP for Everything

**Never guess when you can use an MCP!**

**Documentation lookups (Context7)**:

- "Use Context7 to find the NixOS option for enabling Docker"
- "Look up the latest Rust toolchain setup for NixOS using Context7"
- "Check Bevy 0.15 migration guide via Context7"

**Code examples (GitHub)**:

- "Search GitHub via MCP for Hyprland blur configuration examples"
- "Find Rust ECS game examples on GitHub"
- "Look up how others configure Nix flakes for Rust projects"

**Complex reasoning (Sequential Thinking)**:

- "Use Sequential Thinking to plan the game's collision detection system"
- "Reason through the best state management approach for this feature"

**Project memory (Memory)**:

- "Save this performance optimization approach to memory"
- "Record why we chose this architecture pattern"

**Git analysis (Git)**:

- "When was this bug introduced? Use Git MCP to analyze"
- "Show me the evolution of this module using Git MCP"

**API testing (Fetch)**:

- "Test this game server endpoint with Fetch MCP"
- "Download this asset manifest using Fetch"

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

## 🎓 Learning Resources

Use MCP servers to look up:

- NixOS manual and options
- Home Manager documentation
- Hyprland wiki
- Package sources in nixpkgs
- Community configurations for inspiration

## ⚠️ Important Notes

1. **No sudo needed**: All files in `~/repos/nix-home` are user-editable
2. **System import**: `/etc/nixos/configuration.nix` imports this directory
3. **State version**: 24.11 (don't change without research)
4. **Flakes enabled**: Experimental features are on
5. **Always rebuild**: After changes, run `nh os switch`

## 🔨 Rebuilding with nh

This project uses **nh** (nix helper) instead of raw
`nixos-rebuild`. It provides colored build output,
automatic diff display, and confirmation prompts.

**Common commands** (run from `~/repos/nix-home`):

| Command        | Description                                                 |
| -------------- | ----------------------------------------------------------- |
| `nh os switch` | Build and activate config (replaces `nixos-rebuild switch`) |
| `nh os test`   | Activate without adding boot entry (for testing)            |
| `nh os boot`   | Build and set as next boot entry without activating         |
| `nh clean all` | Garbage collect old generations                             |

**Notes**:

- nh auto-detects the hostname (`DavidDudsonPC`)
- Shows a diff of what changed before applying
- Asks for sudo when needed (no need to prefix with sudo)
- Use `nh os switch` as the default after any config change

## 💡 Pro Tips

- Use `nix search nixpkgs <package>` to find packages (or Context7!)
- Use `nixos-option <option.path>` to see option documentation
- Check `man configuration.nix` for system options
- Check `man home-configuration.nix` for home-manager options
- Use the GitHub MCP to explore nixpkgs source when needed

---

**Remember**: You have 7 powerful MCP servers at your disposal:

- Context7 for documentation
- GitHub for code examples
- Memory for persistence
- Git for history analysis
- Fetch for HTTP requests
- Sequential Thinking for complex reasoning
- NixOS for Nix-specific help

**USE THEM AGGRESSIVELY!** Don't guess, don't assume -
look it up, reason through it, and save it for later.
MCPs make you 10x more effective!
