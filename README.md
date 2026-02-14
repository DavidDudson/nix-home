# NixOS Configuration

Dave's Nixos config. Feel free to use it as a starting point!

- Home Manager is run via a nixos-rebuild, instead of being independent.
- All Dots are stored in this repo, and overwrite dots in `~/.config/*`
- The actual `/etc/nixos/configuration.nix` imports from this directory
  - This is so llm modifications can be made to this config in user space, without giving llms root access.
- Any application config that can be in this repo, will be, eg. zed/helix editor config, plugins etc.
