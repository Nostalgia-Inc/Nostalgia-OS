#!/usr/bin/env bash
set -euo pipefail

log(){ echo "[Nostalgia first-boot] $*"; }

# ensure our work dirs exist
install -d /var/lib/nostalgia

# --- 1) Ensure Flathub and Arduino IDE are present --------------------------------
if ! flatpak remotes --columns=name | grep -qx flathub; then
  log "Adding Flathub remote"
  flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
fi

if ! flatpak info cc.arduino.arduinoide >/dev/null 2>&1; then
  log "Installing Arduino IDE (Flatpak)"
  flatpak install -y --noninteractive flathub cc.arduino.arduinoide || log "Arduino install failed (continuing)"
else
  log "Arduino already installed"
fi

# --- 2) Apply wallpaper for existing 'nostalgia' user (if any) ---------------------
WALLPAPER="/usr/share/nostalgia/Nostalgia.png"
TARGET_USER="nostalgia"

if id "$TARGET_USER" >/dev/null 2>&1 && [ -f "$WALLPAPER" ]; then
  USER_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6)"
  # Try KDE helper if available (user context)
  if command -v rsync >/dev/null; then :; fi
  log "Setting wallpaper for $TARGET_USER"
  install -d "$USER_HOME/.config"
  # minimal plasma config injection (keeps existing file if present)
  CFG="$USER_HOME/.config/plasma-org.kde.plasma.desktop-appletsrc"
  if ! grep -q 'Image=file:///usr/share/nostalgia/Nostalgia.png' "$CFG" 2>/dev/null; then
    {
      echo "[Containments][1][Wallpaper][org.kde.image][General]"
      echo "Image=file:///usr/share/nostalgia/Nostalgia.png"
    } >> "$CFG"
    chown "$TARGET_USER:$TARGET_USER" "$CFG"
  fi
fi

# --- 3) Seed Steam intro/outro videos for existing user ----------------------------
if id "$TARGET_USER" >/dev/null 2>&1; then
  USER_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6)"
  MOV_DIR="$USER_HOME/.steam/root/config/uioverrides/movies"
  install -d "$MOV_DIR"
  if [ -f /usr/share/nostalgia/media/boot-intro.webm ]; then
    ln -sf /usr/share/nostalgia/media/boot-intro.webm "$MOV_DIR/deck_startup.webm"
  fi
  if [ -f /usr/share/nostalgia/media/boot-outro.webm ]; then
    ln -sf /usr/share/nostalgia/media/boot-outro.webm "$MOV_DIR/deck_shutdown.webm"
  fi
  chown -R "$TARGET_USER:$TARGET_USER" "$USER_HOME/.steam"
fi

# --- 4) Mark as done so it never re-runs -------------------------------------------
touch /var/lib/nostalgia/firstboot.done
log "Completed successfully."