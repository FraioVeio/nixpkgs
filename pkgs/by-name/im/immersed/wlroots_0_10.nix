{
  lib,
  stdenv,
  fetchgit,
  meson,
  ninja,
  pkg-config,
  wayland-scanner,
  libGL,
  mesa-gl-headers,
  wayland,
  wayland-protocols,
  libinput,
  libxkbcommon,
  pixman,
  libgbm,
  udev,
}:

# wlroots 0.10.0 provides libwlroots.so.5 (so_version = ['5','9','1']).
# Each wlroots minor release increments the soversion by one starting from
# 0.6.0 = soversion 1, so 0.10.x is the only series that matches .so.5.
# Fetched via fetchgit because the GitLab archive endpoint returns 404 for
# old tags.
stdenv.mkDerivation (finalAttrs: {
  pname = "wlroots";
  version = "0.10.0";

  src = fetchgit {
    url = "https://gitlab.freedesktop.org/wlroots/wlroots.git";
    rev = finalAttrs.version;
    hash = "sha256-yOLfjwpM5WsclQ7Rt5eo9eLcErJjRjAI6bNo7dMNGDA=";
  };

  strictDeps = true;
  depsBuildBuild = [ pkg-config ];

  nativeBuildInputs = [
    meson
    ninja
    pkg-config
    wayland-scanner
  ];

  propagatedBuildInputs = [ libinput ];

  buildInputs = [
    libGL
    mesa-gl-headers
    wayland
    wayland-protocols
    libxkbcommon
    pixman
    libgbm
    udev
  ];

  # include/types/wlr_seat.h declares the three default grab impls without
  # `extern`, making them tentative definitions in every TU that includes the
  # header. GCC 10+ defaults to -fno-common, so the linker sees multiple
  # definitions at link time. Adding `extern` turns them into proper
  # declarations and lets each .c file own exactly one definition.
  postPatch = ''
    substituteInPlace include/types/wlr_seat.h \
      --replace-fail \
        'const struct wlr_pointer_grab_interface default_pointer_grab_impl;' \
        'extern const struct wlr_pointer_grab_interface default_pointer_grab_impl;' \
      --replace-fail \
        'const struct wlr_keyboard_grab_interface default_keyboard_grab_impl;' \
        'extern const struct wlr_keyboard_grab_interface default_keyboard_grab_impl;' \
      --replace-fail \
        'const struct wlr_touch_grab_interface default_touch_grab_impl;' \
        'extern const struct wlr_touch_grab_interface default_touch_grab_impl;'
  '';

  mesonFlags = [
    (lib.mesonEnable "xwayland" false)
    (lib.mesonEnable "x11-backend" false)
    (lib.mesonEnable "xcb-errors" false)
    (lib.mesonEnable "xcb-icccm" false)
    (lib.mesonEnable "logind" false)
    (lib.mesonEnable "libcap" false)
    (lib.mesonBool "examples" false)
    (lib.mesonBool "werror" false)
  ];

  meta = {
    description = "Modular Wayland compositor library";
    homepage = "https://gitlab.freedesktop.org/wlroots/wlroots";
    changelog = "https://gitlab.freedesktop.org/wlroots/wlroots/-/tags/${finalAttrs.version}";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
    maintainers = with lib.maintainers; [
      wineee
      doronbehar
    ];
  };
})
