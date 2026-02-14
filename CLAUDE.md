# Claude Code Environment Guide

Welcome! This is a modular NixOS configuration for DavidDudsonPC. This guide will help you work effectively with this codebase.

## 🤖 Available MCP Servers

This environment has **7 MCP servers** configured. **USE THEM AGGRESSIVELY** - they're here to make you more effective!

### 🔍 Context7 MCP
**Use constantly for**: Documentation lookup for ANY programming language, framework, or tool.

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
**Use for**: Searching repositories, checking issues, finding examples, exploring nixpkgs source.

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

**Critical**: At the end of significant work sessions, explicitly save key learnings to memory!

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

This is a **modular NixOS configuration** - NOT a single monolithic file. Understanding this structure is critical:

```
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
    ├── desktop/              ← User desktop settings
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

### When Modifying Configuration

**DO**:
- Edit the specific module file, not the main config
- Test with `sudo nixos-rebuild switch`
- Keep changes focused and logical
- Use MCP servers to research options before implementing
- After making changes, enter `nix-shell` and run linting/formatting before committing:
  ```sh
  nix-shell
  find . -name '*.nix' | xargs nixfmt
  find . -name '*.nix' | xargs deadnix
  statix check .
  find . -name '*.sh' | xargs shellcheck
  ```

**DON'T**:
- Make multiple unrelated changes in one commit
- Skip testing before committing
- Hardcode values that should be variables
- Commit without running the linters first

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
5. **Test**: `sudo nixos-rebuild switch`

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
- context7, github, git, fetch, memory, sequential-thinking, nixos (currently enabled)
- filesystem, playwright, terraform, time, notion, grafana, and more

**After adding**, rebuild: `sudo nixos-rebuild switch`

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

## 📝 Commit Guidelines

When committing changes:
- **Always** enter `nix-shell` and run `nixfmt`, `deadnix`, `statix`, and `shellcheck` before committing
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
5. **Always rebuild**: After changes, run `sudo nixos-rebuild switch`

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

**USE THEM AGGRESSIVELY!** Don't guess, don't assume - look it up, reason through it, and save it for later. MCPs make you 10x more effective!
