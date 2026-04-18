{
  description = "DavidDudsonPC NixOS configuration";

  inputs = {
    # Using nixos-unstable-small for faster updates than nixos-unstable while still being CI-tested.
    # Switch back to nixos-unstable once it catches up if preferred.
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable-small";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    mcp-servers-nix = {
      url = "github:natsukium/mcp-servers-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      nixpkgs,
      home-manager,
      fenix,
      mcp-servers-nix,
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
              inherit mcp-servers-nix;
            };
          }
        ];
      };
    };
}
