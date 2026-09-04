{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        # "x86_64-windows" # Non-standard
      ];
      perSystem = { pkgs, ... }: rec {
        packages = {
          default = pkgs.stdenv.mkDerivation {
            pname = "septabee";
            version = "B_T2";
            src = pkgs.fetchurl {
              url = "https://septabee.nekoweb.org/important_stuff/SEPTABEE_DOWNLOADS/version_B/septabee_linux_B_T2.7z";
              sha256 = "sha256-OMnbRBTku8yi4b3Ay7d70EbB/e2Qh+PfzK2O8qRFoaA=";
            };

            nativeBuildInputs = with pkgs; [
              p7zip
              autoPatchelfHook
            ];

            buildInputs = with pkgs; [
              vulkan-loader
              pipewire
              libx11
              stdenv.cc.cc.lib
              libpng
              freetype
            ];

            appendRunpaths = with pkgs; [
              "${lib.makeLibraryPath [
                vulkan-loader
                pipewire
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
              name = "septabee";
              exec = name;
              desktopName = "Septabee DAW";
              genericName = "Septabee Digital Audio Workstation";
              categories = [
                "Audio"
              ];
            };
          };

        };

        apps = {
          default = {
            type = "app";
            program = "${packages.default}/bin/septabee";
          };
        };
      };
      flake.nixosModules.default =
        {
          config,
          lib,
          pkgs,
          ...
        }:
        {
          options.programs.septabee = with lib; {
            enable = mkEnableOption "septabee";
            package = septabee-pkg;
            wayland = mkOption {
              type = types.bool;
              default = !config.services.xserver.enable;
              example = false;
              description = "Toggle Wayland-specific buildInputs.";
            };
          };

          config =
            let
              c = config.programs.septabee;
              p = c.package.override {

                appendRunpaths = with pkgs; [
                  "${
                    lib.makeLibraryPath [
                      vulkan-loader
                      pipewire
                    ]
                    ++ pkgs.lib.optionals c.wayland [
                      wayland
                      libxkbcommon
                    ]
                  }"
                ];
              };
            in
            lib.mkIf c.enable {
              environment.systemPackages = [
                p
              ];

              security.wrappers.septabee = {
                owner = "root";
                group = "root";
                permissions = "u-rwx,g=rx,o=rx";
                capabilities = "cap_sys_nice+ep";
                source = "${p}/lib/septabee";
              };

              security.wrappers.septabee-sounds = {
                owner = "root";
                group = "root";
                permissions = "u-rwx,g=rx,o=rx";
                capabilities = "cap_sys_nice+ep";
                source = "${p}/lib/septabee-sounds";
              };

            };
        };
    };
}
