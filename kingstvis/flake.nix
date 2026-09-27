{
  inputs = {
    nixpkgs.url = "github:numtide/nixpkgs-unfree/nixos-unstable";
    nixpkgs-old.url = "github:NixOS/nixpkgs/nixos-21.11";
    flake-utils.url = "github:numtide/flake-utils";
    ws281x = {
      url = "git+ssh://git@github.com/mergmann/ws281x-kingst";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-old,
      flake-utils,
      ws281x,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        oldPkgs = import nixpkgs-old {
          inherit system;
          config.permittedInsecurePackages = [ "openssl-1.0.2u" ];
        };
        ws281x-analyzer = ws281x.packages.${system}.ws281x-analyzer;
      in
      {
        packages.default = pkgs.stdenv.mkDerivation rec {
          pname = "kingstvis";
          version = "3.6.6";
          src = pkgs.fetchzip {
            url = "https://res.kingst.site/kfs/KingstVIS_v${version}.tar.gz";
            hash = "sha256-41tIOUaPOkyLAowf0M+hnZC6b5wVKVAD/DTjnE7nbOQ=";
            stripRoot = true;
          };

          meta.mainProgram = "KingstVIS";

          nativeBuildInputs = with pkgs; [
            autoPatchelfHook
            makeWrapper
          ];
          buildInputs = with pkgs; [
            stdenv.cc.cc.lib
            dbus
            fontconfig
            freetype
            glib
            libGL
            libsm
            libx11
            libxi
            libxrender
            zlib

            oldPkgs.openssl_1_0_2
          ];

          dontConfigure = true;
          dontBuild = true;

          installPhase = ''
            runHook preInstall
            mkdir -p $out/opt/KingstVIS
            mkdir -p $out/bin
            cp -r --no-preserve=mode . $out/opt/KingstVIS/
            install -Dm755 ${ws281x-analyzer}/lib/libWS281x.so $out/opt/KingstVIS/Analyzer/libWS281x.so
            chmod +x $out/opt/KingstVIS/KingstVIS

            makeWrapper $out/opt/KingstVIS/KingstVIS $out/bin/KingstVIS \
              --set QT_QPA_PLATFORM xcb \
              --set QT_PLUGIN_PATH $out/opt
            runHook postInstall
          '';
        };
      }
    );
}
