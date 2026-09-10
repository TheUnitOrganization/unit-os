#!/usr/bin/env python3
"""SUPER+CTRL+<arrow>: put the focused window on that side, and mean it.

Plain swapwindow only trades places with a window that is already there, so in
a top/bottom pair SUPER+CTRL+left does nothing at all -- there is no left
neighbour to swap with, and dwindle's preserve_split keeps the pair stacked.
This flips the split when that is the only way "left" can mean anything:

  neighbour that way       -> swap with it (what swapwindow always did)
  neighbour the other way  -> already at that end of the split, do nothing
  neither                  -> the pair is split on the wrong axis: flip it,
                              then land on the side that was asked for
"""
import json
import subprocess
import sys

DIRS = {"left": ("x", -1), "right": ("x", 1), "up": ("y", -1), "down": ("y", 1)}


def hypr(*args):
    return subprocess.run(["hyprctl", *args], capture_output=True, text=True).stdout


def dispatch(lua):
    subprocess.run(["hyprctl", "dispatch", lua], capture_output=True)


def main():
    d = sys.argv[1] if len(sys.argv) > 1 else ""
    if d not in DIRS:
        sys.exit("usage: snap-window.py " + "|".join(DIRS))
    axis, sign = DIRS[d]

    me = json.loads(hypr("activewindow", "-j") or "{}")
    if not me.get("address") or me.get("floating") or me.get("fullscreen"):
        return  # floating and fullscreen windows are not in the tiling tree
    ws = me["workspace"]["id"]
    others = [c for c in json.loads(hypr("clients", "-j") or "[]")
              if c["workspace"]["id"] == ws and not c["floating"]
              and c["address"] != me["address"]]

    i = 0 if axis == "x" else 1   # the axis the direction moves along
    j = 1 - i                     # the one it has to share to be a neighbour

    def neighbour(c, s):
        # Gaps only ever shrink windows along the axis they are split on, so
        # "shares the other axis" is a plain overlap test -- side-by-side
        # windows overlap in y, stacked ones do not.
        if min(me["at"][j] + me["size"][j], c["at"][j] + c["size"][j]) \
                <= max(me["at"][j], c["at"][j]):
            return False
        mid = me["at"][i] + me["size"][i] / 2
        return (c["at"][i] + c["size"][i] / 2 - mid) * s > 0

    if any(neighbour(c, sign) for c in others):
        dispatch('hl.dsp.window.swap({ direction = "%s" })' % d)
    elif any(neighbour(c, -sign) for c in others):
        return  # already as far that way as this split goes
    else:
        dispatch('hl.dsp.layout("togglesplit")')
        dispatch('hl.dsp.window.swap({ direction = "%s" })' % d)


main()
