#!/usr/bin/env bash
# Claude Code Stop hook: save the configs this session touched.
#
# This used to only nag. Saving by hand every time was the annoying part, so
# now it just does it -- the whole point of the repo is that you can look
# back, and an autosave commit is cheaper than a lost config.
# The real work is in ~/.local/bin/dots-autosave.
set -uo pipefail

n=$("$HOME/.local/bin/dots-autosave" 2>/dev/null) || exit 0
[ -n "$n" ] || exit 0

printf '{"systemMessage":"dotfiles: autosaved %s changed config file(s) to ~/.dotfiles"}\n' "$n"
