#!/usr/bin/env bash
set -euo pipefail

LOG=/var/log/nostalgia-firstboot.log
exec >>"$LOG" 2>&1
echo "[Nostalgia] first-boot starting at $(date -Is)"

STATE_DIR=/var/lib/nostalgia
DONE_FLAG="$STATE_DIR/firstboot.done"
mkdir -p "$STATE_DIR"
if [[ -f "$DONE_FLAG" ]]; then
  echo "[Nostalgia] first-boot already completed, exiting."
  exit 0
fi

# Ensure key dirs exist
install -d /usr/share/nostalgia /usr/share/nostalgia/media /usr/lib/nostalgia

# 1) Plymouth: ensure theme applied in initramfs for next boot
if command -v plymouth-set-default-theme >/dev/null 2>&1; then
  plymouth-set-default-theme nostalgia -R || true
fi

# 2) Arduino IDE (networked, runtime)
nm-online -q || true
flatpak --system remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo || true
flatpak --system install -y --noninteractive flathub cc.arduino.arduinoide || true

# 3) Game Mode intro/outro for EXISTING users (installer-created)
INTRO=/usr/share/nostalgia/media/boot-intro.webm
OUTRO=/usr/share/nostalgia/media/boot-outro.webm
if [[ -f "$INTRO" || -f "$OUTRO" ]]; then
  for H in /home/*; do
    [[ -d "$H" ]] || continue
    U="$(basename "$H")"
    MOVES="$H/.steam/root/config/uioverrides/movies"
    install -d "$MOVES"
    [[ -f "$INTRO" ]] && ln -sf "$INTRO" "$MOVES/deck_startup.webm"
    [[ -f "$OUTRO" ]] && ln -sf "$OUTRO" "$MOVES/deck_shutdown.webm"
    chown -R "$U":"$U" "$H/.steam"
  done
fi

# 4) KDE wallpaper for EXISTING users who don’t have one yet
if [[ -f /usr/share/wallpapers/Nostalgia.png ]]; then
  for H in /home/*; do
    [[ -d "$H" ]] || continue
    U="$(basename "$H")"
    CFG="$H/.config/plasma-org.kde.plasma.desktop-appletsrc"
    if [[ ! -f "$CFG" ]]; then
      install -d "$H/.config"
      printf '%s\n[Containments][1][Wallpaper][org.kde.image][General]\nImage=file:///usr/share/wallpapers/Nostalgia.png\n' > "$CFG"
      chown -R "$U":"$U" "$H/.config"
    fi
  done
fi

# 5) Hostname suffix
current="$(cat /etc/hostname 2>/dev/null || hostname)"
echo "${current}_CRT" > /etc/hostname

touch "$DONE_FLAG"
systemctl disable nostalgia-firstboot.service || true
echo "[Nostalgia] first-boot finished at $(date -Is)"
exit 0
