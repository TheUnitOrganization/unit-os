# This machine — what was built, where it lives, how to rebuild it

Arch Linux + Hyprland on a Ryzen 7 7730U laptop (2880×1620 @120 Hz, scale 2).
Built 9–10 Sep 2026 with Claude Code. Read this first when you come back.

## 1. What you have now

| Thing | What it does | Where |
|---|---|---|
| Hyprland | window manager; Lua config split into files | `~/.config/hypr/*.lua` |
| Waybar | floating glass bar, five capsules: workspaces · window · time (clock │ layout) · work (AI │ save) · tray · link (wifi │ volume │ bt) · system (cpu │ ram │ battery │ power mode) | `~/.config/waybar/` |
| rofi | launcher — `SUPER+R` or `SUPER+CTRL+SPACE` | `~/.config/rofi/` |
| kitty | terminal — `SUPER+Q`; Ctrl+V pastes text, or hands the key to the program when the clipboard holds only an image (so a `SUPER+SHIFT+S` snip pastes into Claude Code); Shift+Enter = newline | `~/.config/kitty/kitty.conf`, `smart_paste.py` |
| Neovim 0.12 | ~150-line config, 5 plugins, gruvbox-material or `quiet` | `~/.config/nvim/init.lua` |
| tmux | prefix Ctrl+a; `prefix D` = agent left / editor right | `~/.config/tmux/tmux.conf` |
| `theme` | one command re-skins everything: `theme terminal` / `theme brown`, each with a `light` side; `theme toggle` flips | `~/.local/bin/theme` |
| Wallpapers | one image, every theme and side: the ANIMA quadruped on a white studio ground, pinned by the single absolute path in `~/.config/themes/wallpaper`. Remove that file and hyprpaper rotates the family's folder every 5 min instead — but that folder now holds only this one image | `~/Pictures/unit-os-theme/anima-wheel.png` |
| AI pill `✦ 70%` | Claude Max allowance actually in use; `SUPER+A` (or click) toggles the breakdown popup — no hover tooltip, it duplicated the popup. The popup has a block per provider (Claude · OpenCode · Replicate · OpenAI), each with its reset times and the date you last used it, so a provider you pay for but never touch still says so. Keys go in `~/.config/ai-usage/env` (commented template inside); nothing there is required | `~/.config/waybar/scripts/ai-usage.py` |
| Time capsule `01:54 Lisbon │ US` | one pill, two halves: right-click the left half (or `SUPER+Z`) flips Lisbon⇄Caracas; click the right half (or `SUPER+SHIFT+SPACE`) cycles us→pt→latam | `scripts/clock-tz.sh`, `scripts/language.sh`, layouts in `~/.config/hypr/input.lua` |
| Save pill | time since configs were last saved. Click to save now — the hourly timer is currently disabled, see §2. | `~/.local/bin/dots-autosave`, `~/.config/systemd/user/dots-autosave.timer` |
| Dotfiles | git backup of every config above | `~/.dotfiles` (bare repo) — `dots status`, `dots-save` |
| Bootstrap | rebuild all of this on a fresh Arch install | `~/.local/bin/bootstrap-desktop` |
| Drawing | the paint app — blank canvas, crop, shapes, text. Chosen over KolourPaint: GTK3, so it added no new dependencies (KolourPaint drags in the KF6 stack) | `pacman -S drawing` |
| `shot` | every screenshot key runs this. `PRINT` keeps a PNG in `~/Pictures/Screenshots`; region snips go to the clipboard only, so the folder doesn't fill with throwaways. Every mode notifies, so a cancelled drag says so instead of failing silently | `~/.local/bin/shot` |
| swappy | the annotator `shot edit` opens (arrows, boxes, text) | `~/.config/swappy/config` |
| Cheat sheet | every key binding, filterable | `~/Documents/cheatsheets.html` — `SUPER+/` |
| `efficient-fable` | Claude Code skill: Fable plans, Sonnet/Haiku execute | `~/.claude/skills/efficient-fable/`, `~/.claude/agents/` |
| personal-os | your repo, cloned | `~/Projects/personal-os` |

Keys you'll want first: `SUPER+Q` terminal · `SUPER+R` launcher · `SUPER+W` close ·
`SUPER+E` files · `SUPER+B` Brave · `SUPER+C` Claude · `SUPER+1..0` workspaces ·
`SUPER+S` scratchpad · `PRINT` whole screen to clipboard ·
`SUPER+SHIFT+S` region snip · `SUPER+/` cheat sheet ·
`SUPER+Z` clock timezone · `SUPER+SHIFT+SPACE` keyboard layout.

### Window and screenshot keys (changed 10 Sep 2026)

| Key | Does | Note |
|---|---|---|
| `SUPER+SHIFT+HJKL` | move window in the tiling tree | can push it to another monitor |
| `SUPER+CTRL+arrows` | **swap** window with its neighbour | trades places, rest of the layout stays put |
| `PRINT` | whole screen → **file + clipboard** | the deliberate "keep this" · `shot full` |
| `SUPER+SHIFT+S` | drag a region → **clipboard only** | the Snipping Tool chord · `shot region` |
| `SHIFT+PRINT` | drag a region, then annotate in swappy | `Ctrl+S` there is the only thing that writes a file · `shot edit` |

Only `PRINT` leaves a file behind. Region snips are throwaways — they'd fill
`~/Pictures/Screenshots` with noise — so they stop at the clipboard, which
means the shot dies on your next copy. Need to keep a region? Use `SHIFT+PRINT`
and press `Ctrl+S`. A cancelled drag (tap Print without dragging) raises a
"cancelled" notification rather than silently doing nothing.
| `SUPER+ALT+S` | send window to scratchpad | moved off `SUPER+SHIFT+S`, which is the snip key now |

`SUPER+PRINT` is now unbound and free. `SUPER+/` reads the binds live from
`binds.lua`, so the cheat sheet never goes stale — only this table can.

## 2. Daily habits (the only two that matter)

- **Saving is manual right now.** Checked 10 Sep 2026: `dots-autosave.timer`
  is installed but *disabled*, and there is no Claude Code Stop hook in
  `~/.claude/settings.json` — so the configs are saved only when you click the
  save pill or run `dots-save`. **This is deliberate, leave it that way.** The
  point is to see what enters the config history rather than have a timer (or
  an agent) sweep changes in behind you — which matters when several Claude
  sessions edit the same files at once. The `dots-autosave.timer` unit exists
  and stays `disabled`; don't enable it, and don't add a Claude Code Stop hook
  that saves. A *new* file is always a deliberate `dots add <path>` —
  `dots-save` only runs `add -u`, so nothing is swept in by accident.
  The repo also has no remote yet — the backup is on this disk only.
- **Want a different look?** Two families, each with a dark and a light
  side (changed 10 Sep 2026): `theme terminal` is personal-os's *terminal*
  theme (near-black, off-white, square) and `theme terminal light` its
  *paper* twin; `theme brown` is artist-os's default (warm greys under
  parchment text) and `theme brown light` the parchment-and-white-cards
  original. `theme light` / `theme dark` / `theme toggle` flip the side of
  whatever family is on. Dark is the default side. `mono` and `mecha` still
  work as names for `terminal` and `brown`. **Shape is per family**
  (changed 10 Sep 2026 evening): `radius` in `FAMILIES` is 0 for
  `terminal` (square windows, bar pills, launcher, notifications, GTK
  menus, kitty tabs) and 12 for `brown` (soft). `theme` writes it to
  `hypr/colors.lua` (`rounding`), `waybar/shape.css`, rofi, dunst, GTK
  and hyprlock. `terminal light` is a few steps below white on purpose.
  Add a family by adding one
  entry to `FAMILIES` in `~/.local/bin/theme` with a `dark` and a `light`
  dict. A light side also wants `gtk_theme: Adwaita`, `prefer_dark: 0`,
  `color_scheme: prefer-light`, `sel_bg`/`sel_fg`, `shadow`, `border2`
  (solid ink border), `border_inactive` and `nvim_bg: light` — all
  optional, and all defaulted for dark.
- **Folder icons** are a thin theme in `$HOME`, not `papirus-folders` (which
  needs root and is undone by every papirus update). `papirus-variant
  Papirus-Bun Papirus pink` builds one; `theme` rebuilds a missing one on
  switch. `mono-folders` is the old name, now a wrapper.
- **Folder colours (changed 10 Sep 2026).** Plain folders take the palette's
  own hue from `icons_src` — mono is `teal`, so nothing in Thunar reads grey.
  On top of that, `FOLDER_HUES` in `~/.local/bin/theme` gives the XDG dirs
  their own colour: Documents blue, Downloads green, Music violet, Pictures
  yellow, Videos red. Pass them to `papirus-variant` as `category=colour`
  pairs. Only XDG dirs can be coloured individually — Thunar 4.20 ignores
  both `metadata::custom-icon` and `metadata::custom-icon-name`, so an
  ordinary folder like `~/Projects` cannot be singled out; it takes the base
  hue like everything else. The build stamps its inputs into
  `<theme>/.recipe`, and `theme` rebuilds whenever that goes stale — so
  editing `FOLDER_HUES` is enough, no manual rebuild.

### How the desktop starts

There is no display manager. You log in on tty1 and `~/.bash_profile` starts
the session:

```bash
if command -v uwsm >/dev/null && uwsm check may-start; then
    exec uwsm start hyprland.desktop
fi
```

`uwsm` (Universal Wayland Session Manager) runs Hyprland as a **systemd user
session** rather than as a bare process. That is what makes `systemctl --user`
behave: environment variables actually reach user services, and waybar,
hypridle and hyprpaper get ordered start-up and clean shutdown. The older
one-liner — `[[ -z $DISPLAY && $(tty) == /dev/tty1 ]] && exec Hyprland` — works
too, and is what most tutorials still show; Omarchy shipped it for a year and
then migrated to uwsm, which is the pattern the Hyprland wiki documents now.

`uwsm check may-start` is doing the guarding: interactive login, tty1 only, no
session already running. tty2–6 stay plain shells on purpose.

**If the desktop ever fails to start, tty1 becomes a login loop** — because of
`exec`, a compositor that dies takes the login with it. `Ctrl+Alt+F2` gets you
a real shell to fix the config from. This is the one failure mode worth
memorising.

Omarchy also does getty autologin and a splash-flicker helper. Neither is here:
autologin trades your disk password prompt for convenience, and there is no
plymouth splash to flicker.

## 3. Rebuilding from nothing

1. Install Arch (archinstall is fine), boot, log in, connect wifi.
2. `sudo pacman -S git base-devel`
3. `git clone --bare git@github.com:januarionclx/unit-linux.git ~/.dotfiles`
   — needs the GitHub repo to exist first (see §5).
4. `git --git-dir=$HOME/.dotfiles --work-tree=$HOME checkout`
5. `bash ~/.local/bin/bootstrap-desktop` — installs every package from the
   saved manifests, enables services, fetches wallpapers, regenerates theme files.
6. Log out and in. Then `gh auth login`, `opencode auth login`.

Until step 3's repo exists, the backup lives only on this disk. Copy `~/.dotfiles`
to a USB stick if you want a stopgap: `cp -r ~/.dotfiles /run/media/…/`.

## 4. Things worth knowing (cost time to learn)

- Hyprland ≥0.55 uses **Lua** config. Most ricing videos and Omarchy themes
  ship the old hyprlang format — their waybar/rofi/kitty parts copy over, their
  `hyprland.conf` does not. `hyprctl configerrors` after every edit.
- `hyprctl dispatch '<lua>'` runs a binding's action live — the safe way to
  test a dispatcher name (e.g. `hl.dsp.window.fullscreen()`).
- hyprpaper 0.8 uses a `wallpaper { … }` block; the old `preload`/`wallpaper=`
  lines fail *silently*.
- A terminal only re-reads a config file that existed when it launched.
  "My new keybind doesn't work" → open a new window.
- Claude Code `!` commands can't `sudo` (no TTY). Run installs in a real terminal.
- `paru` is broken (built against an old libalpm). Use `yay`.
- The session is started by `~/.bash_profile` via `uwsm`, not by a display
  manager. A change there is only truly tested by a reboot, and a bad one
  makes tty1 a login loop — `Ctrl+Alt+F2` is always the way out.
- Notifications sit 16px under the bar and 16px from the right edge, the
  same `gaps_out` the windows use, so their top and right edges line up
  with the window below. dunst is a layer-shell surface, so its `offset`
  is measured from the bar's exclusive zone, not from the screen edge.
  Their rounded corners are really transparent: the notifications/rofi
  layer rule in `rules.lua` has `ignore_alpha`, without which Hyprland
  blurs the whole rectangle and a square shows behind the corners.
- `~/.config/dunst/dunstrc` is **generated by `theme`** — edit `render_dunst`
  in `~/.local/bin/theme`, not the file, or the next `theme terminal` eats it.
  The same goes for `~/.config/gtk-{3,4}.0/settings.ini` (`render_gtk_settings`)
  and `~/.config/hypr/hyprlock.conf` (`render_hyprlock`; the lock screen shows
  the pinned wallpaper, else ANIMA `4-wheel-leg` — `LOCK_IMAGE` in the script).
  `~/.config/waybar/shape.css` and `~/.config/kitty/colors.conf` are generated too.
- A light GTK palette needs `gtk-theme-name=Adwaita`, not just a light
  `gtk.css`: every widget the css does not name falls back to the base
  theme, so Adwaita-dark leaves black holes in Thunar.
- The scratchpad (`SUPER+S`) is a hidden workspace `-98`. A window you "lost"
  is usually there. Terminals are 75 % opaque, so you also see through them.

## 5. Not done yet

One list, kept current: **`~/Documents/TODO.md`**.

## 6. Where the other docs are

- Keys: `~/Documents/cheatsheets.html` (also https://claude.ai/code/artifact/e4a3a312-513c-46c1-91b4-7b04615f9a54)
- Markdown versions: `~/Documents/{hyprland,terminal,nvim}-cheatsheet.md`
- Neovim's own interactive tutorial: `nvim +Tutor`
- Session logs (written by Claude sessions): `~/Documents/sessions/index.html`
- The to-do list: `~/Documents/TODO.md` — `SUPER+SHIFT+D`
- This guide on the desktop: `SUPER+SHIFT+/`
- This file: `~/Documents/system-guide.md`
