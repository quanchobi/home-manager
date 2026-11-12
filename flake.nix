{
  description = "Home Manager configuration";

  inputs = {
    anthropic-skills = {
      url = "github:anthropics/skills";
      flake = false;
    };

    # Tracks master instead of nixpkgs' zsh-fzf-tab, which lags behind; bumped
    # by `nix flake update` like every other input.
    fzf-tab = {
      url = "github:Aloxaf/fzf-tab";
      flake = false;
    };

    nixvim.url = "github:quanchobi/nixvim";

    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";

    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    tmux-agent-indicator = {
      url = "github:quanchobi/tmux-agent-indicator";
      inputs.nixpkgs.follows = "nixpkgs";
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
      tmux-agent-indicator,
      treefmt-nix,
      ...
    }@inputs:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;

      # Standalone (non-NixOS) home-manager config for one host architecture,
      # from a user entry point plus any per-host modules.
      mkHome =
        system: modules:
        home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.${system};
          extraSpecialArgs = { inherit inputs; };
          modules = [
            {
              nixpkgs.config.allowUnfree = true;
            }
            nixvim.homeModules.default
            tmux-agent-indicator.homeModules.default
            ./modules/standalone.nix
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
        anderson = mkHome "x86_64-linux" [ ./users/anderson ];
        "anderson@yappy-yiqi" = mkHome "x86_64-linux" [
          ./users/anderson
          ./users/anderson/desktop.nix
        ];
        "jacob.hanks@canonical.com" = mkHome "x86_64-linux" [ ./users/jacob.hanks_canonical.com ];
      };

      # NixOS module for home-manager
      nixosModules.default = {
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          extraSpecialArgs = { inherit inputs; };
          users.anderson = {
            imports = [
              ./users/anderson
              nixvim.homeModules.default
              tmux-agent-indicator.homeModules.default
            ];
          };
        };
      };
    };
}
