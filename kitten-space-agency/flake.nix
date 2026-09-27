{
  description = "KSA Linux pre-alpha";

  inputs.nixpkgs.url = "github:numtide/nixpkgs-unfree/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};

      version = "2026.9.22.5482";
      hash = "sha256-69yi2BfMIZ0fFKbb52w2Ihji+yvY6uN7aTUYiPXy/3Q=";

      ksa-unwrapped = pkgs.stdenvNoCC.mkDerivation {
        pname = "ksa-unwrapped";
        inherit version;

        src = pkgs.requireFile {
          name = "ksa_linux_v${version}.tar.gz";
          url = "https://ahwoo.com/app/100000/kitten-space-agency";
          inherit hash;
        };

        sourceRoot = ".";
        dontConfigure = true;
        dontBuild = true;
        dontFixup = true;

        installPhase = ''
          runHook preInstall
          mkdir -p $out/opt
          cp -r "$(dirname "$bin")" $out/opt/ksa
          chmod +x $out/opt/ksa/KSA
          chmod +x $out/opt/ksa/createdump
          runHook postInstall
        '';
      };

      desktopItem = pkgs.makeDesktopItem {
        name = "ksa";
        desktopName = "Kitten Space Agency";
        exec = "ksa";
        categories = [ "Game" ];
      };

      ksa = pkgs.buildFHSEnv {
        pname = "ksa";
        inherit version;

        targetPkgs =
          p: with p; [
            icu
            openssl
            stdenv.cc.cc.lib
            libxkbcommon
            vulkan-loader
            wayland
          ];

        runScript = pkgs.writeShellScript "ksa" ''
          # KSA creates the manifest.toml with r-- permission
          chmod u+w "$HOME/Documents/My Games/Kitten Space Agency/manifest.toml"
          cd ${ksa-unwrapped}/opt/ksa
          exec ./KSA "$@"
        '';

        extraInstallCommands = ''
          mkdir -p $out/share/applications
          cp ${desktopItem}/share/applications/*.desktop $out/share/applications/
        '';
      };
    in
    {
      packages.${system} = {
        inherit ksa ksa-unwrapped;
        default = ksa;
      };
      overlays.default = final: prev: { inherit ksa; };
    };
}
