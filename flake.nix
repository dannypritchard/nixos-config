{
  description = "My Nix config";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    nixos-wsl.url = "github:nix-community/NixOS-WSL";
  };

  outputs = { self, nixpkgs, home-manager, nixos-wsl, ... }:
  let
    system = "x86_64-linux";
  in {
    nixosConfigurations.wsl = nixpkgs.lib.nixosSystem {
      inherit system;

      modules = [
        nixos-wsl.nixosModules.default
        ./hosts/wsl/configuration.nix

        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.users.danny = import ./home.nix;
        }
      ];
    };

    # Optional for later (don’t use yet if it confuses you)
    homeConfigurations.danny = home-manager.lib.homeManagerConfiguration {
      pkgs = nixpkgs.legacyPackages.${system};
      modules = [ ./home.nix ];
    };
  };
}
