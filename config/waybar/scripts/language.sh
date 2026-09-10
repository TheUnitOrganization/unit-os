#!/usr/bin/env bash
# Active keyboard layout, as a two-letter pill.
#
# Waybar 0.15's built-in `hyprland/language` module renders an empty label
# here (it never picks up the layout from a Lua-configured Hyprland), so this
# reads the main keyboard out of `hyprctl devices -j` instead -- same reason
# the clock is a script rather than waybar's clock module.
#
# Refresh is signal-driven: SUPER+SHIFT+SPACE and a click on the pill both
# send RTMIN+10 after switching, so the pill changes the instant you do. The
# interval in config.jsonc is only a slow safety net.
set -uo pipefail

keymap=$(hyprctl devices -j 2>/dev/null \
    | jq -r 'first(.keyboards[] | select(.main) | .active_keymap) // empty')
[ -n "$keymap" ] || keymap="unknown"

# Short label per layout in kb_layout (input.lua). Add a line here when you
# add a layout there.
case "$keymap" in
    "English (US)")             short="US" ;;
    Portuguese*)                short="PT" ;;
    "Spanish (Latin American)") short="ES" ;;
    Spanish*)                   short="ES" ;;
    *)                          short="${keymap:0:2}" ;;
esac

tooltip="<b>${keymap}</b>\n\nSUPER+SHIFT+SPACE cycles US -> PT -> ES\nClick the pill to do the same"

printf '{"text":"%s","tooltip":"%s","class":"language"}\n' "$short" "$tooltip"
