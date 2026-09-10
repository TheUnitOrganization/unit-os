-- MONITORS --------------------------------------------------------------
-- Pinned explicitly: "preferred" can negotiate down to 60Hz on this panel.
-- Verify with: hyprctl monitors
hl.monitor({
    output   = "eDP-1",
    mode     = "2880x1620@120",
    position = "auto",
    scale    = 2,
})

-- Fallback for any monitor plugged in later (HDMI/USB-C dock).
hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = "auto",
})
