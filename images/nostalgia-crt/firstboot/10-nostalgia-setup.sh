#!/usr/bin/env bash
set -oue pipefail
set -e

echo "[Nostalgia CRT] Running first boot setup..."

# Apply custom wallpaper (KDE)
wallpaper="/usr/share/nostalgia/branding/wallpaper.png"
if [[ -f "$wallpaper" ]]; then
  cp "$wallpaper" /usr/share/wallpapers/Nostalgia.png
fi

# Custom User
useradd -m -G wheel -s /bin/bash crt
echo "crt:nostalgia" | chpasswd

# Custom hostname
hostnamectl set-hostname "$(hostname)_CRT"

# Flatpak setup for Arduino IDE
echo "[Nostalgia CRT] Installing Flatpak apps..."
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak install -y --noninteractive flathub cc.arduino.arduinoide

# Optionally add EmuDeck or any other setup here in the future

# Disable service so it doesn't re-run
systemctl disable nostalgia.service

echo "[Nostalgia CRT] First boot setup completed."
