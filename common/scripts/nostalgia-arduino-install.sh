#!/usr/bin/bash
set -euo pipefail

APP_ID=cc.arduino.IDE2
if flatpak info --system "$APP_ID" >/dev/null 2>&1; then
    echo "Arduino IDE 2 is installed system-wide"
    exit 0
fi

echo "Installing Arduino IDE 2; a failed download will be retried"
flatpak remote-add --system --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak install --system --assumeyes --noninteractive flathub "$APP_ID"
# Do not report success until the application is actually installed.
flatpak info --system "$APP_ID" >/dev/null
echo "Arduino IDE 2 installation complete"
