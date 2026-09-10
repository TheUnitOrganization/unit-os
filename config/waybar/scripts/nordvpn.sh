#!/usr/bin/env bash
# Waybar: NordVPN state. The AUR nordvpn-bin package ships only the CLI and the
# daemon - it has tray *icons* in /usr/share/icons but no tray program to draw
# them - so this reads `nordvpn status` instead and renders the same thing as a
# bar capsule, matching network / pulseaudio / bluetooth next to it.
set -uo pipefail

ICON_ON="󰕥"    # shield-check
ICON_OFF="󰦝"   # shield-off

# Click action. Toggling is a slow call (a few seconds to bring the tunnel up),
# so it runs detached and the bar refreshes on its own signal afterwards.
if [ "${1:-}" = "toggle" ]; then
    if nordvpn status 2>/dev/null | tr -d '\r' | grep -q "^Status: Connected"; then
        nordvpn disconnect >/dev/null 2>&1
    else
        nordvpn connect >/dev/null 2>&1
    fi
    exit 0
fi

json() { printf '{"text":"%s","class":"%s","tooltip":"%s"}\n' "$1" "$2" "$3"; }

command -v nordvpn >/dev/null || { json "$ICON_OFF" disabled "NordVPN not installed"; exit 0; }

# The daemon owns the socket; without it every CLI call blocks for a while.
systemctl is-active --quiet nordvpnd || { json "$ICON_OFF" critical "nordvpnd is not running\\n\\nsudo systemctl start nordvpnd"; exit 0; }

# `nordvpn status` draws a spinner, so strip CR and ANSI before parsing.
raw=$(timeout 5 nordvpn status 2>/dev/null | tr -d '\r' | sed 's/\x1b\[[0-9;]*[A-Za-z]//g')
field() { printf '%s\n' "$raw" | grep -m1 "^$1:" | cut -d: -f2- | sed 's/^ *//'; }

state=$(field Status)

if [ "$state" = "Connected" ]; then
    country=$(field Country)
    city=$(field City)
    server=$(field Server)
    tech=$(field "Current technology")
    xfer=$(field Transfer)
    # Country as a 2-letter tag, so the pill stays the width of the ones
    # beside it. "Venezuela" -> VE, "United States" -> US.
    # One-word country -> first two letters (Venezuela -> VE); multi-word ->
    # initials (United States -> US). Either way a 2-char tag.
    tag=$(printf '%s\n' "$country" | awk '{if (NF>1) {for(i=1;i<=NF;i++) printf "%s", toupper(substr($i,1,1))} else printf "%s", toupper(substr($1,1,2))}' | cut -c1-2)
    [ -n "$tag" ] || tag="ON"
    json "$ICON_ON $tag" ok "NordVPN: $country - $city\\n$server\\n$tech\\n$xfer\\n\\nclick to disconnect"
else
    json "$ICON_OFF" off "NordVPN: ${state:-Disconnected}\\n\\nclick to connect"
fi
