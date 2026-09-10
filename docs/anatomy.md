# januario's Arch + Hyprland desktop

A reproducible desktop, the way Omarchy is one, but built by hand and kept
in a bare git repo instead of an installer. This file is the guide: what the
machine is, how to rebuild it from a blank disk, what every file does, and
how to live with it day to day.

Everything under "Rebuild" is copy-paste. Everything else is reading.

---

## 1. What you are looking at

| Piece | Choice | Why |
|---|---|---|
| Distro | Arch, rolling | one package manager, current Hyprland |
| Compositor | Hyprland 0.56, **Lua config** | 0.55+ dropped hyprlang; guides online will not paste |
| Bar | waybar, floating glass pills | 16px margins match Hyprland `gaps_out` |
| Launcher | rofi | drun, run, window modes |
| Terminal | kitty | ghostty on SUPER+SHIFT+Q for comparison |
| Notifications | dunst | themed by `theme` |
| Lock / idle | hyprlock, hypridle | dim 5m, lock 10m, screen off 15m, no suspend yet |
| Wallpaper | hyprpaper 0.8 + `gen-wallpaper` | generated from the palette, no stock art |
| Editor | Neovim 0.12, `vim.pack`, no distro | ~150-line init.lua |
| Shell | bash + starship + fzf + zoxide | every tool guarded, missing one never breaks the shell |
| Theme | `theme terminal` or `theme studio`, both dark | one palette renders 9 config files |
| Fonts | JetBrainsMono Nerd Font, Noto | icons in the bar need the Nerd variant |
| Icons | Papirus-Dark | |

Hardware this was built on: ASUS laptop, Ryzen 7 7730U, eDP-1 2880x1620 @
120Hz at scale 2 (logical 1440x810), 16 GB RAM, BAT0, NVMe.

Disk layout, dual boot with Windows:

```
nvme0n1p1  vfat   /boot        (shared EFI, Windows made it)
nvme0n1p3  ntfs   /mnt         (Windows C:, read-only-ish, for grabbing files)
nvme0n1p6  btrfs  subvols  @ -> /   @home -> /home   @pkg -> /var/cache/pacman/pkg   @log -> /var/log
           mount opts: compress=zstd:3, ssd, discard=async
zram0      4 GB swap (zram-generator), priority 100
```

Login: there is **no display manager**. Log in on tty1 and type `Hyprland`.

---

## 2. Rebuild from a blank disk

### 2.1 Base Arch

`archinstall` is fine. Pick: btrfs with the subvolume layout above,
`linux` + `linux-firmware` + `amd-ucode`, NetworkManager, no desktop profile
(Hyprland comes from the package list), user `januario` with sudo.
Boot, log in on tty1, get online:

```bash
nmtui                       # wifi
sudo pacman -S git base-devel
```

### 2.2 Pull the dotfiles

The configs live in a **bare repo** whose work tree is `$HOME`. That is why
there is no `~/dotfiles` folder full of symlinks: the files are simply where
the programs expect them, and git tracks only the ones that were added.

```bash
git clone --bare git@github.com:januarionclx/unit-linux.git ~/.dotfiles
git --git-dir=$HOME/.dotfiles --work-tree=$HOME checkout
```

If checkout complains about existing files (a stock `.bashrc`), move them
aside and run it again.

> As of 2026-09-10 the repo has **no remote yet**. Push it once:
> `dots remote add origin git@github.com:januarionclx/unit-linux.git && dots push -u origin master` (create the private repo `unit-linux` on GitHub first)

### 2.3 Install everything

```bash
bash ~/.local/bin/bootstrap-desktop
```

What it does, in order:

1. `pacman -S --needed` every package in `pkglist-native.txt` (this folder).
2. Builds `yay` from the AUR if missing, then installs `pkglist-aur.txt`
   (brave, nordvpn, wlogout). Use yay, not paru: paru-bin is built against
   an older `libalpm` than pacman 7.1 ships and dies on start.
3. Enables power-profiles-daemon, bluetooth, and the user pipewire units.
4. Creates the XDG dirs, refreshes the desktop database, and runs `theme`
   with whatever `~/.config/themes/current` says, which **generates** the
   colour files that are deliberately not in git.
5. Starts Neovim headless once so `vim.pack` fetches the plugins.
6. Clones a monochrome wallpaper set into `~/Pictures/wallpapers/mono`.

### 2.4 Root-only hardening (the kill switches)

Three layers so a runaway process never takes the desktop with it.
Strongest first; each works without the others. Safe to run twice.

**a) systemd-oomd**: kills the worst cgroup in your session once memory
pressure stays above 60%, *before* the machine starts swap-thrashing.
This is the layer that makes the other two rarely needed.

```bash
sudo systemctl enable --now systemd-oomd.service
sudo mkdir -p /etc/systemd/system/user@.service.d
printf '%s\n' '[Service]' 'ManagedOOMMemoryPressure=kill' 'ManagedOOMMemoryPressureLimit=60%' \
  | sudo tee /etc/systemd/system/user@.service.d/10-oomd.conf
sudo systemctl daemon-reload
```

**b) Magic SysRq**: ALT + PrtSc + F makes the *kernel* OOM-kill the biggest
memory user, even when Hyprland itself is frozen. Stock Arch sets
`kernel.sysrq = 16` (sync only), so the F key does nothing until this.
`244 = keyboard(4) + sync(16) + remount-ro(32) + signal/oom(64) + reboot(128)`.

```bash
printf '%s\n' 'kernel.sysrq = 244' | sudo tee /etc/sysctl.d/99-sysrq.conf
sudo sysctl -p /etc/sysctl.d/99-sysrq.conf
```

**c) Negative nice for the task manager**: CTRL+SHIFT+ESC launches
`nice -n -10 btop` so it outranks a CPU hog. Users cannot go below nice 0
until PAM allows it, and PAM reads this at login, so **log out once** after.
Until then the bind still works, just at nice 0.

```bash
sudo install -d /etc/security/limits.d
printf '%s\n' 'januario  -  nice  -10' | sudo tee /etc/security/limits.d/10-taskmgr-nice.conf
```

(`~/setup-finish.sh` is a) to c) plus the original package step as one
script, for when you would rather not paste.)

### 2.5 First login

```bash
Hyprland                    # from tty1
```

Then, inside the desktop: `gh auth login`, `opencode auth login`, and
`theme studio` or `theme terminal` to taste. Check the bar shows a save pill on
the right; if it says "no repo" the bare clone did not land.

### 2.6 Verify

```bash
hyprctl configerrors                     # empty = good
cat /proc/sys/kernel/sysrq               # 244
systemctl is-active systemd-oomd         # active
ulimit -e                                # 30 after re-login (0 = nice limit not active yet)
for b in kitty rofi waybar dunst hyprpaper hypridle hyprlock btop tmux nvim starship fzf zoxide; do
  command -v $b >/dev/null && echo "ok   $b" || echo "MISS $b"; done
```

---

## 3. Anatomy: what every file does

### Hyprland `~/.config/hypr/`

`hyprland.lua` is 7 `require`s, in an order that matters (env before
autostart so launched apps inherit the variables):

| File | Holds |
|---|---|
| `env.lua` | cursor size, Wayland hints for Electron and Qt. **No `GDK_SCALE`**: at scale 2 it double-scales GTK apps. |
| `monitors.lua` | eDP-1 pinned to `2880x1620@120` scale 2 ("preferred" negotiates down to 60Hz); catch-all for docks. |
| `looks.lua` | gaps 8/16, border 3, rounding 12, blur, shadow, animations. Colours come from `colors.lua`. |
| `colors.lua` | **generated by `theme`**, not in git. Border and shadow colours. |
| `input.lua` | US layout, touchpad natural scroll + tap, 3-finger swipe = workspace. |
| `rules.lua` | float small utilities and dialogs, blur waybar/rofi/dunst layers, float+centre the btop task manager. |
| `binds.lua` | every key. SUPER = Windows key. Full list in `~/Documents/cheatsheets.html` (SUPER+/). |
| `autostart.lua` | waybar, hyprpaper, dunst, hypridle, blueman-applet, two cliphist watchers. |
| `hyprpaper.conf` | 0.8 syntax: a `wallpaper { }` block, absolute paths, fails silently otherwise. |
| `hypridle.conf` | dim 5m, lock 10m, dpms off 15m. No suspend until resume is tested. |
| `hyprlock.conf` | lock screen, themed colours, JetBrainsMono. |
| `hyprland.lua.bak` | the untouched stock config, for reference. |

After any edit: `hyprctl reload && hyprctl configerrors`. Dispatchers can be
probed live with `hyprctl dispatch '<lua expr>'`.

### Bar `~/.config/waybar/`

`config.jsonc` (modules and click actions), `style.css` (the glass pills),
`colors.css` (generated). Scripts:

| Script | Does |
|---|---|
| `clock-tz.sh` | clock that names its zone; right-click toggles Lisbon / Caracas |
| `ai-usage.py` | Claude Max, OpenAI, Replicate, opencode allowance in one pill; keys in `~/.config/ai-usage/env` |
| `ai-notify.sh` | the same as a toggleable notification (SUPER+A, SUPER+=) |
| `dots-status.sh` | the save pill: time since last dotfiles commit, warning when dirty, critical after 7 days; click = `dots-save` |
| `dots-remind.sh` | Claude Code Stop hook that nags when configs are unsaved |

### Theme system

`~/.local/bin/theme` is one Python file with a `FAMILIES` dict. `theme
<name>` renders that palette into nine files and reloads the apps:

```
waybar/colors.css   kitty/colors.conf   alacritty/colors.toml   rofi/theme.rasi
dunst/dunstrc       hypr/colors.lua     starship.toml           gtk-3.0/gtk.css + gtk-4.0/gtk.css
nvim/lua/theme.lua
```

The generated files are not tracked; `~/.config/themes/current` (one word)
is. Adding a theme = adding one dict entry. `gen-wallpaper` draws a plain
dark wallpaper from the active palette into `~/Pictures/wallpapers/generated/`.

Two themes, both dark, no light side: `terminal` (personal-os -- true
black under off-white, square corners, Neovim `quiet`) and `studio`
(artist-os -- warm greys under parchment, soft corners, Neovim
gruvbox-material). `studio` sits several steps up from `terminal` and covers
what a light theme would have, which is why there is no light side to
either. The old names `mono`, `mecha` and `brown` still resolve.

### Everything else

| Path | What |
|---|---|
| `~/.bashrc` | PATH, nvim as editor and manpager, starship, zoxide, fzf keys, `dots` and `dots-save` aliases |
| `~/.config/tmux/tmux.conf` | prefix Ctrl-a, `|` and `-` splits keeping cwd, truecolor fix for kitty |
| `~/.config/nvim/init.lua` | Part A options and keys, Part B oil/snacks/neogit via `vim.pack`, Part C LSP |
| `~/.config/kitty/kitty.conf` | JetBrainsMono 11, padding 14, copy-on-select, Ctrl+V pastes, Shift+Enter = newline |
| `~/.config/rofi/config.rasi` | modes and font; `theme.rasi` is generated |
| `~/.config/btop/` | vim keys, mecha-no-onna theme |
| `~/.config/gtk-3.0/settings.ini` | Adwaita-dark, Papirus-Dark, Cantarell 11 |
| `~/.local/share/applications/*.desktop` | WhatsApp, YouTube and the cheatsheet as launcher entries |
| `~/Documents/*-cheatsheet.md`, `cheatsheets.html` | keys for Hyprland, the terminal and Neovim |
| `~/.claude/` | settings (with the dots-remind hook), the `efficient-fable` skill, executor and scout agents |
| `pkglist-native.txt`, `pkglist-aur.txt` | this folder; what bootstrap installs |

---

## 4. Living with it

**Save configs.** The bar pill turns yellow when tracked files changed.
Click it, or:

```bash
dots-save                   # add -u, commit "save <date>", push
dots status                 # what changed
dots add ~/.config/foo/bar  # start tracking a new file
```

**Change theme.** `theme` lists them, `theme terminal` (or `studio`) switches everything and
reloads waybar, kitty, dunst, Hyprland. Then `gen-wallpaper` if you want the
wallpaper to follow.

**Add a package.** Install it, then refresh the lists so bootstrap knows:

```bash
pacman -Qqen > ~/.config/unit/pkglist-native.txt
pacman -Qqem > ~/.config/unit/pkglist-aur.txt
```

**Something is stuck.** In order of how frozen the machine is:

1. CTRL+SHIFT+ESC, btop floats on top: `k` kill, `t` terminate, `f` filter, `m`/`c` sort.
2. SUPER+Q terminal, `pkill -f name`.
3. ALT + PrtSc + F, kernel OOM-kills the biggest process, desktop may be frozen.
4. ALT + PrtSc + R, E, I, S, U, B in that order, the "reisub" clean reboot.

**Edit Hyprland.** Change a file, `hyprctl reload`, `hyprctl configerrors`.
Binds and rules apply live. Monitors and env need a re-login.

---

## 5. Gotchas that cost time

- **Hyprland 0.55+ is Lua.** Any `hyprland.conf` snippet online is hyprlang and will not paste. Translate; `hl.config({...})`, `hl.bind(...)`, `hl.window_rule({...})`.
- **Window rule `size` wants integers**: `{ 1008, 607 }`. Percent strings are silently ignored, `{w=,h=}` errors.
- **hyprpaper 0.8** dropped `preload` and `wallpaper = monitor,path`. Wrong syntax fails silently with "Monitor eDP-1 has no target".
- **`misc.vfr`** is not a valid 0.56 key.
- **Never set `GDK_SCALE=2`** on this panel; GTK apps double-scale.
- **Alacritty** only watches a config that existed when it launched.
- **paru** is broken against pacman 7.1; use yay.
- **Negative nice** needs the limits.d file *and* a fresh login. `nice` still runs the command at 0 with a warning, so binds never fail.
- **Brave** needs `ELECTRON_OZONE_PLATFORM_HINT=wayland` or it renders blurry through XWayland.
- **The bar clock** cannot print a city name natively; that is why it is a script.

---

## 6. Not done yet

- Push `~/.dotfiles` to a remote (section 2.2).
- Test `systemctl suspend` and the lid, then add a suspend listener to `hypridle.conf`.
- Drop `alacritty` and `hyprlauncher` once kitty and rofi are trusted: `sudo pacman -Rns alacritty hyprlauncher`. Decide whether ghostty stays.
- `~/Documents/hyprland-cheatsheet.md` still says SUPER+C closes a window; it is SUPER+W now (SUPER+C opens Claude). `cheatsheets.html` is current.
