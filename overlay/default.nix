final: prev:
let
  rpi-kernel = { kernel, version, fw }:
    let
      new-kernel = prev.linux_rpi4.override {
        argsOverride = {
          src = kernel;
          inherit version;
          modDirVersion = version;
        };
      };
      new-fw = prev.raspberrypifw.overrideAttrs (oldfw: { src = fw; });
      version-slug = builtins.replaceStrings [ "." ] [ "_" ] version;
    in {
      "linux_rpi-${version-slug}" = new-kernel;
      "raspberrypifw-${version-slug}" = new-fw;
    };
  rpi-kernels = builtins.foldl' (b: a: b // rpi-kernel a) { };
in {
  # newer version of libcamera
  libcamera = prev.libcamera.overrideAttrs (old: {
    src = prev.fetchgit {
      url = "https://git.libcamera.org/libcamera/libcamera.git";
      rev = "44d59841e1ce59042b8069b8078bc9f7b1bfa73b";
      sha256 = "1nzkvy2y772ak9gax456ws2fmjc9ncams0m1w27h1rzpxn5yphqr";
    };
    mesonFlags = [ "-Dv4l2=true" "-Dqcam=disabled" "-Dlc-compliance=disabled" ];
    patches = (old.patches or [ ]) ++ [ ./libcamera.patch ];
  });

  libcamera-apps = final.callPackage ./libcamera-apps.nix { };

  # provide generic rpi arm64 u-boot
  uboot_rpi_arm64 = prev.buildUBoot rec {
    defconfig = "rpi_arm64_defconfig";
    extraMeta.platforms = [ "aarch64-linux" ];
    filesToInstall = [ "u-boot.bin" ];
    version = "2022.07";
    src = prev.fetchurl {
      url = "ftp://ftp.denx.de/pub/u-boot/u-boot-${version}.tar.bz2";
      sha256 = "0png7p8k6rwbmmcyhc22xczcaz7kx0dafw5zmp0i9ni4kjs8xc4j";
    };
  };
} // (rpi-kernels [
  {
    version = "5.15.36";
    kernel = prev.fetchFromGitHub {
      owner = "raspberrypi";
      repo = "linux";
      rev = "9af1cc301e4dffb830025207a54d0bc63bec16c7";
      sha256 = "fsMTUdz1XZhPaSXpU1uBV4V4VxoZKi6cwP0QJcrCy1o=";
      fetchSubmodules = true;
    };
    fw = prev.fetchFromGitHub {
      owner = "raspberrypi";
      repo = "firmware";
      rev = "2cf8a179b3f2e6e5e5ceba4e8e544def10a49020";
      sha256 = "YG1bryflbV3W62MhZ/XMSgUJXMhCl/fe86x+CT7XZ4U=";
    };
  }
  {
    version = "5.15.56";
    kernel = prev.fetchFromGitHub {
      owner = "raspberrypi";
      repo = "linux";
      rev = "912b039b7c55d40ae930f2602e45c66055c375a8";
      sha256 = "igtTOPbDw9FJAzZe7u4trCkHLOIQX0RZdUwtWpBX1Ag=";
      fetchSubmodules = true;
    };
    fw = prev.fetchFromGitHub {
      owner = "raspberrypi";
      repo = "firmware";
      rev = "e1e3dc004ec45c0a6ab3f32eb02c1e0c8846796c";
      sha256 = "Smn3wQ81zzmj+Wpt2Xwby+0Zt7YGhmhlaEscbaZaMmI=";
    };
  }
])