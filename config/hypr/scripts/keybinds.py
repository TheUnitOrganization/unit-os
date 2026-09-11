#!/usr/bin/env python3
"""SUPER+/: every keybinding as a checklist you work through.

Read live from binds.lua, so the list can never go stale -- add a bind and it
shows up here unlearned. SPACE ticks the highlighted row; ticked rows sink to
the bottom and dim, so the top of the list is always "what I still cannot do
from memory", and the list shortens as you learn it.

Progress lives in ~/.config/unit/keys-learned.txt, which is inside the
dotfiles work tree, so it survives a rebuild along with everything else.

  keybinds.py           the Hyprland checklist (this is what SUPER+/ runs)
  keybinds.py herdr     the same checklist for herdr's keys (SUPER+CTRL+/)
  keybinds.py --list    plain "KEY    what it does" lines, no rofi

A ticked row sinks, so the next unlearned one slides into the spot you were
looking at -- which used to read as "space did nothing". The header now
names what was just ticked, and the boxes are Nerd Font glyphs the rofi font
actually has (the Unicode ballot boxes were borrowed from another face).
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


def hypr_rows():
    """Every hl.bind in binds.lua, live."""
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
    return rows


HERDR_CFG = pathlib.Path.home() / ".config/herdr/config.toml"


def herdr_rows():
    """herdr's [keys] table: the shipped defaults (commented out in
    `herdr --default-config`) with ~/.config/herdr/config.toml laid over them,
    plus any [[keys.command]] popups. `prefix` is spelled out as the real
    chord so the list reads as keys you press, not names."""
    def parse(text, commented):
        keys, cmds, section, cmd = {}, [], None, None
        for raw in text.splitlines():
            line = raw.strip()
            if commented and line.startswith("#"):
                line = line[1:].strip()
            if line.startswith("[[keys.command]]"):
                section, cmd = "cmd", {}
                cmds.append(cmd)
                continue
            if line.startswith("["):
                section = "keys" if line.startswith("[keys]") else None
                cmd = None
                continue
            m = re.match(r'([a-z_]+)\s*=\s*"([^"]*)"', line)
            if not m or section is None:
                continue
            name, val = m.groups()
            if section == "cmd" and cmd is not None:
                cmd[name] = val
            elif section == "keys" and name not in ("type", "command", "key", "width", "height"):
                keys[name] = val   # the prose above [[keys.command]] mentions these; not bindings
        # The default config's [[keys.command]] is a commented-out example
        # (lazygit), not a binding anyone has -- only the user's file counts.
        return keys, ([] if commented else cmds)

    try:
        default = subprocess.run(["herdr", "--default-config"], capture_output=True,
                                 text=True, timeout=5).stdout
    except (OSError, subprocess.TimeoutExpired):
        default = ""
    keys, cmds = parse(default, commented=True)
    if HERDR_CFG.exists():
        ukeys, ucmds = parse(HERDR_CFG.read_text(), commented=False)
        keys.update(ukeys)
        cmds += ucmds

    prefix = keys.pop("prefix", "ctrl+b")

    def chord(binding):
        b = binding.replace("prefix+", prefix + " ")
        b = b.replace("+", " + ").replace("1..9", "1 … 9")
        return " ".join(part.upper() if len(part) <= 5 else part.capitalize()
                        for part in b.split())

    rows = []
    for name, binding in keys.items():
        if not binding:
            continue
        rows.append((chord(binding), name.replace("_", " ")))
    for c in cmds:
        if c.get("key"):
            what = pathlib.Path(c.get("command", "")).name or c.get("type", "command")
            rows.append((chord(c["key"]), f"{what} ({c.get('type', 'shell')})"))
    return rows


# --------------------------------------------------------------------------
# Checklist
# --------------------------------------------------------------------------
# A row is identified by its key chord alone, not by chord+description. The
# descriptions above are derived from the command, so improving a hint would
# otherwise silently un-tick a key you had already learned.
STATE_DIR = pathlib.Path.home() / ".config/unit"
BOX, BOX_DONE = "\U000f0131", "\U000f0132"   # nf-md-checkbox_blank_outline / _marked

# rofi exit codes: 0 accept, 1 cancel, 10.. = -kb-custom-1 onwards.
ACCEPT, CUSTOM_TOGGLE, CUSTOM_RESET = 0, 10, 11


def load(state):
    if not state.exists():
        return set()
    return {ln.strip() for ln in state.read_text().splitlines()
            if ln.strip() and not ln.startswith("#")}


def save(state, learned):
    state.parent.mkdir(parents=True, exist_ok=True)
    state.write_text(
        "# Keys marked learned in the checklist.\n"
        "# One key chord per line. Delete a line to put it back on the list;\n"
        "# delete the file to start over.\n"
        + "".join(f"{k}\n" for k in sorted(learned)))


def render(ordered, learned, width):
    """Pango markup rows. Learned ones dim rather than disappear -- the point
    is to watch the unlearned block shrink, which needs the rest still there."""
    out = []
    for k, d in ordered:
        done = k in learned
        line = html.escape(f"{BOX_DONE if done else BOX}  {k:<{width}}{d}")
        out.append(f"<span alpha='40%'>{line}</span>" if done else line)
    return out


def checklist(rows, state, prompt):
    width = max(len(k) for k, _ in rows) + 3
    learned = load(state)
    last = None   # the key just ticked, named in the header so a sinking row
                  # cannot read as "nothing happened"
    # Only keys that still exist in binds.lua count; a bind you deleted should
    # not keep inflating the "learned" score.
    live = {k for k, _ in rows}
    learned &= live

    filt, row = "", 0
    while True:
        todo = [r for r in rows if r[0] not in learned]
        done = [r for r in rows if r[0] in learned]
        ordered = todo + done
        if last is None:
            head = f"<b>{len(todo)}</b> of {len(rows)} still to learn"
        elif last in learned:
            head = f"<b>{BOX_DONE} {html.escape(last)}</b> learned  ·  {len(todo)} left"
        else:
            head = f"<b>{BOX} {html.escape(last)}</b> back on the list  ·  {len(todo)} left"
        mesg = head + "   ·   <b>space</b> tick   ·   <b>alt+r</b> reset   ·   <b>esc</b> close"
        proc = subprocess.run(
            ["rofi", "-dmenu", "-i", "-sync", "-no-custom", "-markup-rows",
             # space is the tick key, so it can no longer be typed into the
             # filter; fuzzy matching is what makes that survivable ("mvwin"
             # still finds "move window").
             "-matching", "fuzzy",
             "-p", prompt, "-mesg", mesg,
             "-format", "i|f",
             "-kb-custom-1", "space",
             "-kb-custom-2", "alt+r",
             "-filter", filt, "-selected-row", str(row)],
            input="\n".join(render(ordered, learned, width)),
            capture_output=True, text=True)

        if proc.returncode == CUSTOM_RESET:
            learned.clear()
            save(state, learned)
            filt, row, last = "", 0, None
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
        last = key
        # Written on every tick, not at the end: rofi is killed rather than
        # closed often enough (SUPER+/ again, a logout) that deferring the
        # write loses progress.
        save(state, learned)
        # Hold the cursor at the same row number. Ticking the top item makes
        # the next unlearned one slide up under it, so you can walk down the
        # list on space alone.
        row = i


SOURCES = {
    "hypr":  (hypr_rows,  STATE_DIR / "keys-learned.txt",       "keys"),
    "herdr": (herdr_rows, STATE_DIR / "herdr-keys-learned.txt", "herdr"),
}

if __name__ == "__main__":
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    build, state, prompt = SOURCES[args[0] if args else "hypr"]
    rows = build()
    if "--list" in sys.argv:
        width = max(len(k) for k, _ in rows) + 3
        for k, d in rows:
            print(f"{k:<{width}}{d}")
    else:
        checklist(rows, state, prompt)
