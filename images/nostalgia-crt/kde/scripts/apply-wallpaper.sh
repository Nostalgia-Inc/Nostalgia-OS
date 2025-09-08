#!/usr/bin/env bash
set -euo pipefail
WALL="/usr/share/nostalgia/branding/wallpaper.png"
MARKER="$HOME/.config/.nostalgia_wallpaper_applied"

# Only run inside a Plasma session
if [[ "${XDG_CURRENT_DESKTOP:-}" != *KDE* && "${DESKTOP_SESSION:-}" != *plasma* ]]; then
  exit 0
fi

# Tool exists?
if ! command -v plasma-apply-wallpaperimage >/dev/null 2>&1; then
  exit 0
fi

if [[ -f "$WALL" && ! -f "$MARKER" ]]; then
  plasma-apply-wallpaperimage "$WALL" || true
  mkdir -p "$(dirname "$MARKER")"
  touch "$MARKER"
fi
