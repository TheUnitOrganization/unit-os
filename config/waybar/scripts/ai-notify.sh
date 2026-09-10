#!/usr/bin/env bash
# Toggle the AI usage snippet as a notification.
#
# A real toggle: it remembers the id of the notification it raised and closes
# only that one, so pressing the key never swallows an unrelated popup (a
# volume or battery notification). It stays up until toggled off rather than
# expiring on a timer.
set -uo pipefail

USAGE="$HOME/.config/waybar/scripts/ai-usage.py"
STATE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/ai-usage"
ID_FILE="$STATE_DIR/notify-id"
mkdir -p "$STATE_DIR"

close_by_id() {
    gdbus call --session \
        --dest org.freedesktop.Notifications \
        --object-path /org/freedesktop/Notifications \
        --method org.freedesktop.Notifications.CloseNotification "$1" \
        >/dev/null 2>&1
}

displayed=$(dunstctl count displayed 2>/dev/null || echo 0)

# Ours is up -> take it down. If nothing is on screen at all the user already
# dismissed it, so fall through and show it again instead of eating the press.
if [ -s "$ID_FILE" ] && [ "$displayed" -gt 0 ]; then
    close_by_id "$(cat "$ID_FILE")"
    : > "$ID_FILE"
    exit 0
fi

body=$("$USAGE" --notify 2>/dev/null) || body="could not read usage"

# -t 0 = stays until toggled off. -p prints the id so we can close just this one.
id=$(notify-send -a "AI usage" -u low -t 0 -p \
        -h string:x-dunst-stack-tag:ai-usage \
        "AI usage" "$body" 2>/dev/null) || id=""

printf '%s' "$id" > "$ID_FILE"
