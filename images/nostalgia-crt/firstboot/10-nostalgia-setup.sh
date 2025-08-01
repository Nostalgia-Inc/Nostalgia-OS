#!/usr/bin/env bash
set -oue pipefail

echo "[Nostalgia CRT] Running first boot setup..."

# Apply custom wallpaper (KDE)
wallpaper="/usr/share/nostalgia/branding/wallpaper.png"
if [[ -f "$wallpaper" ]]; then
  cp "$wallpaper" /usr/share/wallpapers/Nostalgia.png
fi

# Run EmuDeck install script (from /usr/share/nostalgia/scripts)
chmod +x /usr/share/nostalgia/scripts/install-emudeck.sh
bash /usr/share/nostalgia/scripts/install-emudeck.sh || true

echo "[Nostalgia CRT] First boot setup completed."
