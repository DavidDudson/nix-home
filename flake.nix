{
  description = "DavidDudsonPC NixOS configuration";

  inputs = {
    # nixos-unstable only advances once Hydra has built the big packages, so
    # chromium and friends come from the binary cache. nixos-unstable-small
    # runs ahead of the cache and forced a from-source chromium build.
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    # claude-code only: nixos-unstable lags it by days, and /steward needs a
    # recent release. Drop this input once nixos-unstable catches up.
    nixpkgs-claude.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Private repo: git+ssh uses the SSH key, github: would need an API token.
    overbridge = {
      url = "git+ssh://git@github.com/DavidDudson/overbridge";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      nixpkgs,
      nixpkgs-claude,
      home-manager,
      fenix,
      overbridge,
      ...
    }:
    {
      nixosConfigurations.DavidDudsonPC = nixpkgs.lib.nixosSystem {
        specialArgs = {
          inherit fenix;
        };
        modules = [
          ./configuration.nix
          {
            nixpkgs.overlays = [
              (final: _prev: {
                inherit
                  (import nixpkgs-claude {
                    inherit (final.stdenv.hostPlatform) system;
                    config.allowUnfree = true;
                  })
                  claude-code
                  ;
              })
            ];
          }
          home-manager.nixosModules.home-manager
          {
            home-manager.extraSpecialArgs = {
              inherit overbridge;
            };
          }
        ];
      };
    };
}
