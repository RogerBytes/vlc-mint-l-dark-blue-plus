#!/usr/bin/env bash
# Turns on the skins interface for the CURRENT user and selects a skin.
# Run it as a normal user (no sudo): it only edits ~/.config/vlc/vlcrc.
#   ./tools/enable-skin.sh          -> window buttons on the left (default.vlt)
#   ./tools/enable-skin.sh right    -> window buttons on the right
set -euo pipefail

if [[ "$(id -u)" -eq 0 ]]; then
    echo "Run this script as your normal user, not with sudo." >&2
    exit 1
fi

case "${1:-left}" in
    left)  SKIN="/usr/share/vlc/skins2/default.vlt" ;;
    right) SKIN="/usr/share/vlc/skins2/Mint-L-Dark-Blue-Right.vlt" ;;
    *) echo "Usage: $0 [left|right]" >&2; exit 1 ;;
esac

if [[ ! -f "$SKIN" ]]; then
    echo "Skin not found: $SKIN (is the package installed?)" >&2
    exit 1
fi

if pgrep -x vlc > /dev/null; then
    echo "Close VLC first, then run this script again." >&2
    exit 1
fi

RC="${XDG_CONFIG_HOME:-$HOME/.config}/vlc/vlcrc"
mkdir -p "$(dirname "$RC")"
touch "$RC"

python3 - "$RC" "$SKIN" <<'PY'
import sys
rc, skin = sys.argv[1:]
lines = open(rc, encoding="utf-8", errors="replace").read().splitlines()

def set_key(lines, section, key, value):
    out, in_sec, done, seen_sec = [], False, False, False
    for line in lines:
        s = line.strip()
        if s.startswith("[") and s.endswith("]"):
            if in_sec and not done:
                out.append(f"{key}={value}")
                done = True
            in_sec = s == f"[{section}]"
            seen_sec = seen_sec or in_sec
        elif in_sec and not done and (s.startswith(f"{key}=") or s.startswith(f"#{key}=")):
            out.append(f"{key}={value}")
            done = True
            continue
        out.append(line)
    if not done:
        if not seen_sec:
            out += ["", f"[{section}]"]
        out.append(f"{key}={value}")
    return out

lines = set_key(lines, "core", "intf", "skins2")
lines = set_key(lines, "skins2", "skins2-last", skin)
open(rc, "w", encoding="utf-8").write("\n".join(lines) + "\n")
PY

echo "Skin enabled: $SKIN"
echo "Start VLC as usual."
