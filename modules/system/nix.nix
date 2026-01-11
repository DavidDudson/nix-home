{ config, lib, pkgs, ... }:

{
  nixpkgs.config.allowUnfree = true;

  nix = {
    optimise.automatic = true;
    settings = {
      auto-optimise-store = true;
      experimental-features = "nix-command flakes";
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
  };

  system = {
    copySystemConfiguration = true;
    stateVersion = "24.11";
  };
}
