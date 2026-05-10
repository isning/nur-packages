{
  description = "My personal NUR repository";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    # add git hooks to format nix code before commit
    pre-commit-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      pre-commit-hooks,
      ...
    }:
    let
      forAllSystems = nixpkgs.lib.genAttrs nixpkgs.lib.systems.flakeExposed;
    in
    {
      legacyPackages = forAllSystems (
        system:
        import ./default.nix {
          pkgs = import nixpkgs { inherit system; };
        }
      );
      packages = forAllSystems (
        system: nixpkgs.lib.filterAttrs (_: v: nixpkgs.lib.isDerivation v) self.legacyPackages.${system}
      );

      nixosModules = import ./nixos-modules; # NixOS modules
      # homeModules = import ./home-modules;
      # darwinModules = import ./darwin-modules;
      # flakeModules = import ./flake-modules;
      overlays = import ./overlays; # nixpkgs overlays

      checks = forAllSystems (system: {
        pre-commit-check = pre-commit-hooks.lib.${system}.run {
          src = ./.;
          hooks = {
            nixfmt = {
              enable = true;
              settings.width = 100;
            };
            # Source code spell checker
            typos = {
              enable = true;
              settings = {
                write = true; # Automatically fix typos
                configPath = ".typos.toml"; # relative to the flake root
                exclude = "rime-data/";
              };
            };
            prettier = {
              enable = true;
              settings = {
                write = true; # Automatically format files
                configPath = ".prettierrc.yaml"; # relative to the flake root
              };
            };
            # deadnix.enable = true; # detect unused variable bindings in `*.nix`
            # statix.enable = true; # lints and suggestions for Nix code(auto suggestions)
          };
        };
      });

      # Development Shells
      devShells = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = pkgs.mkShell {
            packages = with pkgs; [
              # fix https://discourse.nixos.org/t/non-interactive-bash-errors-from-flake-nix-mkshell/33310
              bashInteractive
              # fix `cc` replaced by clang, which causes nvim-treesitter compilation error
              gcc
              # Nix-related
              nixfmt
              deadnix
              statix
              # spell checker
              typos
              # code formatter
              prettier
            ];
            name = "dots";
            inherit (self.checks.${system}.pre-commit-check) shellHook;
          };
        }
      );

      # Format the nix code in this flake
      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt);
    };
}
