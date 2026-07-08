{
  pname,
  version,
  src,
  meta,
  appimageTools,
  callPackage,
  libgpg-error,
  webkitgtk_4_1,
  patchelf,
  runCommand,
  stdenv,
  lib,
}:

let
  wlroots_0_10 = callPackage ./wlroots_0_10.nix { };

  src' = appimageTools.extract {
    inherit pname version;
    src = src;

    # Because of https://github.com/NixOS/nixpkgs/issues/267408
    postExtract = ''
      cp ${libgpg-error}/lib/* $out/usr/lib/
    '';
  };

  # The aarch64 AppImage only bundles libgpg-error; all other libs must come from
  # the FHS environment. webkitgtk_4_0 and its JSCore were removed from nixpkgs;
  # webkitgtk_4_1 exports the same API — the soname change only reflects the
  # libsoup2→libsoup3 switch in webkit's internals.
  src'' =
    if stdenv.hostPlatform.isAarch64 then
      runCommand "${pname}-${version}-patched-src" { nativeBuildInputs = [ patchelf ]; } ''
        cp -rP ${src'} $out
        chmod -R u+w $out
        find $out -type f | while read -r f; do
          patchelf --replace-needed libwebkit2gtk-4.0.so.37 libwebkit2gtk-4.1.so.0 "$f" 2>/dev/null || true
          patchelf --replace-needed libjavascriptcoregtk-4.0.so.18 libjavascriptcoregtk-4.1.so.0 "$f" 2>/dev/null || true
        done
      ''
    else
      src';
in

appimageTools.wrapAppImage {
  inherit pname version meta;
  src = src'';

  extraPkgs =
    pkgs: with pkgs; [
      libva
      # VAAPI backends
      nvidia-vaapi-driver
      mesa
      # Other dependencies
      libgpg-error
      fontconfig
      libGL
      libgbm
      wayland
      pipewire
      fribidi
      harfbuzz
      freetype
      libthai
      e2fsprogs
      zlib
      libp11
      libx11
      libsm
    ]
    ++ lib.optionals stdenv.hostPlatform.isx86 [
      intel-media-driver
      intel-vaapi-driver
    ]
    ++ lib.optionals stdenv.hostPlatform.isAarch64 [
      # webkit (sonames patched from 4.0 to 4.1 above)
      webkitgtk_4_1
      # UI toolkit libs not bundled in the aarch64 AppImage (bundled in x86_64)
      pulseaudio
      gtk3
      pango
      gdk-pixbuf
      glib
      cairo
      libxrandr
      libxcomposite
      libxdamage
      libxfixes
      libxinerama
      libxext
      libxxf86vm
      libxtst
      # wlroots 0.10 provides libwlroots.so.5 (soversion=5); each wlroots minor
      # release increments soversion, so 0.10.x is the only series that matches.
      wlroots_0_10
    ];

  multiArch = true;
}
