#!/usr/bin/env bash
# Waybar clock that names its timezone ("Lisbon 23:01") instead of printing
# an abbreviation (WEST / -04). Right-click in the bar calls this with
# `toggle`. Only the bar changes -- the system clock stays on Portugal time.
set -uo pipefail

STATE="${XDG_CACHE_HOME:-$HOME/.cache}/waybar-clock-tz"
[ -f "$STATE" ] || printf 'Europe/Lisbon\n' > "$STATE"

if [ "${1:-}" = "toggle" ]; then
    if [ "$(cat "$STATE")" = "Europe/Lisbon" ]; then
        printf 'America/Caracas\n' > "$STATE"
    else
        printf 'Europe/Lisbon\n' > "$STATE"
    fi
fi

tz=$(cat "$STATE")
case "$tz" in
    Europe/Lisbon)   label="Lisbon"  ;;
    America/Caracas) label="Caracas" ;;
    *)               label="$tz"     ;;
esac

text="$(TZ="$tz" date +%H:%M) $label"

# Tooltip: both zones at once, plus this month's calendar.
lis=$(TZ=Europe/Lisbon   date '+%H:%M')
car=$(TZ=America/Caracas date '+%H:%M')
day=$(TZ="$tz" date '+%A, %d %B %Y')
calendar=$(TZ="$tz" cal | sed 's/&/\&amp;/g; s/</\&lt;/g')

tooltip="<b>${day}</b>\n\nLisbon   ${lis}\nCaracas  ${car}\n\n<tt>${calendar}</tt>"

# JSON so waybar gets text and tooltip separately.
printf '{"text":"%s","tooltip":"%s","class":"clock"}\n' \
    "$text" "$(printf '%s' "$tooltip" | sed ':a;N;$!ba;s/\n/\\n/g; s/"/\\"/g')"
