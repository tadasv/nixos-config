{
  description = "A very basic flake";

  inputs = {
    # Pin our primary nixpkgs repository. This is the main nixpkgs repository
    # we'll use for our configurations. Be very careful changing this because
    # it'll impact your entire system.
    nixpkgs.url = "github:nixos/nixpkgs/nixos-22.11";

    # We use the unstable nixpkgs repo for some packages.
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable"; 

    home-manager = {
      url = "github:nix-community/home-manager/release-22.11";

      # We want to use the same set of nixpkgs as our system.
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }:
  let 
    system = "x86_64-linux";

    pkgs = import nixpkgs {
      inherit system;
      config = { allowUnfree = true; };
    };

    lib = nixpkgs.lib;

  in {
    nixosConfigurations = {
      # here `nixos` must match hostname of the machine this this is running
      nixos = lib.nixosSystem {
        inherit system;

        modules = [
          ./system/configuration.nix

		  home-manager.nixosModules.home-manager {
		    home-manager.useGlobalPkgs = true;
			home-manager.useUserPackages = true;
			home-manager.users.vptr = {
		      imports = [ ./users/vptr/home.nix ];
		    };
	      }
        ];
      };
    };
  };
}
