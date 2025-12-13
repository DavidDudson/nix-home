# NixOS Configuration

Modular NixOS configuration for DavidDudsonPC.

## Directory Structure

```
nix-home/
├── configuration.nix          # Main entry point
├── home/                      # Home Manager configuration
│   ├── home.nix              # Home Manager entry point
│   ├── programs/             # User programs
│   │   ├── git.nix          # Git configuration
│   │   └── shell.nix        # Shell programs (nushell, starship, carapace)
│   ├── desktop/              # Desktop user settings
│   │   └── gtk.nix          # GTK theme configuration
│   └── mcp/                  # Claude Code MCP servers
│       └── servers.nix      # MCP server definitions
├── modules/                   # System-level modules
│   ├── system/               # Core system configuration
│   │   ├── boot.nix         # Boot loader & LUKS
│   │   ├── networking.nix   # Network & SSH
│   │   ├── nix.nix          # Nix settings & flakes
│   │   ├── programs.nix     # System packages
│   │   └── users.nix        # User accounts
│   ├── hardware/             # Hardware-specific settings
│   │   ├── nvidia.nix       # NVIDIA GPU configuration
│   │   ├── bluetooth.nix    # Bluetooth settings
│   │   └── audio.nix        # PipeWire audio
│   ├── desktop/              # Desktop environment
│   │   ├── hyprland.nix     # Hyprland compositor
│   │   └── fonts.nix        # System fonts
│   └── services/             # System services
│       └── services.nix     # Misc services (printing, etc)
└── update-system-config.sh   # Script to setup /etc/nixos import
```

## Usage

### Making Changes

Edit any file in this directory, then rebuild:

```bash
sudo nixos-rebuild switch
```

### Quick Reference

- **Add system packages**: Edit `modules/system/programs.nix`
- **Configure git**: Edit `home/programs/git.nix`
- **Add MCP servers**: Edit `home/mcp/servers.nix`
- **Change shell config**: Edit `home/programs/shell.nix`
- **Modify Hyprland**: Edit `modules/desktop/hyprland.nix`
- **Update NVIDIA settings**: Edit `modules/hardware/nvidia.nix`

### Version Control

Initialize git to track changes:

```bash
cd ~/repos/nix-home
git init
git add .
git commit -m "Initial modular NixOS config"
```

## MCP Servers

Configured servers:
- **Context7**: Developer documentation integration
- **GitHub**: Repository integration

MCP configuration is in `home/mcp/servers.nix`.

## Notes

- The actual `/etc/nixos/configuration.nix` imports from this directory
- All configurations are user-editable without sudo
- Home Manager state version: 24.11
- System state version: 24.11
