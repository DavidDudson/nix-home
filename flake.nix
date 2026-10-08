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
      mcp-servers-nix,
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
              inherit mcp-servers-nix ws;
            };
          }
        ];
      };
    };
}
