{
  description = "DavidDudsonPC NixOS configuration";

  inputs = {
    # nixos-unstable only advances once Hydra has built the big packages, so
    # chromium and friends come from the binary cache. nixos-unstable-small
    # runs ahead of the cache and forced a from-source chromium build.
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Private repo: git+ssh uses the SSH key, github: would need an API token.
    ws = {
      url = "git+ssh://git@github.com/DavidDudson/ws";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      nixpkgs,
      home-manager,
      fenix,
      ws,
      ...
    }:
    {
      nixosConfigurations.DavidDudsonPC = nixpkgs.lib.nixosSystem {
        specialArgs = {
          inherit fenix;
        };
        modules = [
          ./configuration.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.extraSpecialArgs = {
              inherit ws;
            };
          }
        ];
      };
    };
}
