#!/usr/bin/env bash
# Per-machine setup for photofind.
#
# ~/Code/ syncs via Syncthing, so the script itself travels between machines.
# ~/.local/bin does NOT sync, and macOS Full Disk Access is granted per-machine
# per-binary — so this has to be run once on each Mac.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN="$HOME/.local/bin"

mkdir -p "$BIN"
chmod +x "$HERE/photofind"
ln -sf "$HERE/photofind" "$BIN/photofind"
echo "✓ linked $BIN/photofind -> $HERE/photofind"

case ":$PATH:" in
  *":$BIN:"*) ;;
  *) echo "⚠ $BIN is not on PATH — add it in ~/Code/system/.zshrc (synced), not ~/.zshrc" ;;
esac

if command -v montage >/dev/null 2>&1; then
  echo "✓ imagemagick present (contact sheets available)"
else
  echo "⚠ imagemagick missing — 'photofind sheet' will not work"
  echo "  fix: brew install imagemagick"
fi

LIB="${PHOTOFIND_LIBRARY:-$HOME/Pictures/Photos Library.photoslibrary}"
if [ ! -d "$LIB" ]; then
  echo "⚠ no Photos library at $LIB"
  echo "  If this Mac keeps its library elsewhere, set PHOTOFIND_LIBRARY in ~/Code/system/.zshrc"
  exit 0
fi
echo "✓ library found: $LIB"

# Full Disk Access is the usual failure and the error is opaque, so probe for it.
if python3 - "$LIB" <<'PY' 2>/dev/null
import sqlite3, sys
sqlite3.connect(f"file:{sys.argv[1]}/database/Photos.sqlite?immutable=1", uri=True) \
       .execute("select count(*) from ZASSET").fetchone()
PY
then
  echo "✓ database readable (Full Disk Access granted)"
  echo
  "$BIN/photofind" doctor
else
  cat <<'MSG'
✗ cannot read the Photos database.

This is almost always missing Full Disk Access, which is granted PER MACHINE and
PER BINARY (Terminal.app and iTerm are separate entries):

  System Settings -> Privacy & Security -> Full Disk Access
  -> enable your terminal, then fully quit and reopen it

Re-run this script afterwards to verify.
MSG
  exit 1
fi
