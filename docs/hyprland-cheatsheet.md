# Hyprland cheatsheet

`SUPER` is the Windows key. Config lives in `~/.config/hypr/` (Lua, split
across `binds.lua`, `looks.lua`, etc). After editing: `hyprctl configerrors`.

## Launch things
| Key | Does |
|-----|------|
| `SUPER + Q` | terminal (kitty) |
| `SUPER + SHIFT + Q` | second terminal (ghostty) |
| `SUPER + R` | app launcher (rofi) |
| `SUPER + E` | file manager (thunar) |
| `SUPER + B` | browser (brave) |

## Windows
| Key | Does |
|-----|------|
| `SUPER + C` | close window |
| `SUPER + F` | fullscreen |
| `SUPER + SHIFT + F` | maximise (keeps the bar) |
| `SUPER + V` | toggle floating |
| `SUPER + T` | toggle split direction |
| `SUPER + P` | pseudo-tile |

## Move around  (same hjkl as tmux and nvim)
| Key | Does |
|-----|------|
| `SUPER + H J K L` | focus left / down / up / right |
| `SUPER + arrows` | same, if you prefer arrows |
| `SUPER + SHIFT + H J K L` | move the window itself |
| `SUPER + LMB drag` | drag a window |
| `SUPER + RMB drag` | resize a window |

## Workspaces
| Key | Does |
|-----|------|
| `SUPER + 1..0` | go to workspace 1-10 |
| `SUPER + SHIFT + 1..0` | send window to workspace |
| `SUPER + scroll` | next / previous workspace |
| `SUPER + S` | toggle the scratchpad ("magic") |
| `SUPER + SHIFT + S` | throw window into the scratchpad |

## Screen & session
| Key | Does |
|-----|------|
| `PRINT` | select a region, opens in swappy to annotate |
| `SHIFT + PRINT` | whole screen straight to clipboard |
| `SUPER + SHIFT + V` | clipboard history (cliphist via rofi) |
| `SUPER + ALT + L` | lock now (hyprlock) |
| `SUPER + SHIFT + E` / `SUPER + M` | logout menu (wlogout) |

Laptop keys (volume, mute, brightness, play/pause) work as printed.
Idle: dims at 5 min, locks at 10, screen off at 15. No auto-suspend.

## Useful commands
| Command | Does |
|---------|------|
| `hyprctl configerrors` | did my config edit break something? |
| `hyprctl monitors` | resolution / refresh / scale |
| `hyprctl clients` | every open window, with class + title |
| `hyprctl dispatch '<lua>'` | run a bind's action live, e.g. `hl.dsp.window.fullscreen()` |
| `hyprctl hyprpaper listactive` | current wallpaper |

Wallpapers rotate every 15 min from `~/Pictures/wallpapers/mecha-no-onna/`.
