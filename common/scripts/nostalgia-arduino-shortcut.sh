#!/usr/bin/bash
set -euo pipefail

STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/nostalgia"
MARKER="$STATE_DIR/arduino-shortcut-v2"
[[ ! -f "$MARKER" ]] || exit 0

# The independent user service retries while the background installer downloads.
flatpak info --system cc.arduino.IDE2 >/dev/null
SOURCE=/var/lib/flatpak/exports/share/applications/cc.arduino.IDE2.desktop
[[ -r "$SOURCE" ]] || { echo "Arduino IDE 2 launcher is not exported yet" >&2; exit 1; }
DESKTOP_DIR="$(xdg-user-dir DESKTOP)"
mkdir -p "$STATE_DIR"

# XDG uses HOME when desktop icons are disabled.
if [[ -z "$DESKTOP_DIR" || "$DESKTOP_DIR" == "$HOME" ]]; then
    echo "Desktop directory disabled; Arduino IDE 2 is available in the app menu"
    touch "$MARKER"
    exit 0
fi
mkdir -p "$DESKTOP_DIR"
TARGET="$DESKTOP_DIR/Arduino.desktop"
# Migrate our old broken launcher without overwriting a user's custom shortcut.
if [[ ! -e "$TARGET" ]] || grep -qx 'Exec=arduino' "$TARGET"; then
    install -m0755 "$SOURCE" "$TARGET"
else
    echo "Preserving existing Arduino desktop shortcut"
fi
touch "$MARKER"
