#!/usr/bin/env bash
set -euo pipefail

LOG=/var/log/nostalgia-firstboot.log
exec >>"$LOG" 2>&1
echo "[Nostalgia] first-boot starting at $(date -Is)"

STATE_DIR=/var/lib/nostalgia
DONE_FLAG="$STATE_DIR/firstboot.done"
mkdir -p "$STATE_DIR"
[[ -f "$DONE_FLAG" ]] && { echo "[Nostalgia] already done"; exit 0; }

# Make sure dirs exist
install -d /usr/share/nostalgia /usr/share/nostalgia/media /usr/lib/nostalgia

# Add Flathub and install Arduino IDE (Steam is already handled by Deck)
nm-online -q || true
flatpak --system remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo || true
flatpak --system install -y --noninteractive flathub cc.arduino.arduinoide || true

# Wallpaper example for KDE (system default for new users)
# If you ship a wallpaper at /usr/share/nostalgia/branding/wallpaper.png,
# copy or set it via a plasma-defaults file (simple default copy shown):
if [[ -f /usr/share/nostalgia/branding/wallpaper.png ]]; then
  install -D /usr/share/nostalgia/branding/wallpaper.png \
            /usr/share/wallpapers/Nostalgia.png
fi

# Hostname suffix
current="$(cat /etc/hostname 2>/dev/null || hostname)"
echo "${current}_CRT" > /etc/hostname

touch "$DONE_FLAG"
systemctl disable nostalgia-firstboot.service || true
echo "[Nostalgia] first-boot finished at $(date -Is)"
