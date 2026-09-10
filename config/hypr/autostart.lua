-- AUTOSTART -------------------------------------------------------------
-- This is the block that was entirely commented out in the default config,
-- which is why waybar / wallpaper / notifications never appeared.
hl.on("hyprland.start", function()
    -- FIRST, and by absolute path. tty1 autologins now (setup-autologin),
    -- so this lock screen IS the login prompt -- if PATH ever regressed and
    -- this silently failed to launch, the machine would boot to an unlocked
    -- desktop. hypridle still calls plain `hyprlock` for idle locking.
    hl.exec_cmd([[sh -c '$HOME/.local/bin/lock-boot']])

    hl.exec_cmd("waybar")
    hl.exec_cmd("hyprpaper")
    hl.exec_cmd("dunst")
    hl.exec_cmd("hypridle")
    hl.exec_cmd("blueman-applet")
end)
