#!/usr/bin/env bash
set -euo pipefail

echo "[FIRSTBOOT] Nostalgia OS setup starting..."

# --- Branding: wallpaper (KDE) ---
wallpaper="/usr/share/nostalgia/branding/wallpaper.png"
if [[ -f "$wallpaper" ]]; then
  install -D -m 0644 "$wallpaper" /usr/share/wallpapers/Nostalgia.png
fi

# --- Hostname (ensure CRT suffix) ---
current="$(hostname)"
if [[ "$current" != *_CRT ]]; then
  hostnamectl set-hostname "${current}_CRT"
fi

# --- Create default user if missing ---
USER_NAME="crt"
USER_PASS="nostalgia"   # CHANGE this later
if ! id -u "$USER_NAME" >/dev/null 2>&1; then
  useradd -m -G wheel,audio,video -s /bin/bash "$USER_NAME"
  echo "${USER_NAME}:${USER_PASS}" | chpasswd
  echo "[FIRSTBOOT] Created user '${USER_NAME}' with a temporary password."
fi

# --- Flatpak + Arduino IDE (runtime install) ---
if ! flatpak remotes | grep -q '^flathub'; then
  flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
fi
flatpak install -y --noninteractive flathub cc.arduino.arduinoide || true

# --- SDDM autologin (KDE) ---
mkdir -p /etc/sddm.conf.d
cat >/etc/sddm.conf.d/00-nostalgia-autologin.conf <<EOF
[Autologin]
User=${USER_NAME}
Session=plasma.desktop
Relogin=true
EOF

# --- Make login background match (optional) ---
# If you’ve made a custom SDDM theme, point to it here.
# This sets our simple autologin conf only; SDDM theme can be added separately.

# --- Disable this service so it runs once ---
systemctl disable nostalgia.service || true

# --- If we executed before SDDM starts (preferred), autologin applies on this boot.
# If not, try to restart display manager safely:
if systemctl is-active --quiet sddm; then
  systemctl try-restart sddm || true
fi

echo "[FIRSTBOOT] Nostalgia OS setup complete."
