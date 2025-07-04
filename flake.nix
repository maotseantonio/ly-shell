{
  description = "QuickShell QS-Bar with config + deps";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
quickshell = {
      url = "github:outfoxxed/quickshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, quickshell, ... }: let
    forAllSystems = f: nixpkgs.lib.genAttrs [ "x86_64-linux" "aarch64-linux" ] f;
  in {
    packages = forAllSystems (system: let
      pkgs = import nixpkgs { inherit system; };

      # QuickShell core binary
      quickshellBin = quickshell.packages.${system}.default;

      # Your extra runtime dependencies
      extraDeps = with pkgs; [
        libsForQt5.qtstyleplugin-kvantum
        kdePackages.qtstyleplugin-kvantum
        wlsunset
        libsForQt5.qt5.qtgraphicaleffects
        kdePackages.qt5compat
        kdePackages.qtbase
        kdePackages.qtdeclarative
        kdePackages.qtmultimedia
        libqalculate
        colloid-kde
        kdePackages.qt5compat
        kdePackages.qqc2-desktop-style
        kdePackages.sonnet
        kdePackages.kirigami
        kdePackages.kirigami-addons
        kdePackages.breeze
      ];

      # QML path setup
      qt6Qml = pkgs.lib.concatMapStringsSep ":" (pkg: "${pkg}/lib/qt-6/qml") extraDeps;
      qt5Qml = "${pkgs.libsForQt5.qtstyleplugin-kvantum}/lib/qt-5/qml";
      qmlPath = "${qt6Qml}:${qt5Qml}";

      # Package that wraps everything
      qsBar = pkgs.stdenvNoCC.mkDerivation {
        pname = "qs-bar";
        version = "1.0";

        src = ./config;

        nativeBuildInputs = [ pkgs.makeWrapper ];

        installPhase = ''
          mkdir -p $out/share/quickshell
          cp -r * $out/share/quickshell

          mkdir -p $out/bin
          makeWrapper ${quickshellBin}/bin/qs $out/bin/qs-bar \
            --add-flags "-p $out/share/quickshell/shell.qml"
        '';

      };

    in {
      default = qsBar;
      qs-bar = qsBar;
    });
  };
}
