-- ENVIRONMENT -----------------------------------------------------------
-- Cursor
hl.env("XCURSOR_SIZE",   "24")
hl.env("HYPRCURSOR_SIZE", "24")

-- Force Chromium/Electron apps (Brave) onto native Wayland instead of
-- XWayland. Without this Brave renders through XWayland and looks blurry
-- on this 2880x1620 @ scale 2 panel.
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "wayland")

-- Qt apps native Wayland too.
hl.env("QT_QPA_PLATFORM",                     "wayland;xcb")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
hl.env("QT_AUTO_SCREEN_SCALE_FACTOR",         "1")

-- NOTE: GDK_SCALE is deliberately NOT set. On Wayland, GTK reads the scale
-- from the compositor; setting GDK_SCALE=2 on top of a scale-2 monitor
-- double-scales every GTK app (Thunar, nwg-look) to comic proportions.
