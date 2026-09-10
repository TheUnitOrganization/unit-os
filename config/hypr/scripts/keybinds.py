#!/usr/bin/env python3
"""SUPER+/: every keybinding as a checklist you work through.

Read live from binds.lua, so the list can never go stale -- add a bind and it
shows up here unlearned. SPACE ticks the highlighted row; ticked rows sink to
the bottom and dim, so the top of the list is always "what I still cannot do
from memory", and the list shortens as you learn it.

Progress lives in ~/.config/unit/keys-learned.txt, which is inside the
dotfiles work tree, so it survives a rebuild along with everything else.

  keybinds.py           the checklist (this is what SUPER+/ runs)
  keybinds.py --list    plain "KEY    what it does" lines, no rofi
"""
import html
import re
import subprocess
import sys
import pathlib

SRC = pathlib.Path.home() / ".config/hypr/binds.lua"

APP_NAMES = {
    "kitty": "terminal", "thunar": "file manager",
    "brave": "browser", "hyprlock": "lock screen", "wlogout": "logout menu",
    "telegram-desktop": "Telegram",
}
CMD_HINTS = [  # substring -> description, first match wins
    ("rofi -show drun", "app launcher"),
    ("whatsapp", "WhatsApp"), ("youtube", "YouTube"),
    ("cheatsheets", "keys cheat sheet (page)"), ("system-guide", "system guide"),
    ("TODO.md", "to-do list"), ("-e claude", "Claude Code"),
    ("swappy", "screenshot region, annotate"),
    ("grim -g", "screenshot region to clipboard"),
    ("grim -", "screenshot screen to clipboard"),
    ("cliphist", "clipboard history"), ("ai-notify", "AI usage popup"),
    ("keybinds.py", "this list"),
    ("btop", "system monitor (btop)"), ("wall-next", "next wallpaper"),
    ("rofi -show drun", "app launcher"), ("hyprlauncher", "app launcher"),
    ("exec kitty", "terminal"),
    ("DEFAULT_AUDIO_SOURCE@ toggle", "mute microphone"), ("set-mute", "mute"),
    ("wpctl set-volume -l", "volume up"), ("wpctl set-volume", "volume down"),
    ("brightnessctl -e4 -n2 set 5%+", "brightness up"), ("brightnessctl", "brightness down"),
    ("playerctl next", "media next"), ("playerctl previous", "media previous"),
    ("play-pause", "media play / pause"),
]


def key_text(expr: str) -> str:
    k = expr.replace("mainMod ..", "SUPER").replace('"', "")
    k = re.sub(r"\s*\+\s*", " + ", k)
    k = re.sub(r"\s+", " ", k).strip()
    return k.replace("SUPER SUPER", "SUPER")


def describe(action: str) -> str:
    ex = re.search(r'exec_cmd\(\[\[(.*?)\]\]', action) or re.search(r'exec_cmd\("(.*?)"\)', action) \
         or re.search(r'exec_cmd\((\w+)(?:\s*\.\.\s*"(.*?)")?\)', action)
    if ex:
        g = ex.groups()
        cmd = LOCALS.get(g[0], g[0]) + (g[1] if len(g) > 1 and g[1] else "")
        u = re.search(r'--app=https?://([^/\s]+)', cmd)
        if u:
            host = u.group(1).replace("www.", "")
            return {"calendar.google.com": "Google Calendar", "web.whatsapp.com": "WhatsApp",
                    "youtube.com": "YouTube", "mail.google.com": "Gmail"}.get(host, host)
        f = re.search(r'file://\S*/([\w.-]+)\.html', cmd)
        if f:
            return {"cheatsheets": "keys cheat sheet (page)", "system-guide": "system guide",
                    "index": "session logs"}.get(f.group(1), f.group(1))
        if "snap-window.py" in cmd:
            return "snap window " + cmd.split()[-1]
        for needle, desc in CMD_HINTS:
            if needle in cmd:
                return desc
        return APP_NAMES.get(cmd.split()[0], cmd)
    d = re.search(r'direction = "(\w+)"', action)
    if "window.close" in action:      return "close window"
    if "float" in action:             return "toggle floating"
    if "maximized" in action:         return "maximize"
    if "fullscreen" in action:        return "fullscreen"
    if "pseudo" in action:            return "pseudo-tile"
    if "togglesplit" in action:       return "toggle split direction"
    if "toggle_special" in action:    return "toggle scratchpad"
    if "special:magic" in action:     return "move window to scratchpad"
    if "drag" in action:              return "drag window (mouse)"
    if "resize" in action:            return "resize window (mouse)"
    if "window.swap" in action and d: return f"swap window {d.group(1)}"
    if "window.move" in action and d: return f"move window {d.group(1)}"
    if "focus" in action and d:       return f"focus {d.group(1)}"
    if "window.move" in action:       return "move window to workspace N"
    if "workspace = i" in action:     return "go to workspace N"
    if "e+1" in action:               return "next workspace"
    if "e-1" in action:               return "previous workspace"
    if "exit" in action:              return "quit Hyprland"
    return action


LOCALS = {}
for line in SRC.read_text().splitlines():
    lm = re.match(r'\s*local\s+(\w+)\s*=\s*(?:\[\[(.*?)\]\]|"(.*?)")', line)
    if lm:
        LOCALS[lm.group(1)] = lm.group(2) or lm.group(3) or ""

rows, seen = [], set()
for line in SRC.read_text().splitlines():
    m = re.match(r'\s*hl\.bind\((.+?),\s*(hl\.dsp\..+)\)\s*(--.*)?$', line)
    if not m:
        continue
    key, action = key_text(m.group(1)), describe(m.group(2))
    if ".." in key or " key" in key:   # the 1..10 loop template lines
        continue
    if (key, action) not in seen:
        seen.add((key, action))
        rows.append((key, action))

# the workspace loop isn't a literal bind line; add it by hand
rows.append(("SUPER + 1 … 0", "go to workspace 1-10"))
rows.append(("SUPER + SHIFT + 1 … 0", "move window to workspace 1-10"))

# --------------------------------------------------------------------------
# Checklist
# --------------------------------------------------------------------------
# A row is identified by its key chord alone, not by chord+description. The
# descriptions above are derived from the command, so improving a hint would
# otherwise silently un-tick a key you had already learned.
STATE = pathlib.Path.home() / ".config/unit/keys-learned.txt"
WIDTH = max(len(k) for k, _ in rows) + 3

# rofi exit codes: 0 accept, 1 cancel, 10.. = -kb-custom-1 onwards.
ACCEPT, CUSTOM_TOGGLE, CUSTOM_RESET = 0, 10, 11


def load():
    if not STATE.exists():
        return set()
    return {ln.strip() for ln in STATE.read_text().splitlines()
            if ln.strip() and not ln.startswith("#")}


def save(learned):
    STATE.parent.mkdir(parents=True, exist_ok=True)
    STATE.write_text(
        "# Keys marked learned in the SUPER+/ checklist.\n"
        "# One key chord per line. Delete a line to put it back on the list;\n"
        "# delete the file to start over.\n"
        + "".join(f"{k}\n" for k in sorted(learned)))


def render(ordered, learned):
    """Pango markup rows. Learned ones dim rather than disappear -- the point
    is to watch the unlearned block shrink, which needs the rest still there."""
    out = []
    for k, d in ordered:
        done = k in learned
        line = html.escape(f"{'☑' if done else '☐'}  {k:<{WIDTH}}{d}")
        out.append(f"<span alpha='40%'>{line}</span>" if done else line)
    return out


def checklist():
    learned = load()
    # Only keys that still exist in binds.lua count; a bind you deleted should
    # not keep inflating the "learned" score.
    live = {k for k, _ in rows}
    learned &= live

    filt, row = "", 0
    while True:
        todo = [r for r in rows if r[0] not in learned]
        done = [r for r in rows if r[0] in learned]
        ordered = todo + done
        mesg = (f"<b>{len(todo)}</b> of {len(rows)} still to learn"
                "   ·   <b>space</b> tick   ·   <b>alt+r</b> reset   ·   <b>esc</b> close")
        proc = subprocess.run(
            ["rofi", "-dmenu", "-i", "-sync", "-no-custom", "-markup-rows",
             # space is the tick key, so it can no longer be typed into the
             # filter; fuzzy matching is what makes that survivable ("mvwin"
             # still finds "move window").
             "-matching", "fuzzy",
             "-p", "keys", "-mesg", mesg,
             "-format", "i|f",
             "-kb-custom-1", "space",
             "-kb-custom-2", "alt+r",
             "-filter", filt, "-selected-row", str(row)],
            input="\n".join(render(ordered, learned)),
            capture_output=True, text=True)

        if proc.returncode == CUSTOM_RESET:
            learned.clear()
            save(learned)
            filt, row = "", 0
            continue
        if proc.returncode not in (ACCEPT, CUSTOM_TOGGLE):
            break

        idx, _, filt = proc.stdout.strip().partition("|")
        if not idx.isdigit():
            break
        i = int(idx)
        if not 0 <= i < len(ordered):
            break

        key = ordered[i][0]
        learned.symmetric_difference_update({key})
        # Written on every tick, not at the end: rofi is killed rather than
        # closed often enough (SUPER+/ again, a logout) that deferring the
        # write loses progress.
        save(learned)
        # Hold the cursor at the same row number. Ticking the top item makes
        # the next unlearned one slide up under it, so you can walk down the
        # list on space alone.
        row = i


if __name__ == "__main__":
    if "--list" in sys.argv:
        for k, d in rows:
            print(f"{k:<{WIDTH}}{d}")
    else:
        checklist()
