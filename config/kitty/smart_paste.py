# Ctrl+V that does the right thing for whatever is on the clipboard.
#
# kitty.conf maps ctrl+v to this instead of paste_from_clipboard. Text
# pastes as before. When the clipboard holds only an image (a region
# screenshot from SUPER+SHIFT+S), kitty has nothing to paste and would
# swallow the key -- so the key itself is forwarded to the program in the
# window, letting Claude Code and friends read the image off the clipboard
# themselves (Claude Code's chat:imagePaste is bound to ctrl+v).
#
# No UI: handle_result runs inside the kitty process (no_ui = True).
import subprocess

TEXT_TYPES = ("text/plain", "UTF8_STRING", "TEXT", "STRING", "text/")


def main(args):
    pass


def handle_result(args, answer, target_window_id, boss):
    try:
        types = subprocess.run(["wl-paste", "--list-types"], capture_output=True,
                               text=True, timeout=1).stdout
    except Exception:
        types = "text/plain"
    w = boss.window_id_map.get(target_window_id)
    if w is None:
        return
    if any(t in types for t in TEXT_TYPES) or not types.strip():
        # What boss.paste_from_clipboard does, aimed at this window rather
        # than whichever one the boss considers active.
        if w.send_paste_event():
            return
        from kitty.boss import get_clipboard_string
        text = get_clipboard_string()
        if text:
            w.paste_with_actions(text)
        return
    # send-key encodes the key the way the program asked for (legacy \x16
    # or the kitty keyboard protocol), so it lands as a real Ctrl+V.
    boss.call_remote_control(w, ("send-key", "ctrl+v"))


handle_result.no_ui = True
