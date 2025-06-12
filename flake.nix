{
  description = "Thorium - The fastest browser on earth";
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs, ... }:
    let
      version = "130.0.6723.174";
      baseUrl = "https://github.com/Alex313031";

      linuxVariants = {
        avx = {
          url = "${baseUrl}/thorium/releases/download/M${version}/Thorium_Browser_${version}_AVX.AppImage";
          hash = "sha256-23Vq+MDoV1ePkcVVy5SHWX6QovFUKxDdsgteWfG/i1U=";
        };
        avx2 = {
          url = "${baseUrl}/thorium/releases/download/M${version}/Thorium_Browser_${version}_AVX2.AppImage";
          hash = "sha256-Ej7OIdAjYRmaDlv56ANU5pscuwcBEBee6VPZA3FdxsQ=";
        };
        sse3 = {
          url = "${baseUrl}/thorium/releases/download/M${version}/Thorium_Browser_${version}_SSE3.AppImage";
          hash = "sha256-6qHCijDhAk7gXJ2TM774gVgW82AhexFlXFG1C0kfFoc=";
        };
        sse4 = {
          url = "${baseUrl}/thorium/releases/download/M${version}/Thorium_Browser_${version}_SSE4.AppImage";
          hash = "sha256-v5GGcu/bLJMc2f4Uckcn+ArgnnLL/jrT+01iw/105iY=";
        };
      };

      macosVariants = {
        arm = {
          url = "${baseUrl}/Thorium-MacOS/releases/download/M${version}/Thorium_MacOS_ARM.dmg";
          hash = "sha256-uhxFpSlixffZspN1exynRWFx4kCSfDDc2vf9SNLcjAQ=";
          systems = [ "aarch64-darwin" ];
        };
        x64 = {
          url = "${baseUrl}/Thorium-MacOS/releases/download/M${version}/Thorium_MacOS_X64.dmg";
          hash = "sha256-HJL2ELVryJO0uxHXUTNmsfmR5gkY2OX+upJ7Xx2mbP8=";
          systems = [ "x86_64-darwin" ];
        };
      };

      mkPackagesForSystem =
        system:
        let
          pkgs = import nixpkgs { inherit system; };
          inherit (pkgs.lib) toUpper;

          mkThorium =
            {
              variant,
              url,
              hash,
            }:
            let
              src = pkgs.fetchurl { inherit url hash; };
              appimageContents = pkgs.appimageTools.extractType2 {
                pname = "thorium";
                inherit version src;
              };
            in
            pkgs.appimageTools.wrapType2 {
              pname = "thorium";
              inherit version src;
              extraInstallCommands = ''
                install -m 444 -D ${appimageContents}/thorium-browser.desktop $out/share/applications/thorium-browser.desktop
                install -m 444 -D ${appimageContents}/thorium.png $out/share/icons/hicolor/512x512/apps/thorium.png
                substituteInPlace $out/share/applications/thorium-browser.desktop \
                --replace 'Exec=AppRun --no-sandbox %U' 'Exec=thorium %U'
              '';
            };

          mkThoriumMacOS =
            {
              variant,
              url,
              hash,
            }:
            let
              src = pkgs.fetchurl { inherit url hash; };
            in
            pkgs.stdenv.mkDerivation {
              pname = "thorium";
              inherit version src;
              nativeBuildInputs = [ pkgs.undmg ];
              sourceRoot = ".";
              installPhase = ''
                runHook preInstall
                mkdir -p $out/Applications
                cp -r "Thorium.app" $out/Applications/Thorium.app

                mkdir -p $out/bin
                cat > $out/bin/thorium << EOF
                #!/bin/bash
                exec $out/Applications/Thorium.app/Contents/MacOS/Thorium "\$@"
                EOF
                chmod +x $out/bin/thorium
                runHook postInstall
              '';
              meta = {
                description = "Thorium Browser (${toUpper variant}) - A fast and secure web browser";
                homepage = "https://thorium.rocks";
                license = pkgs.lib.licenses.bsd3;
                platforms = [ system ];
                maintainers = [ pkgs.lib.maintainers.Alex313031 ];
                mainProgram = "thorium";
              };
            };
        in
        if system == "x86_64-linux" then
          pkgs.lib.mapAttrs' (variant: info: {
            name = "thorium-${variant}";
            value = mkThorium {
              inherit variant;
              inherit (info) url hash;
            };
          }) linuxVariants
        else if
          builtins.elem system [
            "aarch64-darwin"
            "x86_64-darwin"
          ]
        then
          pkgs.lib.mapAttrs' (variant: info: {
            name = "thorium-${variant}";
            value = mkThoriumMacOS {
              inherit variant;
              inherit (info) url hash;
            };
          }) (pkgs.lib.filterAttrs (variant: info: builtins.elem system info.systems) macosVariants)
        else
          { };

      mkAppsForSystem =
        system:
        let
          pkgs = import nixpkgs { inherit system; };
          inherit (pkgs.lib) toUpper;

          thoriumApp = variant: {
            type = "app";
            program = "${self.packages.${system}.${variant}}/bin/thorium";
            meta = {
              description = "Thorium Browser (${toUpper variant}) - A fast and secure web browser";
              homepage = "https://thorium.rocks";
              license = pkgs.lib.licenses.bsd3;
              maintainers = [ pkgs.lib.maintainers.Alex313031 ];
              mainProgram = "thorium";
            };
          };
        in
        pkgs.lib.mapAttrs' (variant: _: {
          name = "thorium-${variant}";
          value = thoriumApp variant;
        }) (mkPackagesForSystem system);

      systems = [
        "x86_64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ];

    in
    {
      packages = builtins.listToAttrs (
        map (system: {
          name = system;
          value = mkPackagesForSystem system;
        }) systems
      );

      apps = builtins.listToAttrs (
        map (system: {
          name = system;
          value = mkAppsForSystem system;
        }) systems
      );
    };
}
