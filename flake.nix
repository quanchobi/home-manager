{
    description = "Home Manager configuration of anderson";

    inputs = {
        # Specify the source of Home Manager and Nixpkgs.
        nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
        home-manager = {
            url = "github:nix-community/home-manager";
            inputs.nixpkgs.follows = "nixpkgs";
        };

        ags.url = "github:Aylur/ags";
    };

    outputs = { nixpkgs, home-manager, ... }@inputs:
        let
        system = "x86_64-linux";
    in {
        homeConfigurations."anderson" = home-manager.lib.homeManagerConfiguration {
            # import nixpkgs
            pkgs = import nixpkgs { inherit system; };

            # pass inputs as specialArgs
            extraSpecialArgs = { inherit inputs; };

            # Specify your home configuration modules here
            modules = [
                ./home.nix
                ./apps/zsh.nix
                ./apps/foot.nix
                ./apps/starship.nix
                ./apps/password-store.nix
                ./apps/neovim.nix
                ./apps/git.nix
                ./apps/tmux.nix
                ./apps/eza.nix
                ./apps/spotifyd.nix
                ./apps/hypr.nix
                ./apps/ags/ags.nix
            ];
        };
    };
}
