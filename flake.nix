
{
  description = "QuickShell QS-Bar flake with home config and activation";

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

      quickshellBin = quickshell.packages.${system}.default;

      quickshellConfig = pkgs.stdenvNoCC.mkDerivation {
        pname = "quickshell-config";
        version = "1.0";
        src = ./config;
        installPhase = ''
          mkdir -p $out
          cp -r * $out/
        '';
      };


      qsBar = pkgs.stdenvNoCC.mkDerivation {
  pname = "qs-bar";
  version = "1.0";

  nativeBuildInputs = [ pkgs.makeWrapper ];

  unpackPhase = "true";  # no source to unpack

  installPhase = ''
    mkdir -p $out/bin

    makeWrapper ${quickshellBin}/bin/quickshell $out/bin/qs-bar \
      --set QML2_IMPORT_PATH "${qmlPath}" \
      --prefix PATH : ${pkgs.lib.makeBinPath extraDeps} \
      --add-flags "-p $HOME/.config/quickshell/shell.qml"
  '';
};


    in {
      quickshellConfig = quickshellConfig;
      qs-bar = qsBar;
      default = qsBar;
    });

    homeManagerModules.quickshell = { config, lib, pkgs, ... }: let
      cfg = config.myQuickshell;
    in {
      options.myQuickshell = {
        enable = lib.mkEnableOption "QuickShell bar with home config";
      };

      config = lib.mkIf cfg.enable {
        home.packages = [
          self.packages.${pkgs.system}.qs-bar
        ];

        home.activation.setupQuickshell = config.lib.dag.entryAfter ["writeBoundary"] ''
          mkdir -p "$HOME/.config/quickshell"
          cp -r --no-preserve=all ${self.packages.${pkgs.system}.quickshellConfig}/* "$HOME/.config/quickshell"
          chmod -R u+w "$HOME/.config/quickshell"
        '';
      };
    };
  };
}
