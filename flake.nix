{
  description = "Home Manager configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    stylix.url = "github:danth/stylix/release-25.05";
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      stylix,
      ...
    }@inputs:
    {
      # For non-NixOS systems
      homeConfigurations."anderson" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
        extraSpecialArgs = {
          inherit inputs;
        };
        modules = [ ./anderson/home.nix ];
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
                imports = [ ./anderson/home.nix ];
                system.gui.enable = systemGuiEnable;
              };
          };
        };
    };
}
