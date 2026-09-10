-- KEYBINDINGS -----------------------------------------------------------
local mainMod     = "SUPER"
-- Fallbacks: until `bash ~/setup-finish.sh` installs kitty and rofi, these
-- fall back to the packages that are already present, so SUPER+Q and
-- SUPER+R can never leave you with no way to launch anything.
-- Once kitty/rofi are installed you can simplify these to just "kitty"
-- and "rofi -show drun".
local terminal    = [[sh -c 'command -v kitty >/dev/null && exec kitty || exec alacritty']]
local fileManager = "thunar"
local browser     = "brave"
local menu        = [[sh -c 'command -v rofi >/dev/null && exec rofi -show drun || exec hyprlauncher']]

-- Apps
hl.bind(mainMod .. " + Q",         hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + E",         hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + B",         hl.dsp.exec_cmd(browser))
hl.bind(mainMod .. " + R",         hl.dsp.exec_cmd(menu))

-- Task manager, the Windows CTRL+SHIFT+ESC muscle memory. btop is a TUI, so
-- this costs one kitty + one tiny process: no heavier than a plain terminal.
-- `nice -n -10` makes btop outrank everything else for CPU time when some
-- process is pegging the cores. Until setup-finish.sh grants your user
-- negative nice it just prints a warning and runs at 0 -- never fails.
-- Class "btop" matches the float+center rule in rules.lua.
-- Inside btop: k = kill, t = terminate, f = filter, m/c sort by mem/cpu.
hl.bind("CTRL + SHIFT + ESCAPE", hl.dsp.exec_cmd("kitty --class btop -e nice -n -10 btop"))

-- Window management
hl.bind(mainMod .. " + W",         hl.dsp.window.close())

-- Web apps. --app= gives a chromeless window with no tabs or address bar,
-- so it behaves like a native app rather than a browser tab.
hl.bind(mainMod .. " + Y",         hl.dsp.exec_cmd("brave --app=https://youtube.com"))
-- C for Chat. Goes through ~/.local/bin/whatsapp so the window gets its own
-- class instead of "brave-browser", which is what lets rules.lua and waybar
-- tell it apart from a normal browser window.
hl.bind(mainMod .. " + C",         hl.dsp.exec_cmd("whatsapp"))
hl.bind(mainMod .. " + ALT + C",   hl.dsp.exec_cmd("brave --app=https://calendar.google.com"))
-- All of these are in rofi too (SUPER+R) via ~/.local/share/applications,
-- so the keys are a shortcut, never the only way in.
-- The keys cheatsheet in a normal window: --app= strips the address bar and
-- back button, which is right for WhatsApp but wrong for a document.
-- SUPER+/ = every keybinding as a checklist (Omarchy's SUPER+K, but K is
-- focus-up here). Read live from this file, so it never goes stale. SPACE
-- ticks the highlighted row and ticked rows sink to the bottom, so the top of
-- the list is always the keys still to learn. The script drives rofi itself
-- now -- it has to, because ticking means re-running rofi with a new order --
-- so this is a plain exec, not a pipe.
hl.bind(mainMod .. " + SLASH",     hl.dsp.exec_cmd([[sh -c '$HOME/.config/hypr/scripts/keybinds.py']]))
-- The system guide and the to-do list, one shift away from the cheatsheet.
hl.bind(mainMod .. " + SHIFT + SLASH", hl.dsp.exec_cmd([[sh -c 'brave "file://$HOME/Documents/system-guide.html"']]))
hl.bind(mainMod .. " + SHIFT + D",     hl.dsp.exec_cmd([[sh -c 'kitty --title TODO -e nvim "$HOME/Documents/TODO.md"']]))
-- Session log: a page per working session (built / gotchas / still open)
hl.bind(mainMod .. " + D",         hl.dsp.exec_cmd([[sh -c 'brave "file://$HOME/Documents/sessions/index.html"']]))

-- The agent pair. A opens Claude Code, X says what it has cost you:
-- reach for the work, then check the bill.
hl.bind(mainMod .. " + A",         hl.dsp.exec_cmd("agent"))
-- Agentic usage: a dismissible notification, no window to manage.
hl.bind(mainMod .. " + X",         hl.dsp.exec_cmd("$HOME/.config/waybar/scripts/ai-notify.sh"))
-- N for Notifications: bring back the last one you dismissed or missed.
-- Press again to keep walking further back through the history. Nothing
-- else on this machine can recall a notification once it has gone.
hl.bind(mainMod .. " + N",         hl.dsp.exec_cmd("dunstctl history-pop"))
-- Clock timezone: flip the waybar clock between Lisbon and Caracas. Same
-- toggle as right-clicking the clock pill; only the bar changes, the system
-- clock stays on Portugal time. Z = zone.
hl.bind(mainMod .. " + Z", hl.dsp.exec_cmd(
    [[sh -c '$HOME/.config/waybar/scripts/clock-tz.sh toggle >/dev/null && pkill -RTMIN+8 waybar']]))

-- Keyboard layout: cycle us -> pt -> latam (set in input.lua). Hyprland's
-- Lua config exposes no xkb dispatcher, so this goes through hyprctl.
-- "all" switches every keyboard at once, internal and USB; the signal
-- repaints the waybar language pill immediately.
hl.bind(mainMod .. " + SHIFT + SPACE", hl.dsp.exec_cmd(
    [[sh -c 'hyprctl switchxkblayout all next && pkill -RTMIN+10 waybar']]))

-- T for Tiling: SHIFT+T pops the focused window out of the grid and back
-- into it. SUPER+V is the same toggle, kept for muscle memory.
hl.bind(mainMod .. " + SHIFT + T", hl.dsp.window.float({ action = "toggle" }))
-- F for Fullscreen: plain F is real fullscreen (the window owns the screen,
-- no bar), SHIFT+F is maximized (fills the workspace, waybar and gaps stay).
hl.bind(mainMod .. " + F",         hl.dsp.window.fullscreen())
hl.bind(mainMod .. " + SHIFT + F", hl.dsp.window.fullscreen({ mode = "maximized" }))
hl.bind(mainMod .. " + P",         hl.dsp.window.pseudo())
hl.bind(mainMod .. " + T",         hl.dsp.exec_cmd("telegram-desktop"))
-- Flip the next split between beside/below. The "\" key looks like the
-- split it makes, and nothing else claims it. "`" is the same dispatcher on
-- the other end of the keyboard, for whichever hand is free.
hl.bind(mainMod .. " + backslash", hl.dsp.layout("togglesplit"))
hl.bind(mainMod .. " + grave",     hl.dsp.layout("togglesplit"))

-- Session
hl.bind(mainMod .. " + ALT + L",   hl.dsp.exec_cmd("hyprlock"))
hl.bind(mainMod .. " + M",         hl.dsp.exec_cmd("wlogout"))

-- Focus: vim keys and arrows both, on purpose. hjkl here is the same
-- motion you use in tmux and Neovim -- three places, one muscle memory.
hl.bind(mainMod .. " + H", hl.dsp.focus({ direction = "left"  }))
hl.bind(mainMod .. " + J", hl.dsp.focus({ direction = "down"  }))
hl.bind(mainMod .. " + K", hl.dsp.focus({ direction = "up"    }))
hl.bind(mainMod .. " + L", hl.dsp.focus({ direction = "right" }))

hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left"  }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up"    }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down"  }))

-- Move the focused window around the tiling tree
hl.bind(mainMod .. " + SHIFT + H", hl.dsp.window.move({ direction = "left"  }))
hl.bind(mainMod .. " + SHIFT + J", hl.dsp.window.move({ direction = "down"  }))
hl.bind(mainMod .. " + SHIFT + K", hl.dsp.window.move({ direction = "up"    }))
hl.bind(mainMod .. " + SHIFT + L", hl.dsp.window.move({ direction = "right" }))

-- Snap the focused window to that side: the Windows "throw the window over
-- there" muscle memory, on SUPER+CTRL+arrow. Different from the SHIFT binds
-- above: move() re-parents the window in the tiling tree (and can push it onto
-- another monitor), this one keeps the layout's shape and just puts you on the
-- side you asked for. Bare swap() could only trade places with a window that
-- was already there, so in a top/bottom pair CTRL+left did nothing at all;
-- snap-window.py flips the split first when that is what "left" has to mean.
local snap = "$HOME/.config/hypr/scripts/snap-window.py"
hl.bind(mainMod .. " + CTRL + left",  hl.dsp.exec_cmd(snap .. " left"))
hl.bind(mainMod .. " + CTRL + right", hl.dsp.exec_cmd(snap .. " right"))
hl.bind(mainMod .. " + CTRL + up",    hl.dsp.exec_cmd(snap .. " up"))
hl.bind(mainMod .. " + CTRL + down",  hl.dsp.exec_cmd(snap .. " down"))

-- Workspaces 1-10
for i = 1, 10 do
    local key = tostring(i % 10)
    hl.bind(mainMod .. " + " .. key,         hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- Scratchpad
hl.bind(mainMod .. " + S",         hl.dsp.workspace.toggle_special("magic"))
-- SHIFT+S is the Windows snip key now, so throwing a window at the
-- scratchpad moved to ALT+S -- same ALT modifier as SUPER+ALT+L for lock.
hl.bind(mainMod .. " + ALT + S", hl.dsp.window.move({ workspace = "special:magic" }))

-- Scroll through workspaces
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

-- Drag / resize with the mouse
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Screenshots. Laid out on Windows muscle memory: PRINT is the whole
-- screen, SUPER+SHIFT+S is the snip. All three go through ~/.local/bin/shot.
-- What each leaves behind differs on purpose: a region snip is the throwaway
-- one -- you grab it to paste somewhere and never want it again -- so it only
-- reaches the clipboard. PRINT is the deliberate "keep this", so it writes a
-- PNG to ~/Pictures/Screenshots as well. Every mode notifies, which is what
-- makes a cancelled drag visible instead of reading as "screenshots broken".
--
-- Whole screen -> file + clipboard. Plain PRINT, exactly like Windows.
hl.bind("PRINT", hl.dsp.exec_cmd("shot full"))

-- Drag a region -> clipboard only, no file. The Snipping Tool chord.
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd("shot region"))

-- Drag a region, then annotate in swappy (arrows, boxes, text). Nothing is
-- written unless you press Ctrl+S there.
hl.bind("SHIFT + PRINT", hl.dsp.exec_cmd("shot edit"))

-- Drag a region -> saved PNG, and the PATH on the clipboard as text. For
-- handing a screenshot to a terminal program: a CLI cannot always pull an
-- image off the Wayland clipboard, but a pasted path works everywhere.
hl.bind(mainMod .. " + SHIFT + A", hl.dsp.exec_cmd("shot snip"))

-- Media keys
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      { locked = true, repeating = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { locked = true })
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   { locked = true })

-- Brightness. These binds existed in the default config but brightnessctl
-- was never installed, which is why the keys did nothing.
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"), { locked = true, repeating = true })

hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })

-- Wallpaper: skip to another image from the current theme's set (hyprpaper
-- rotates on its own every 30 min; `wall-next` does it on demand).
hl.bind(mainMod .. " + SHIFT + B", hl.dsp.exec_cmd("wall-next"))
