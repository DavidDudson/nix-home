# Claude Code Environment Guide

Welcome! This is a modular NixOS configuration for DavidDudsonPC. This guide will help you work effectively with this codebase.

## 🤖 Available MCP Servers

This environment has two MCP servers configured that you should use actively:

### Context7 MCP
**Use this for**: Looking up documentation for any programming language, framework, or tool.

Instead of guessing API signatures or syntax, use Context7 to fetch the latest documentation:
- "Use Context7 to check the latest NixOS module options"
- "Look up Hyprland configuration syntax via Context7"
- "Check the Nushell documentation for environment variable syntax"

### GitHub MCP
**Use this for**: Searching GitHub repositories, checking issues, looking up package sources.

Great for:
- Finding example NixOS configurations
- Checking package definitions in nixpkgs
- Looking up MCP server implementations
- Researching how others solve similar problems

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

**DON'T**:
- Make multiple unrelated changes in one commit
- Skip testing before committing
- Hardcode values that should be variables

### When Using MCP Servers

**ALWAYS**:
- Use Context7 before adding new Nix options you're unsure about
- Use GitHub MCP to find examples of similar NixOS setups
- Verify package availability via Context7/GitHub before adding

**Example workflow**:
1. User: "Add tmux to the system"
2. You: Use Context7 to check if tmux has special NixOS module options
3. You: Check `modules/programs/terminal.nix` to see if it's already there
4. You: Add to the appropriate section with correct syntax
5. You: Suggest rebuild and test

## 🎯 Common Tasks

### Adding a New Package

1. **Determine category**: Is it dev, terminal, media, wayland, or system?
2. **Check if exists**: Use `grep -r "package-name" modules/programs/`
3. **Use Context7**: Verify the package name and any special options
4. **Add to appropriate file**: Keep alphabetical order within sections
5. **Test**: `sudo nixos-rebuild switch`

### Adding a New MCP Server

Edit `home/mcp/servers.nix`:
```nix
yourServer = {
  command = "${pkgs.nodejs_20}/bin/npx";
  args = [ "-y" "@scope/mcp-server-name" ];
  transport = "stdio";
};
```

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

### Leverage MCP for Complex Tasks
- "Use Context7 to find the NixOS option for enabling Docker"
- "Search GitHub via MCP for Hyprland blur configuration examples"
- "Look up the latest Rust toolchain setup for NixOS using Context7"

### Keep It Modular
- One concern per file
- Related settings grouped together
- Easy to find, easy to modify

## 📝 Commit Guidelines

When committing changes:
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

**Remember**: You have Context7 and GitHub MCP at your disposal. Use them liberally to provide accurate, well-researched solutions!
