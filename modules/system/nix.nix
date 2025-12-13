{ config, lib, pkgs, ... }:

{
  nixpkgs.config.allowUnfree = true;

  nix.optimise.automatic = true;
  nix.settings.auto-optimise-store = true;
  nix.settings.experimental-features = "nix-command flakes";
  nix.gc.automatic = true;

  system.copySystemConfiguration = true;
  system.stateVersion = "24.11";
}
