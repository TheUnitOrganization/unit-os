#!/usr/bin/env bash
#
# unit-os installer.
#
#   ./install.sh          copy configs into place  (what a fresh machine gets)
#   ./install.sh --link   symlink them back to this repo  (what the author runs)
#
# The two modes install the same files. Copy mode gives you your own divergable
# copy; link mode makes ~/.config/hypr and unit-os/config/hypr the same file, so
# an edit lands in the repo with no sync step.
#
#   --no-packages   skip pacman/AUR installs
#   --dry-run       print what would happen, touch nothing
#
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODE=copy
PACKAGES=1
DRY=0

for arg in "$@"; do
  case "$arg" in
    --link)        MODE=link ;;
    --copy)        MODE=copy ;;
    --no-packages) PACKAGES=0 ;;
    --dry-run)     DRY=1 ;;
    -h|--help)     sed -n '2,14p' "$0" | sed 's/^# \?//'; exit 0 ;;
    *) echo "unknown option: $arg" >&2; exit 1 ;;
  esac
done

say()  { printf '\033[1m::\033[0m %s\n' "$*"; }
warn() { printf '\033[33m::\033[0m %s\n' "$*" >&2; }
run()  { if [[ $DRY == 1 ]]; then printf '   would: %s\n' "$*"; else "$@"; fi; }

# ---------------------------------------------------------------- backup ----
# Anything we are about to replace is moved here first. Never overwrite blind.
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="$HOME/.local/share/unit-os/backup-$STAMP"

preserve() {
  # preserve <path> -- move an existing real file/dir out of the way
  local target="$1"
  [[ -e $target || -L $target ]] || return 0
  # An existing symlink already pointing into this repo needs no backup.
  if [[ -L $target && "$(readlink -f "$target")" == "$REPO"/* ]]; then
    return 0
  fi
  local rel="${target#$HOME/}"
  run mkdir -p "$BACKUP/$(dirname "$rel")"
  run mv "$target" "$BACKUP/$rel"
}

install_path() {
  # install_path <repo-relative-source> <absolute-destination>
  local src="$REPO/$1" dst="$2"
  [[ -e $src ]] || { warn "missing in repo: $1"; return 0; }
  preserve "$dst"
  run mkdir -p "$(dirname "$dst")"
  if [[ $MODE == link ]]; then
    run ln -sfn "$src" "$dst"
  else
    run cp -r "$src" "$dst"
  fi
}

install_templated() {
  # install_templated <repo-relative-source> <absolute-destination>
  # For formats with no variable expansion (.desktop, btop.conf): always a real
  # copy with $HOME substituted. Cannot be a symlink -- a symlink IS the repo
  # file, so there would be nowhere for the substitution to land.
  local src="$REPO/$1" dst="$2"
  [[ -e $src ]] || { warn "missing in repo: $1"; return 0; }
  preserve "$dst"
  run mkdir -p "$(dirname "$dst")"
  if [[ $DRY == 1 ]]; then
    printf '   would: template %s -> %s\n' "$1" "$dst"
  else
    sed "s|\$HOME|$HOME|g" "$src" > "$dst"
  fi
}

# ------------------------------------------------------------- packages ----
install_packages() {
  local native="$REPO/config/unit/pkglist-native.txt"
  local aur="$REPO/config/unit/pkglist-aur.txt"
  command -v pacman >/dev/null || { warn "not an Arch system, skipping packages"; return 0; }

  if [[ -f $native ]]; then
    say "installing native packages"
    run sudo pacman -S --needed --noconfirm - < "$native" || warn "some native packages failed"
  fi
  if [[ -f $aur ]]; then
    # paru on this machine is built against an old libalpm; yay is the working one.
    local helper=""
    for h in yay paru; do command -v "$h" >/dev/null && { helper="$h"; break; }; done
    if [[ -z $helper ]]; then
      warn "no AUR helper (yay/paru) found -- skipping $(wc -l < "$aur") AUR packages"
    else
      say "installing AUR packages with $helper"
      run "$helper" -S --needed --noconfirm - < "$aur" || warn "some AUR packages failed"
    fi
  fi
}

# =========================================================== the install ====
say "unit-os -> $HOME   (mode: $MODE)"
[[ $DRY == 1 ]] && say "dry run -- nothing will be written"

[[ $PACKAGES == 1 ]] && install_packages

# --- config/ : one link (or copy) per app ---------------------------------
say "config"
for src in "$REPO"/config/*; do
  name="$(basename "$src")"
  # btop.conf carries an absolute theme path and cannot expand $HOME
  [[ $name == btop ]] && continue
  install_path "config/$name" "$HOME/.config/$name"
done

# btop: everything but the templated btop.conf
install_path      "config/btop/themes" "$HOME/.config/btop/themes"
install_templated "config/btop/btop.conf" "$HOME/.config/btop/btop.conf"

# --- bin/ : the commands (theme, shot, agent, bootstrap-desktop, ...) ------
say "bin"
for src in "$REPO"/bin/*; do
  install_path "bin/$(basename "$src")" "$HOME/.local/bin/$(basename "$src")"
  [[ $DRY == 1 ]] || chmod +x "$HOME/.local/bin/$(basename "$src")"
done

# --- default/ : shell, desktop entries, user services ---------------------
say "shell and desktop entries"
install_path "default/bashrc" "$HOME/.bashrc"

for src in "$REPO"/default/applications/*.desktop; do
  install_templated "default/applications/$(basename "$src")" \
                    "$HOME/.local/share/applications/$(basename "$src")"
done

for src in "$REPO"/default/systemd/user/*; do
  install_templated "default/systemd/user/$(basename "$src")" \
                    "$HOME/.config/systemd/user/$(basename "$src")"
done

# --- docs/ : readable from ~/Documents, which the keybinds point at -------
say "docs"
run mkdir -p "$HOME/Documents"
for src in "$REPO"/docs/*; do
  install_path "docs/$(basename "$src")" "$HOME/Documents/$(basename "$src")"
done

# --- runtime state dirs the theme switcher expects -------------------------
run mkdir -p "$HOME/.config/themes" "$HOME/.config/ai-usage" "$HOME/Pictures/Screenshots"

if [[ ! -f $HOME/.config/ai-usage/env && $DRY == 0 ]]; then
  cat > "$HOME/.config/ai-usage/env" <<'TEMPLATE'
# Optional. Keys for the waybar AI pill; every line may stay commented out.
# This file is gitignored and must never be committed.
# ANTHROPIC_API_KEY=
# OPENAI_API_KEY=
# REPLICATE_API_TOKEN=
TEMPLATE
  chmod 600 "$HOME/.config/ai-usage/env"
fi

# --- services -------------------------------------------------------------
# dots-autosave.timer is deliberately NOT enabled. Saving is manual: see
# docs/system-guide.md section 2. The unit exists so it can be started by hand.
if command -v systemctl >/dev/null && [[ $DRY == 0 ]]; then
  systemctl --user daemon-reload 2>/dev/null || true
fi

# --- generate the theme-derived files -------------------------------------
if [[ $DRY == 0 ]] && command -v python3 >/dev/null; then
  say "generating theme files"
  "$HOME/.local/bin/theme" "$(cat "$HOME/.config/themes/current" 2>/dev/null || echo terminal)" \
    >/dev/null 2>&1 || warn "theme generation failed -- run 'theme terminal' by hand"
fi

say "done."
if [[ -d ${BACKUP:-} ]]; then
  say "replaced files were backed up to $BACKUP"
fi
if [[ $MODE == link ]]; then
  say "linked: edits under ~/.config now land directly in $REPO"
else
  cat <<EOF

  Next:
    - log out and back in (the session starts from ~/.bash_profile via uwsm)
    - gh auth login
    - theme terminal   /   theme studio
EOF
fi
