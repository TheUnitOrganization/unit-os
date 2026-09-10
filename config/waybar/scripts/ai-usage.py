#!/usr/bin/env python3
"""Waybar module: AI allowance usage across providers.

Subscriptions, not invoices: the question is "how much of each window have I
used", not "what did it cost".

Providers:
  claude    Claude Max subscription. Uses Claude Code's own OAuth token from
            ~/.claude/.credentials.json -- nothing to configure.
  replicate REPLICATE_API_TOKEN in ~/.config/ai-usage/env
  openai    OPENAI_ADMIN_KEY   in ~/.config/ai-usage/env  (org Admin key)
  opencode  OpenCode Go allowance from https://opencode.ai/zen/go/v1/usage.
            Key: OPENCODE_ZEN_API_KEY in ~/.config/ai-usage/env, or whatever
            `opencode auth login` left in ~/.local/share/opencode/auth.json.
            Zen pay-as-you-go credit has no API -- console only.

Every provider also reports when you last used it, so a provider you have
tokens for but haven't touched still says so instead of going silent.

    ai-usage.py            waybar JSON
    ai-usage.py --notify   plain body for notify-send (SUPER+A)
    ai-usage.py --debug    raw provider responses, for wiring new ones

Network results are cached in ~/.cache/ai-usage/ so the bar can refresh
often without hammering anyone's API.
"""

import json
import os
import sys
import time
import datetime as dt
import urllib.request
import urllib.error
from pathlib import Path

HOME = Path.home()
ENV_FILE = HOME / ".config" / "ai-usage" / "env"
CACHE_DIR = HOME / ".cache" / "ai-usage"
CLAUDE_CREDS = HOME / ".claude" / ".credentials.json"
OPENCODE_DATA = HOME / ".local" / "share" / "opencode"
OPENCODE_AUTH = OPENCODE_DATA / "auth.json"
CLAUDE_PROJECTS = HOME / ".claude" / "projects"
ZEN_USAGE_URL = "https://opencode.ai/zen/go/v1/usage"

CACHE_TTL = 120   # seconds
ICON = "✦"
DEBUG = "--debug" in sys.argv


# --------------------------------------------------------------------------
def load_env():
    env = {}
    try:
        for line in ENV_FILE.read_text().splitlines():
            line = line.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            k, v = line.split("=", 1)
            env[k.strip()] = v.strip().strip('"').strip("'")
    except OSError:
        pass
    return env


def cached(name, fetch):
    """Return fetch() result, cached on disk for CACHE_TTL seconds."""
    CACHE_DIR.mkdir(parents=True, exist_ok=True)
    f = CACHE_DIR / f"{name}.json"
    try:
        if time.time() - f.stat().st_mtime < CACHE_TTL:
            return json.loads(f.read_text())
    except (OSError, ValueError):
        pass
    data = fetch()
    try:
        f.write_text(json.dumps(data))
        os.chmod(f, 0o600)
    except OSError:
        pass
    return data


def get_json(url, headers):
    req = urllib.request.Request(url, headers={"User-Agent": "ai-usage-widget/0.2", **headers})
    with urllib.request.urlopen(req, timeout=12) as r:
        return json.load(r)


def when(iso):
    """'in 2h 14m' / 'in 3d 4h' from an ISO timestamp."""
    if not iso:
        return ""
    try:
        t = dt.datetime.fromisoformat(iso.replace("Z", "+00:00"))
        s = (t - dt.datetime.now(dt.timezone.utc)).total_seconds()
    except ValueError:
        return ""
    if s <= 0:
        return "now"
    d, r = divmod(int(s), 86400)
    h, r = divmod(r, 3600)
    m = r // 60
    if d:
        return f"in {d}d {h}h"
    if h:
        return f"in {h}h {m:02d}m"
    return f"in {m}m"


def ago(ts):
    """'today 15:14' / '3d ago' from a unix timestamp or ISO string."""
    if not ts:
        return "never"
    if isinstance(ts, str):
        try:
            ts = dt.datetime.fromisoformat(ts.replace("Z", "+00:00")).timestamp()
        except ValueError:
            return "never"
    t = dt.datetime.fromtimestamp(ts)
    days = (dt.datetime.now().date() - t.date()).days
    if days == 0:
        return f"today {t:%H:%M}"
    if days == 1:
        return f"yesterday {t:%H:%M}"
    if days < 30:
        return f"{t:%-d %b}  ({days}d ago)"
    return f"{t:%-d %b %Y}  ({days}d ago)"


def date_ago(iso_date):
    """'today' / '3 Sep  (4d ago)' from a bare YYYY-MM-DD -- no clock time,
    which a hand-typed date does not have."""
    t = dt.date.fromisoformat(iso_date)
    days = (dt.date.today() - t).days
    if days == 0:
        return "today"
    if days == 1:
        return "yesterday"
    return f"{t:%-d %b}  ({days}d ago)"


def newest(root, pattern):
    """mtime of the most recently touched file under root, or None."""
    best = None
    try:
        for f in root.glob(pattern):
            try:
                m = f.stat().st_mtime
            except OSError:
                continue
            if best is None or m > best:
                best = m
    except OSError:
        pass
    return best


def claude_last_session():
    # Claude Code appends to one .jsonl per session, so the newest transcript
    # is the last time this machine talked to Claude.
    return newest(CLAUDE_PROJECTS, "*/*.jsonl")


def opencode_last_session():
    # opencode writes storage/session/info/<id> per session, under the data
    # dir and again per project -- rglob catches both layouts.
    best = None
    try:
        for d in OPENCODE_DATA.rglob("storage/session/info"):
            m = newest(d, "*")
            if m and (best is None or m > best):
                best = m
    except OSError:
        pass
    return best


def gauge(pct, width=14):
    """A filled track, not ASCII art. Full blocks on a light-shade rail read
    as one continuous bar at any size -- dots left gaps that looked like a
    rendering bug next to the solid waybar pills."""
    pct = max(0.0, min(100.0, float(pct)))
    n = int(round(pct / 100 * width))
    return "█" * n + "░" * (width - n)


def esc(s):
    return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")


def fail(name, e):
    return {"ok": False, "lines": [f"  {name}: {type(e).__name__}"],
            "worst": None, "bar": None, "note": None}


# --------------------------------------------------------------------------
# Providers. Each returns {"ok", "lines", "worst", "bar", "note"}
# --------------------------------------------------------------------------
def claude():
    def fetch():
        tok = json.load(open(CLAUDE_CREDS))["claudeAiOauth"]["accessToken"]
        return get_json("https://api.anthropic.com/api/oauth/usage",
                        {"Authorization": f"Bearer {tok}",
                         "anthropic-beta": "oauth-2025-04-20"})
    try:
        d = cached("claude", fetch)
    except Exception as e:
        return fail("claude", e)

    if DEBUG:
        print(json.dumps(d, indent=1)[:3000])

    lines, worst = [], 0.0
    worst_label = None
    active_pct = active_label = None
    session_pct = weekly_pct = None

    for lim in d.get("limits") or []:
        pct = float(lim.get("percent") or 0)
        kind = lim.get("kind", "")
        scope = (lim.get("scope") or {}).get("model") or {}
        label = {"session": "5-hour",
                 "weekly_all": "weekly",
                 "weekly_scoped": f"weekly {scope.get('display_name') or 'model'}"}.get(kind, kind)
        lines.append(f"  {label:<14}{gauge(pct)} {pct:>3.0f}%   resets {when(lim.get('resets_at'))}")
        if pct >= worst:
            worst, worst_label = pct, label
        if kind == "session":
            session_pct = pct
        elif kind == "weekly_all":
            weekly_pct = pct
        if lim.get("is_active"):
            active_pct, active_label = pct, label

    if not lines:  # older response shape
        for label, o in (("5-hour", d.get("five_hour") or {}), ("weekly", d.get("seven_day") or {})):
            pct = float(o.get("utilization") or 0)
            lines.append(f"  {label:<14}{gauge(pct)} {pct:>3.0f}%   resets {when(o.get('resets_at'))}")
            if label == "5-hour":
                session_pct = pct
            else:
                weekly_pct = pct
            worst = max(worst, pct)

    lines.append(f"  last session  {ago(claude_last_session())}")

    # The bar shows the limit that is actually binding right now.
    bar_pct = active_pct if active_pct is not None else worst
    return {"ok": True, "lines": lines, "worst": worst,
            "bar": f"{bar_pct:.0f}%", "note": active_label,
            "worst_label": worst_label,
            "session": session_pct, "weekly": weekly_pct}


def replicate(env):
    """Replicate sells prepaid credit and its public API has no billing route
    at all -- /v1/account is username and avatar, nothing more. So the honest
    answer is: whoami, when you last ran something, and where the balance
    lives. /v1/predictions is the only usage signal the token can see."""
    tok = env.get("REPLICATE_API_TOKEN")
    if not tok:
        return {"ok": False,
                "lines": ["  account       no REPLICATE_API_TOKEN in ~/.config/ai-usage/env",
                          "  last run      unknown -- nothing local to read",
                          "  credit        no API -- replicate.com/account/billing"],
                "worst": None, "bar": None, "note": None}

    def fetch():
        h = {"Authorization": f"Bearer {tok}"}
        out = {"account": get_json("https://api.replicate.com/v1/account", h)}
        try:
            out["preds"] = get_json("https://api.replicate.com/v1/predictions", h)
        except Exception:
            out["preds"] = None
        return out
    try:
        d = cached("replicate", fetch)
    except Exception as e:
        return fail("replicate", e)
    if DEBUG:
        print(json.dumps(d, indent=1)[:2000])

    acct = d.get("account") or {}
    who = acct.get("username") or acct.get("name") or "account"
    results = ((d.get("preds") or {}).get("results")) or []
    last = results[0].get("created_at") if results else None

    # No balance route exists, so the number can only come from you. It is
    # shown with the age of the note rather than on its own -- a figure typed
    # in weeks ago is a guess, and should look like one.
    credit = "no API -- replicate.com/account/billing"
    try:
        usd = float(env["REPLICATE_CREDIT_USD"])
        noted = env.get("REPLICATE_CREDIT_DATE", "")
        age = date_ago(noted) if noted else ""
        credit = f"${usd:,.2f} as of {age}" if age else f"${usd:,.2f} (undated)"
        credit += "  -- typed in, not fetched"
    except (KeyError, TypeError, ValueError):
        pass

    return {"ok": True,
            "lines": [f"  account       {who}",
                      f"  last run      {ago(last)}",
                      f"  credit        {credit}"],
            "worst": None, "bar": None, "note": None}


def openai(env):
    key = env.get("OPENAI_ADMIN_KEY")
    if not key:
        return {"ok": False,
                "lines": ["  this month    no OPENAI_ADMIN_KEY in ~/.config/ai-usage/env",
                          "  last charge   unknown -- nothing local to read"],
                "worst": None, "bar": None, "note": None}

    month_start = int(dt.datetime.now(dt.timezone.utc)
                      .replace(day=1, hour=0, minute=0, second=0, microsecond=0).timestamp())

    def fetch():
        return get_json(f"https://api.openai.com/v1/organization/costs?start_time={month_start}&limit=31",
                        {"Authorization": f"Bearer {key}"})
    try:
        d = cached("openai", fetch)
    except Exception as e:
        return fail("openai", e)
    if DEBUG:
        print(json.dumps(d, indent=1)[:1500])
    total, last = 0.0, None
    for bucket in d.get("data") or []:
        spent = sum(float((r.get("amount") or {}).get("value") or 0)
                    for r in bucket.get("results") or [])
        total += spent
        if spent > 0 and bucket.get("start_time"):
            last = max(last or 0, bucket["start_time"])
    return {"ok": True,
            "lines": [f"  this month    ${total:,.2f} (API usage)",
                      f"  last charge   {ago(last)}"],
            "worst": None, "bar": None, "note": None}


def zen_key(env):
    """The Zen key, from our env file or from whatever `opencode auth login`
    stored. auth.json keys the entry by provider and the field name has moved
    between releases, so try the plausible ones rather than one hard path."""
    k = env.get("OPENCODE_ZEN_API_KEY") or os.environ.get("OPENCODE_ZEN_API_KEY")
    if k:
        return k
    try:
        d = json.load(open(OPENCODE_AUTH))
    except (OSError, ValueError):
        return None
    for name in ("opencode", "opencode-go", "opencode-zen", "zen"):
        e = d.get(name)
        if isinstance(e, dict):
            for f in ("key", "apiKey", "api_key", "access", "token"):
                if e.get(f):
                    return e[f]
    return None


def zen_windows(d):
    """/zen/go/v1/usage returns rolling / weekly / monthly windows carrying
    status, percent and resetAt. The response is undocumented, so accept both
    a list of windows and an object keyed by window name, and take the first
    field name that is actually present. --debug prints the raw body."""
    raw = d.get("usage") or d.get("windows") or d.get("limits") or d
    items = []
    if isinstance(raw, list):
        for w in raw:
            if isinstance(w, dict):
                items.append((w.get("window") or w.get("kind") or w.get("name") or "window", w))
    elif isinstance(raw, dict):
        for k, w in raw.items():
            if isinstance(w, dict) and any(f in w for f in
                    ("percent", "percentage", "resetAt", "resets_at", "reset_at", "used")):
                items.append((k, w))

    out = []
    for label, w in items:
        pct = None
        for f in ("percent", "percentage", "used_percent", "utilization"):
            if w.get(f) is not None:
                pct = float(w[f])
                if f == "utilization" and pct <= 1:
                    pct *= 100
                break
        if pct is None and w.get("used") is not None and w.get("limit"):
            try:
                pct = float(w["used"]) / float(w["limit"]) * 100
            except (TypeError, ValueError, ZeroDivisionError):
                pct = None
        reset = next((w[f] for f in ("resetAt", "resets_at", "reset_at", "resetsAt")
                      if w.get(f)), None)
        out.append((str(label), pct, reset))
    return out


def opencode(env):
    last = f"  last session  {ago(opencode_last_session())}"
    key = zen_key(env)
    if not key:
        return {"ok": False,
                "lines": ["  go            no key -- `opencode auth login`, or",
                          "                OPENCODE_ZEN_API_KEY in ~/.config/ai-usage/env",
                          "  zen credits   no API -- opencode.ai/console",
                          last],
                "worst": None, "bar": None, "note": None}

    def fetch():
        return get_json(ZEN_USAGE_URL, {"Authorization": f"Bearer {key}"})
    try:
        d = cached("opencode", fetch)
    except Exception as e:
        return {"ok": False,
                "lines": [f"  go            {type(e).__name__} from /zen/go/v1/usage",
                          "  zen credits   no API -- opencode.ai/console", last],
                "worst": None, "bar": None, "note": None}
    if DEBUG:
        print(json.dumps(d, indent=1)[:2000])

    lines, worst = [], 0.0
    for label, pct, reset in zen_windows(d):
        name = f"go {label}"[:13]
        if pct is None:
            lines.append(f"  {name:<14}(no percent in response)")
            continue
        lines.append(f"  {name:<14}{gauge(pct)} {pct:>3.0f}%   resets {when(reset)}")
        worst = max(worst, pct)
    if not lines:
        lines = ["  go            usage response not understood -- run --debug"]
    # Zen's pay-as-you-go wallet is deliberately absent: the API exposes no
    # balance route (opencode issue #44189), only an error once it empties.
    lines.append("  zen credits   no API -- opencode.ai/console")
    lines.append(last)
    return {"ok": True, "lines": lines, "worst": worst, "bar": None, "note": None}


# --------------------------------------------------------------------------
def main():
    env = load_env()
    c = claude()

    # One block per provider rather than one "other providers" list: each now
    # carries its own reset times and its own last-used line, so they no
    # longer read as a footnote to Claude.
    L = ["CLAUDE MAX"] + c["lines"]
    for title, prov in (("OPENCODE", opencode(env)),
                        ("REPLICATE", replicate(env)),
                        ("OPENAI", openai(env))):
        L += ["", title] + prov["lines"]
    body = "\n".join(L)

    if "--notify" in sys.argv:
        print("<tt>" + esc(body) + "</tt>")
        return

    # One number: the 5-hour session window. It is the limit that actually
    # bites during a working stretch, and it is the one that refills on a
    # timescale worth watching -- a per-model weekly cap sitting at 80% says
    # nothing about whether the next hour is going to stop. The weekly and
    # per-model windows stay one click away in the notification.
    shown = c.get("session")
    if shown is None:
        shown = c["worst"] or 0
    cls = "critical" if shown >= 90 else "warning" if shown >= 75 else "ok"

    # The glyph is enlarged with pango rather than by raising the module's
    # font size, which would make the whole pill taller.
    glyph = f'<span size="150%" rise="-1500">{ICON}</span>'
    text = f'{glyph} {shown:.0f}%' if c["ok"] else f'{glyph} --'

    print(json.dumps({
        "text": text,
        "alt": "5-hour",
        "tooltip": f"<tt>{esc(body)}</tt>",
        "class": cls,
        "percentage": int(shown),
    }))


if __name__ == "__main__":
    try:
        main()
    except Exception as exc:  # never let the module take the bar down
        print(json.dumps({"text": f"{ICON} --", "tooltip": str(exc), "class": "idle"}))
