#!/usr/bin/env bash
set -euo pipefail

echo "[Nostalgia OS] First-boot setup starting..."

# 0) One-shot guard
STAMP="/var/lib/nostalgia-firstboot.done"
if [[ -f "$STAMP" ]]; then
  echo "[Nostalgia OS] First-boot already completed. Exiting."
  exit 0
fi

# 1) Branding: wallpaper & SDDM background (files must be provided in ./common)
# Desktop wallpaper asset copied to /usr/share/wallpapers by Containerfile or here:
if [[ -f "/usr/share/nostalgia/branding/wallpaper.png" ]]; then
  install -D -m 0644 /usr/share/nostalgia/branding/wallpaper.png /usr/share/wallpapers/Nostalgia.png
fi

# 2) Hostname suffix (_OS)
if command -v hostnamectl >/dev/null 2>&1; then
  current="$(hostname)"
  [[ "$current" != *_OS ]] && hostnamectl set-hostname "${current}_OS" || true
fi

# 3) Flatpak: make sure flathub is present, then install Arduino IDE system-wide
if command -v flatpak >/dev/null 2>&1; then
  flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo || true
  # Arduino IDE
  flatpak install -y --system flathub cc.arduino.arduinoide || true
  # EmuDeck is user-scoped and interactive; enable a desktop file to prompt the user later (optional).
fi

# 4) Disable the unit and stamp completion
systemctl disable nostalgia-firstboot.service || true
touch "$STAMP"
echo "[Nostalgia OS] First-boot setup completed."
