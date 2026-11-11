{
  description = "Home Manager configuration";

  nixConfig = {
    allow-unfree = true;
  };

  inputs = {
    anthropic-skills = {
      url = "github:anthropics/skills";
      flake = false;
    };

    niri.url = "github:sodiboo/niri-flake";

    nixvim.url = "github:quanchobi/nixvim";

    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";

    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    stylix.url = "github:danth/stylix/release-25.11";

    tmux-agent-indicator = {
      url = "github:accessd/tmux-agent-indicator";
      flake = false;
    };

    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      home-manager,
      nixpkgs,
      nixvim,
      self,
      treefmt-nix,
      ...
    }@inputs:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;

      # Standalone (non-NixOS) home-manager config from a user entry point plus
      # any per-host modules.
      mkHome =
        modules:
        home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
          extraSpecialArgs = {
            inherit inputs;
            isNixOS = false;
          };
          modules = [
            {
              nixpkgs.config.allowUnfree = true;
            }
            nixvim.homeModules.default
          ]
          ++ modules;
        };

      treefmtEval = forAllSystems (
        system:
        treefmt-nix.lib.evalModule nixpkgs.legacyPackages.${system} {
          projectRootFile = "flake.nix";
          programs = {
            nixfmt.enable = true; # Format Nix files
            prettier.enable = true; # Format JSON, YAML, Markdown
            shellcheck.enable = true; # Lint shell scripts
            shfmt.enable = true; # Format shell scripts
          };
          settings.formatter = {
            prettier.excludes = [ "*.lock" ];
          };
        }
      );
    in
    {
      # Formatter for `nix fmt`
      formatter = forAllSystems (system: treefmtEval.${system}.config.build.wrapper);

      # Checks for `nix flake check`
      checks = forAllSystems (system: {
        formatting = treefmtEval.${system}.config.build.check self;
      });

      # For non-NixOS systems. `home-manager switch --flake .` picks
      # "$USER@$(hostname)" before "$USER".
      homeConfigurations = {
        anderson = mkHome [ ./users/anderson ];
        "anderson@yappy-yiqi" = mkHome [
          ./users/anderson
          ./users/anderson/desktop.nix
        ];
        "jacob.hanks@canonical.com" = mkHome [ ./users/jacob.hanks_canonical.com ];
      };

      # NixOS module for home-manager
      nixosModules.default =
        {
          ...
        }:
        {
          imports = [ ./modules/options.nix ];

          config = {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              extraSpecialArgs = {
                inherit inputs;
                isNixOS = true;
              };
              users.anderson = {
                imports = [
                  ./users/anderson
                  nixvim.homeModules.default
                ];
              };
            };
          };
        };
    };
}
