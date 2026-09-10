-- WINDOW RULES ----------------------------------------------------------
hl.window_rule({
    name  = "suppress-maximize-events",
    match = { class = ".*" },
    suppress_event = "maximize",
})

-- Fix dragging issues with XWayland
hl.window_rule({
    name  = "fix-xwayland-drags",
    match = { class = "^$", title = "^$", xwayland = true,
              float = true, fullscreen = false, pin = false },
    no_focus = true,
})

-- Small utility windows should float, not tile.
hl.window_rule({
    name  = "float-utilities",
    match = { class = "^(pavucontrol|blueman-manager|nm-connection-editor|swappy|xarchiver|nwg-look)$" },
    float = true,
})

-- File chooser / dialog portals
hl.window_rule({
    name  = "float-dialogs",
    match = { title = "^(Open File|Save File|Open Folder|Confirm|File Operation Progress)$" },
    float = true,
})

-- Never blur or dim the lock screen / notification layers
hl.layer_rule({
    name  = "no-anim-hyprlock",
    match = { namespace = "^hyprlock$" },
    no_anim = true,
})

-- Real glass: blur whatever is behind the waybar layer. Without this the
-- translucent pills just show the wallpaper straight through.
hl.layer_rule({
    name  = "blur-waybar",
    match = { namespace = "^waybar$" },
    blur  = true,
    ignore_alpha = 0.2,
})

-- Blur rofi and the notification popups too, so they match the bar.
-- ignore_alpha matters: without it Hyprland blurs the layer's whole
-- rectangle, transparent corners included, so a rounded notification sits
-- on a visible square of blurred backdrop (white on a white page).
hl.layer_rule({
    name  = "blur-rofi",
    match = { namespace = "^(rofi|notifications)$" },
    blur  = true,
    ignore_alpha = 0.2,
})

-- Task manager (CTRL+SHIFT+ESC): a big centred floating window, so it lands
-- on top of whatever is stuck instead of reshuffling the tiling tree.
hl.window_rule({
    name  = "float-taskmgr",
    match = { class = "^btop$" },
    float = true,
    center = true,
    -- Percent strings ("70%") are silently ignored by 0.56's Lua rules, so
    -- these are pixels: 70% x 75% of the 1440x810 logical screen (2880x1620 @ scale 2).
    size = { 1008, 607 },
})

-- Rofi should appear already open. Without this Hyprland animates the layer
-- in, and because rofi maps at inputbar height and then grows to fit its
-- entries, you watch a horizontal line stretch open from the centre.
hl.layer_rule({
    name    = "no-anim-rofi",
    match   = { namespace = "^rofi$" },
    no_anim = true,
})

-- Thunar's dialogs (Rename, Properties, Bulk Rename, progress) are real
-- toplevels, not in-window popovers, so under tiling each one steals a slot
-- and reshuffles the layout. Thunar 4.20 has no inline-rename preference --
-- `strings /usr/bin/thunar` lists every misc-* key and there is none -- so
-- making the dialog behave like the modal it is, is the available fix.
hl.window_rule({
    name   = "float-thunar-dialogs",
    match  = { class = "^([Tt]hunar)$",
               title = "^(Rename.*|Bulk Rename.*|Properties.*|Permissions.*|"
                    .. "Open With.*|Create New.*|Confirm.*|Replace.*|"
                    .. "File Operation Progress|Copying.*|Moving.*|Deleting.*)$" },
    float  = true,
    center = true,
})
