<div align="center">

# unit-os

**An Arch Linux + Hyprland desktop that reinstalls itself.**

One repo, one command, one palette that skins everything.

</div>

---

```bash
git clone https://github.com/TheUnitOrganization/unit-os.git
cd unit-os
./install.sh
```

That is the whole install. On a fresh Arch box it pulls ~90 packages, places
every config, and generates the theme. Log out, log back in, and the desktop
is the one in the screenshots.

---

## What it is

| | |
|---|---|
| **Compositor** | Hyprland 0.56 — **Lua** config, split across 11 files |
| **Bar** | waybar — floating glass pills, 16px gaps that line up with the windows |
| **Terminal** | kitty |
| **Editor** | Neovim 0.12, `vim.pack`, 5 plugins, no distro framework |
| **Launcher** | rofi |
| **Theme** | `theme terminal` / `theme studio` — one palette renders 11 config files |

Two themes, both dark. `terminal` is true black under off-white with square
corners; `studio` is warm greys under parchment with soft ones. Shape travels
with the theme, so switching changes the corners of the bar, the launcher, the
notifications and the windows together.

**[docs/what-ships.md](docs/what-ships.md) is the manifest** — what is in here,
what is deliberately not, and which files are generated. Start there.

---

## The two install modes

```bash
./install.sh          # copy configs into ~/.config   (a fresh machine)
./install.sh --link   # symlink them back to the repo (the author's laptop)
```

Same files either way. Copy mode gives you your own copy to diverge from.
Link mode makes `~/.config/hypr` and `unit-os/config/hypr` **the same file**,
so an edit lands in the repo with no sync step and `git status` sees it
immediately.

Useful flags: `--dry-run` (print, touch nothing), `--no-packages`.

Whatever it replaces is moved to `~/.local/share/unit-os/backup-<timestamp>/`
first. It never overwrites blind.

---

## Staying honest

```bash
unit-doctor          # is this machine still what the manifest says?
unit-doctor --fix    # ...and what to run for each thing that isn't
```

`unit-doctor` is the executable half of the manifest. It checks packages
against the lists, that every config is actually linked, that no credential
has been committed, that Hyprland has no config errors, that the generated
theme files exist, and that the kill switches are armed.

It is how you get back to a clean base: run it, fix what it flags, and the
machine matches the document again.

---

## Layout

```
bin/        commands that land on your PATH  (theme, shot, unit-doctor, …)
config/     one directory per app, mirroring ~/.config
themes/     palettes, as data
default/    bashrc, .desktop entries, user services
docs/       the manual — start with what-ships.md
install.sh  copy or link, packages, theme generation
```

---

## Docs

| File | |
|---|---|
| [what-ships.md](docs/what-ships.md) | **the manifest** — the four layers, what is excluded and why |
| [system-guide.md](docs/system-guide.md) | how the machine was built, and the failure modes worth memorising |
| [anatomy.md](docs/anatomy.md) | every file, what it does, and the gotchas that cost time |
| [cheatsheets.html](docs/cheatsheets.html) | every keybinding — `SUPER+/` opens it |

---

## Notes for anyone else running this

- **Hyprland 0.55+ uses Lua.** Almost every rice guide online is still
  hyprlang; those `hyprland.conf` snippets will not paste into this config.
- **Use `yay`, not `paru`** — `paru-bin` is built against an older libalpm
  than pacman 7.1 ships and dies on start.
- **There is no display manager.** `~/.bash_profile` starts the session via
  `uwsm` on tty1. If the compositor dies, tty1 becomes a login loop —
  `Ctrl+Alt+F2` is the way out. Worth knowing before you reboot.
- Monitor setup in `config/hypr/monitors.lua` is pinned to a 2880×1620@120
  laptop panel at scale 2. Change it before first login on other hardware.

---

<div align="center">
<sub>Built for one laptop, kept honest by <code>unit-doctor</code>.</sub>
</div>
