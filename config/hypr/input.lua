-- INPUT -----------------------------------------------------------------
hl.config({
    input = {
        -- Three layouts, cycled with SUPER+SHIFT+SPACE (see binds.lua).
        -- us = plain ANSI, pt = Portuguese, latam = Spanish (Latin America).
        kb_layout    = "us,pt,latam",
        follow_mouse = 1,
        sensitivity  = 0,

        touchpad = {
            natural_scroll        = true,  -- laptop: scroll like a phone
            disable_while_typing  = true,
            tap_to_click          = true,
        },
    },
})

-- Three-finger horizontal swipe changes workspace.
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
