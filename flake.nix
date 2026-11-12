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

    # Keeps its own nixos-unstable nixpkgs (nixvim tracks unstable); only the
    # formatter input is shared.
    nixvim = {
      url = "github:quanchobi/nixvim";
      inputs.treefmt-nix.follows = "treefmt-nix";
    };

    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
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

      # Third-party home-manager modules every config gets, standalone or NixOS.
      sharedModules = [
        nixvim.homeModules.default
        tmux-agent-indicator.homeModules.default
      ];

      # Standalone (non-NixOS) home-manager config for one host architecture,
      # from a user entry point plus any per-host modules.
      mkHome =
        system: modules:
        home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.${system};
          extraSpecialArgs = { inherit inputs; };
          modules = [
            {
              # For modules/fonts.nix (symbola, aegyptus).
              nixpkgs.config.allowUnfree = true;
            }
            ./modules/standalone.nix
          ]
          ++ sharedModules
          ++ modules;
        };

      treefmtEval = forAllSystems (
        system:
        treefmt-nix.lib.evalModule nixpkgs.legacyPackages.${system} {
          projectRootFile = "flake.nix";
          programs = {
            deadnix.enable = true; # Remove unused Nix bindings
            nixfmt.enable = true; # Format Nix files
            prettier.enable = true; # Format JSON, YAML, Markdown
            shellcheck.enable = true; # Lint shell scripts
            shfmt.enable = true; # Format shell scripts
            statix.enable = true; # Fix Nix antipatterns
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

        # anderson's generation through nixosModules.default on a minimal NixOS
        # system that, like a typical consumer, does not allow unfree packages.
        nixos-module =
          (nixpkgs.lib.nixosSystem {
            modules = [
              self.nixosModules.default
              {
                nixpkgs.hostPlatform = system;
                boot.isContainer = true; # no bootloader or filesystems needed
                users.users.anderson.isNormalUser = true;
                system.stateVersion = "26.05";
              }
            ];
          }).config.home-manager.users.anderson.home.activationPackage;
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

      # NixOS module: brings in home-manager's own NixOS module and the user. A
      # consumer that also imports home-manager.nixosModules.home-manager must
      # make this flake's home-manager input follow its own, so both imports are
      # the same path and get deduplicated.
      nixosModules.default = {
        imports = [ home-manager.nixosModules.home-manager ];
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          extraSpecialArgs = { inherit inputs; };
          inherit sharedModules;
          users.anderson = ./users/anderson;
        };
      };
    };
}
