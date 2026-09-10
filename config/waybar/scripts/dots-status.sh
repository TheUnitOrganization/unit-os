#!/usr/bin/env bash
# Waybar: are the dotfiles saved? Green when everything is committed, red when
# tracked files have uncommitted changes. State comes from the actual diff, not
# from how long ago the last save was - age says nothing about whether the
# configs on disk match the repo.
set -uo pipefail
dots() { git --git-dir="$HOME/.dotfiles" --work-tree="$HOME" "$@"; }

[ -d "$HOME/.dotfiles" ] || { echo '{"text":"󰆓","class":"critical","tooltip":"~/.dotfiles missing"}'; exit 0; }

last_rel=$(dots log -1 --format=%cr 2>/dev/null || echo "never")
dirty=$(dots status --porcelain --untracked-files=no 2>/dev/null | wc -l)
ahead=$(dots rev-list --count @{u}..HEAD 2>/dev/null || echo "no remote")

# Icon only - the colour carries the state, the tooltip carries the detail.
text="󰆓"
if [ "$dirty" -gt 0 ]; then
    cls=critical
    tip="Dotfiles: $dirty unsaved change(s)\nlast save: $last_rel\nunpushed: $ahead\n\nclick to save now"
else
    cls=ok
    tip="Dotfiles: all saved\nlast save: $last_rel\nunpushed: $ahead\n\nclick to save now"
fi

printf '{"text":"%s","class":"%s","tooltip":"%s"}\n' "$text" "$cls" "$tip"
