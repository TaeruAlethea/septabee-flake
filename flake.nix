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
    depends = with pkgs; [
      libpng
      vulkan-loader
      freetype
      pipewire
      libx11
      stdenv.cc.cc.lib
      lilv
      zstd
      ncurses
      wayland
      libxkbcommon
      kdePackages.wayland
    ];
    version = "yeet-44";

    septabee-pkg = pkgs.stdenv.mkDerivation {
        name = "septabee-${version}";
        version = version;
        src = pkgs.fetchurl {
          url = "https://septabee.nekoweb.org/important_stuff/SEPTABEE_DOWNLOADS/version_B/septabee_linux_B_T2.7z";
          sha256 = "sha256-OMnbRBTku8yi4b3Ay7d70EbB/e2Qh+PfzK2O8qRFoaA=";
        };

        nativeBuildInputs = with pkgs; [
          p7zip
          autoPatchelfHook
          makeWrapper
        ];

        buildInputs = depends;

        unpackPhase = ''
          runHook preUnpack
          7z x "$src"
          runHook postUnpack
        '';

        installPhase = ''
          runHook preInstall
          mkdir -p "$out/bin" 
          cp -r ./linux/* "$out/bin/"
          runHook postInstall
        '';

        postFixup = ''
          wrapProgram "$out/bin/septabee" \
            --chdir "$out" \
            --run "
              data_home=\"\''\${XDG_DATA_HOME:-\$HOME/.local/share}\"
              abi_dir=\"\$data_home/Septabee/llvm-stuffs/abi-8\"

              mkdir -p \"\$abi_dir\"
            "
        '';
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
    
    nixosModules.${system}.default = { ... }: {
      security.wrappers.septabee = {
        owner = "root";
        group = "root";
        permissions = "u-rwx,g=rx,o=rx";
        capabilities = "cap_sys_nice+ep";
        source = "${septabee-pkg}/bin/septabee";
      };

      security.wrappers.septabee-sounds = {
        owner = "root";
        group = "root";
        permissions = "u-rwx,g=rx,o=rx";
        capabilities = "cap_sys_nice+ep";
        source = "${septabee-pkg}/bin/septabee-sounds";
      };
    };
  };
}
