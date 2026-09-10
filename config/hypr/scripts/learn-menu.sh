#!/usr/bin/env bash
# SUPER+ALT+SPACE: the "Learn" menu, Omarchy-style. Everything you might
# need to look up, in one searchable list.
set -uo pipefail
D="$HOME/Documents"
choice=$(printf '%s\n' \
  "keys        every keybinding, searchable" \
  "guide       system guide (what this desktop is, how to rebuild it)" \
  "todo        the one to-do list" \
  "cheatsheet  keys cheat sheet, as a page" \
  "sessions    logs written by Claude sessions" \
  "nvim        Neovim's interactive tutorial" \
  "hyprland    Hyprland wiki" \
  "arch        Arch wiki" \
  "omarchy     the Omarchy manual (same ideas, DHH's version)" \
  | rofi -sync -dmenu -i -p learn -mesg "Learn — pick what to open") || exit 0
case "${choice%% *}" in
  keys)       "$HOME/.config/hypr/scripts/keybinds.py" | rofi -sync -dmenu -i -p keys -mesg "Every keybinding (type to filter)" >/dev/null ;;
  guide)      brave "file://$D/system-guide.html" ;;
  todo)       kitty --title TODO -e nvim "$D/TODO.md" ;;
  cheatsheet) brave "file://$D/cheatsheets.html" ;;
  sessions)   brave "file://$D/sessions/index.html" ;;
  nvim)       kitty --title "nvim tutor" -e nvim +Tutor ;;
  hyprland)   brave "https://wiki.hypr.land/Configuring/Basics/Binds/" ;;
  arch)       brave "https://wiki.archlinux.org/" ;;
  omarchy)    brave "https://learn.omacom.io/2/the-omarchy-manual" ;;
esac
