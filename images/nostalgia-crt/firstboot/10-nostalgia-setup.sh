#!/usr/bin/env bash
set -oue pipefail
set -e

echo "[Nostalgia CRT] Running first boot setup..."

# Apply custom wallpaper (KDE)
wallpaper="/usr/share/nostalgia/branding/wallpaper.png"
if [[ -f "$wallpaper" ]]; then
  cp "$wallpaper" /usr/share/wallpapers/Nostalgia.png
fi

# Custom hostname
hostnamectl set-hostname "$(hostname)_CRT"

systemctl disable nostalgia.service

echo "[Nostalgia CRT] First boot setup completed."