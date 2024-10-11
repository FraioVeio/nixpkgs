{ callPackage
, lib
, stdenv
, fetchurl
, nixos
, xorg
, glib, libGLU, libGL, libpulseaudio, zlib, dbus, fontconfig, freetype
, gtk3, pango
, makeWrapper , python3Packages, libcap
, lsof, curl, libuuid, cups, mesa, xz, libxkbcommon, steam-run
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "chitubox";
  version = "2.1.0";

  src = fetchurl {
    url = "https://sac.chitubox.com/software/download.do?softwareId=17839&softwareVersionId=v2.1.0&fileName=CHITUBOX_V2.1.0.tar.gz";
    hash = "sha256-mxTc4mYTKgjAU0B24ck7X3GGs1iF6WdGprGDYoUHF0M=";
    name = "chitubox.tar.gz";
  };

  unpackPhase = "true";

  buildInputs = [ steam-run ];

  buildPhase = ''

    export LD_LIBRARY_PATH=${
      lib.makeLibraryPath (with xorg; [
        libGLU libGL
        fontconfig
        freetype
        libpulseaudio
        zlib
        dbus
        libX11
        libXi
        libSM
        libICE
        libXrender
        libXScrnSaver
        libxcb
        libcap
        glib
        gtk3
        pango
        curl
        libuuid
        cups
        xcbutilwm         # libxcb-icccm.so.4
        xcbutilimage      # libxcb-image.so.0
        xcbutilkeysyms    # libxcb-keysyms.so.1
        xcbutilrenderutil # libxcb-render-util.so.0
        xz
        libxkbcommon
      ])
    }:$LD_LIBRARY_PATH

    tar xzvf $src
    mkdir install_root
    ls -l
    steam-run ./CHITUBOX_Basic_Linux_Installer_V2.1.run --root install_root --accept-licenses --no-size-checking --accept-messages --confirm-command install
  '';

  installPhase = ''
    mkdir -p $out
    cp -r install_root/* $out/.
  '';

  meta = with lib; {
    description = "Program that produces a familiar, friendly greeting";
    longDescription = ''
      GNU Hello is a program that prints "Hello, world!" when you run it.
      It is fully customizable.
    '';
    homepage = "https://www.gnu.org/software/hello/manual/";
    changelog = "https://git.savannah.gnu.org/cgit/hello.git/plain/NEWS?h=v${finalAttrs.version}";
    license = licenses.gpl3Plus;
    maintainers = [ ];
    mainProgram = "hello";
    platforms = platforms.all;
  };
})
