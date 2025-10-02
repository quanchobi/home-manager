{
  description = "Home Manager configuration";

  inputs = {
    nixvim.url = "github:quanchobi/nixvim";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    home-manager.url = "github:nix-community/home-manager/release-25.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    stylix.url = "github:danth/stylix/release-25.05";
    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      nixvim,
      home-manager,
      stylix,
      zen-browser,
      ...
    }@inputs:
    {
      # For non-NixOS systems
      homeConfigurations."anderson" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
        extraSpecialArgs = {
          inherit inputs;
        };
        modules = [ 
	./anderson/home.nix
	nixvim.homeManagerModules.default
	];
      };

      # NixOS module for home-manager
      nixosModules.default =
        {
          config,
          lib,
          pkgs,
          ...
        }:
        {
          imports = [ ./anderson/options.nix ];

          config = {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = {
              inherit inputs;
              systemGuiEnable = config.system.gui.enable;
            };
            home-manager.users.anderson =
              {
                config,
                pkgs,
                lib,
                systemGuiEnable,
                ...
              }:
              {
                imports = [ 
		  ./anderson/home.nix
		  nixvim.homeManagerModules.default
		];
                system.gui.enable = systemGuiEnable;
              };
          };
        };
    };
}
