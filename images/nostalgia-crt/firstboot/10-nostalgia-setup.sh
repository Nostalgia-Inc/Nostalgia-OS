#!/usr/bin/env bash
set -euo pipefail

LOG=/var/log/nostalgia-firstboot.log
exec >>"$LOG" 2>&1
echo "[Nostalgia] first-boot starting at $(date -Is)"

STATE_DIR=/var/lib/nostalgia
DONE_FLAG="$STATE_DIR/firstboot.done"
mkdir -p "$STATE_DIR"
if [[ -f "$DONE_FLAG" ]]; then
  echo "[Nostalgia] already completed; exiting."
  exit 0
fi

# Ensure dirs exist
install -d /usr/share/nostalgia /usr/share/nostalgia/media /usr/lib/nostalgia /etc/sddm.conf.d

# 1) Plymouth: rebuild initramfs so theme shows on next boot
if command -v plymouth-set-default-theme >/dev/null 2>&1; then
  plymouth-set-default-theme nostalgia -R || true
fi

# 2) KDE wallpaper: FORCE set for existing users (keep for new via /etc/skel)
WALL=/usr/share/wallpapers/Nostalgia.png
if [[ -f /usr/share/nostalgia/branding/wallpaper.png && ! -f "$WALL" ]]; then
  install -D /usr/share/nostalgia/branding/wallpaper.png "$WALL"
fi

if [[ -f "$WALL" ]]; then
  for H in /home/*; do
    [[ -d "$H" ]] || continue
    U="$(basename "$H")"
    CFG="$H/.config/plasma-org.kde.plasma.desktop-appletsrc"
    install -d "$H/.config"

    # If config exists, replace Image= line; otherwise create minimal file
    if [[ -f "$CFG" ]]; then
      if grep -q '^Image=' "$CFG"; then
        sed -i 's#^Image=.*#Image=file:///usr/share/wallpapers/Nostalgia.png#' "$CFG"
      else
        printf '\n[Containments][1][Wallpaper][org.kde.image][General]\nImage=file:///usr/share/wallpapers/Nostalgia.png\n' >> "$CFG"
      fi
    else
      printf '%s\n[Containments][1][Wallpaper][org.kde.image][General]\nImage=file:///usr/share/wallpapers/Nostalgia.png\n' > "$CFG"
    fi
    chown -R "$U:$U" "$H/.config"
  done
fi

# 3) Network + Arduino (Flatpak)
nm-online -q || true
flatpak --system remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo || true
flatpak --system install -y --noninteractive flathub cc.arduino.arduinoide || true

# 4) Steam intro/outro (for EXISTING users)
INTRO=/usr/share/nostalgia/media/boot-intro.webm
OUTRO=/usr/share/nostalgia/media/boot-outro.webm
if [[ -f "$INTRO" || -f "$OUTRO" ]]; then
  for H in /home/*; do
    [[ -d "$H" ]] || continue
    U="$(basename "$H")"

    # Create the Valve uioverrides path even if Steam hasn't been launched yet
    MOVES="$H/.steam/root/config/uioverrides/movies"
    install -d "$MOVES"
    [[ -f "$INTRO" ]] && ln -sf "$INTRO" "$MOVES/deck_startup.webm"
    [[ -f "$OUTRO" ]] && ln -sf "$OUTRO" "$MOVES/deck_shutdown.webm"
    chown -R "$U:$U" "$H/.steam"
  done
fi

# 5) Hostname suffix
current="$(cat /etc/hostname 2>/dev/null || hostname)"
echo "${current}_CRT" > /etc/hostname

touch "$DONE_FLAG"
systemctl disable nostalgia-firstboot.service || true
echo "[Nostalgia] first-boot finished at $(date -Is)"
exit 0
