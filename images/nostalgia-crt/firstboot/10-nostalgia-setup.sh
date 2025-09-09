#!/usr/bin/env bash
set -euo pipefail

LOG=/var/log/nostalgia-firstboot.log
exec >>"$LOG" 2>&1
echo "[Nostalgia] first-boot starting at $(date -Is)"

# Idempotency guard
STATE_DIR=/var/lib/nostalgia
DONE_FLAG="$STATE_DIR/firstboot.done"
mkdir -p "$STATE_DIR"
if [[ -f "$DONE_FLAG" ]]; then
  echo "[Nostalgia] first-boot already completed, exiting."
  exit 0
fi

# Ensure dirs we touch exist; never fail on absent paths
install -d /usr/share/nostalgia
install -d /usr/share/nostalgia/media
install -d /usr/lib/nostalgia

# Optional: if you keep helper scripts in /usr/lib/nostalgia/scripts later
install -d /usr/lib/nostalgia/scripts || true

# Make sure networking is up enough for Flatpak
nm-online -q || true

# Add Flathub and install Steam + Arduino IDE as system flatpaks
flatpak --system remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo || true
flatpak --system install -y --noninteractive flathub com.valvesoftware.Steam cc.arduino.arduinoide || true

# (EmuDeck is interactive; we’ll do it as a user step later.)

# Mark done and disable the unit
touch "$DONE_FLAG"
systemctl disable nostalgia-firstboot.service || true

echo "[Nostalgia] first-boot finished at $(date -Is)"
exit 0
