{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs = { 
    self, 
    nixpkgs,
    ... 
  }: 
  let
    system = "x86_64-linux";
    pkgs = import nixpkgs { inherit system; };
    version = "yeet-44";

    septabee-pkg = { pkgs, use-wayland ? true, ... }: pkgs.stdenv.mkDerivation rec {
        pname = "septabee";
        version = version;
        src = pkgs.fetchurl {
          url = "https://septabee.nekoweb.org/important_stuff/SEPTABEE_DOWNLOADS/version_B/septabee_linux_B_T2.7z";
          sha256 = "sha256-OMnbRBTku8yi4b3Ay7d70EbB/e2Qh+PfzK2O8qRFoaA=";
        };

        nativeBuildInputs = with pkgs; [
          p7zip
          autoPatchelfHook
        ];

        buildInputs = with pkgs;[
            pipewire
            libx11
            stdenv.cc.cc.lib
          ];

        appendRunpaths = with pkgs;[
          "${lib.makeLibraryPath [
            vulkan-loader
            pipewire ] ++ pkgs.lib.optionals use-wayland [
            wayland
            libxkbcommon
          ]}"
        ];

        unpackPhase = ''
          runHook preUnpack
          7z x "$src"
          runHook postUnpack
        '';

        dontBuild = true;

        installPhase = ''
          runHook preInstall
          
          mkdir -p "$out/bin" "$out/lib"
          cp -r ./linux/* "$out/lib"
          ln -s "$out/lib/septabee" "$out/bin/septabee"
          
          runHook postInstall
        '';
      
        meta.mainProgram = "septabee";
        desktopItem = pkgs.makeDesktopItem rec {
          name = pname;
          exec = name;
          desktopName = "Septabee DAW";
          genericName = "Septabee Digital Audio Workstation";
          categories = [
            "Audio"
          ];
        };
    };
  in
  {
    packages.${system} = {
      default = septabee-pkg;
    };

    apps.${system} = {
      default = {
        type = "app";
        program = "${septabee-pkg}/bin/septabee";
      };
    };
    
    nixosModules.${system}.default = { config, lib, ... }: {
      options.programs.septabee = with lib;  {
    		enable = mkEnableOption "septabee";
    		package = mkPackageOption septabee-pkg;
    		wayland = mkOption {
     			type = types.bool;
     			default = !config.services.xserver.enable;
     			example = false;
     			description = "Toggle Wayland-specific buildInputs.";
    		};
     	};

      config = let
        c = config.programs.septabee;
        p = c.package.override { use-wayland = c.wayland; };
      in lib.mkIf c.enable {
      	environment.systemPackages = [
     			p
    		];
        
        security.wrappers.septabee = {
          owner = "root";
          group = "root";
          permissions = "u-rwx,g=rx,o=rx";
          capabilities = "cap_sys_nice+ep";
          source = "${septabee-pkg}/lib/septabee";
        };

        security.wrappers.septabee-sounds = {
          owner = "root";
          group = "root";
          permissions = "u-rwx,g=rx,o=rx";
          capabilities = "cap_sys_nice+ep";
          source = "${septabee-pkg}/lib/septabee-sounds";
        };
      };
    };
  };
}
