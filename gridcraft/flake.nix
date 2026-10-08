{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    crane.url = "github:ipetkov/crane";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    repo = {
      url = "github:storytold/gridcraft";
      flake = false;
    };
  };

  outputs =
    {
      nixpkgs,
      flake-utils,
      crane,
      rust-overlay,
      repo,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ (import rust-overlay) ];
        };
        craneLib = (crane.mkLib pkgs).overrideToolchain (p: p.rust-bin.stable.latest.default);

        src = repo;
        common = {
          inherit src;
          pname = "gridcraft-workspace";
          strictDeps = true;
          nativeBuildInputs = [ pkgs.pkg-config ];
          buildInputs = [ ];
        };

        cargoArtifacts = craneLib.buildDepsOnly common;

        mkBin =
          name: extra:
          craneLib.buildPackage (
            common
            // {
              inherit cargoArtifacts;
              pname = name;
              cargoExtraArgs = "-p ${name}";
              doCheck = false;
            }
            // extra
          );

        libs = with pkgs; [
          libxkbcommon
          vulkan-loader
          wayland
        ];

        app = mkBin "gridcraft" {
          buildInputs = common.buildInputs ++ libs;
          postFixup = ''
            patchelf --add-rpath ${pkgs.lib.makeLibraryPath libs} $out/bin/gridcraft
          '';
        };
        cli = mkBin "gridcraft-cli" { };
      in
      {
        packages = {
          inherit app cli;
          default = app;
        };

        apps = {
          app = flake-utils.lib.mkApp { drv = app; };
          cli = flake-utils.lib.mkApp { drv = cli; };
        };

        devShells.default = craneLib.devShell {
          packages = [
            pkgs.rust-analyzer
            pkgs.cargo-nextest
          ];
        };
      }
    );
}
