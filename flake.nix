{
  edition = 201909;

  outputs = { self, nixpkgs }:
    let
      systems = ["x86_64-darwin"];
      lib = import ${nixpkgs}/lib;
      forAllSystems = f: lib.genAttrs systems (system: f (
        import nixpkgs {
          inherit system;
          overlays = [self.overlay];
        }
      ));

    in {
      overlay = self: pkgs: {
        home-manager = pkgs.callPackage ./home-manager {
          path = toString ./.;
        };
        mkHome = configuration:
          import home-manager/home-manager.nix {
            inherit pkgs;
            configuration = configuration // { _module.args.pkgs = pkgs; };
            nixpkgsSrc = nixpkgs;
          };
      };

      packages = forAllSystems (pkgs: {inherit (pkgs) home-manager mkHome});

      defaultPackage = forAllSystems (pkgs: pkgs.home-manager);

      homeConfiguration.exampleOnDarwin = self.packages.x86_64-darwin.mkHome {
        home.homeDirectory = "/home/username";
        home.username = "username";
      };
      
      nixosModules.home-manager = import ./nixos;
      darwinModules.home-manager = import ./nix-darwin;
    };
}
