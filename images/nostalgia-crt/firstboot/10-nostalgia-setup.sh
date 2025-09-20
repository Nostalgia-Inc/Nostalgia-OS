#!/usr/bin/env bash
set -euo pipefail

# ===================== helpers =====================
LOGTAG="[Nostalgia first-boot]"
log(){ echo "$LOGTAG $*"; }
warn(){ echo "$LOGTAG WARN: $*" >&2; }
err(){ echo "$LOGTAG ERROR: $*" >&2; }

DONE_FLAG="/var/lib/nostalgia/firstboot.done"
FORCE_FLAG=0
TARGET_USER="nostalgia"
WALLPAPER_SRC="/usr/share/nostalgia/Nostalgia.png"
STEAM_MOV_DIR_REL=".steam/root/config/uioverrides/movies"

# force if: --force arg, env var, or sentinel file
for a in "${@:-}"; do
  [[ "$a" == "--force" ]] && FORCE_FLAG=1
done
[[ "${NOSTALGIA_FORCE:-0}" = "1" ]] && FORCE_FLAG=1
[[ -f /run/nostalgia/force ]] && FORCE_FLAG=1

if [[ -f "$DONE_FLAG" && $FORCE_FLAG -ne 1 ]]; then
  log "Already completed (found $DONE_FLAG). Use --force / NOSTALGIA_FORCE=1 or /run/nostalgia/force to override."
  exit 0
fi

# Ensure base dirs
install -d /var/lib/nostalgia
[[ $FORCE_FLAG -eq 1 ]] && log "FORCE mode enabled."

get_user_home(){
  getent passwd "$1" | cut -d: -f6
}

# ===================== actions =====================
ensure_flathub_and_arduino(){
  if ! flatpak remotes --columns=name | grep -qx flathub; then
    log "Adding Flathub remote"
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo || warn "Failed to add Flathub"
  fi
  if ! flatpak info cc.arduino.arduinoide >/dev/null 2>&1; then
    log "Installing Arduino IDE (Flatpak)"
    flatpak install -y --noninteractive flathub cc.arduino.arduinoide || warn "Arduino install failed"
  else
    log "Arduino already installed"
  fi
}

apply_wallpaper_for_user(){
  local user="$1"
  [[ -f "$WALLPAPER_SRC" ]] || { warn "Wallpaper not found: $WALLPAPER_SRC"; return 0; }
  if id "$user" >/dev/null 2>&1; then
    local home; home="$(get_user_home "$user")"
    install -d "$home/.config"
    local cfg="$home/.config/plasma-org.kde.plasma.desktop-appletsrc"
    if ! grep -q 'Image=file:///usr/share/nostalgia/Nostalgia.png' "$cfg" 2>/dev/null; then
      log "Injecting wallpaper into $cfg for user $user"
      {
        echo "[Containments][1][Wallpaper][org.kde.image][General]"
        echo "Image=file:///usr/share/nostalgia/Nostalgia.png"
      } >> "$cfg"
      chown "$user:$user" "$cfg"
    else
      log "Wallpaper already configured for $user"
    fi
  else
    warn "User $user not found; skipping wallpaper"
  fi
}

seed_steam_movies_for_user(){
  local user="$1"
  if id "$user" >/dev/null 2>&1; then
    local home; home="$(get_user_home "$user")"
    local mov="$home/$STEAM_MOV_DIR_REL"
    install -d "$mov"
    if [[ -f /usr/share/nostalgia/media/boot-intro.webm ]]; then
      ln -sf /usr/share/nostalgia/media/boot-intro.webm "$mov/deck_startup.webm"
    fi
    if [[ -f /usr/share/nostalgia/media/boot-outro.webm ]]; then
      ln -sf /usr/share/nostalgia/media/boot-outro.webm "$mov/deck_shutdown.webm"
    fi
    chown -R "$user:$user" "$home/.steam" || true
  else
    warn "User $user not found; skipping Steam movie seeding"
  fi
}

# ===================== verification =====================
verify(){
  local ok=1

  if ! flatpak info cc.arduino.arduinoide >/dev/null 2>&1; then
    warn "Verify: Arduino IDE missing"
    ok=0
  fi

  if ! grep -q '^Theme=nostalgia$' /etc/plymouth/plymouthd.conf 2>/dev/null; then
    warn "Verify: Plymouth theme not set to nostalgia"
    ok=0
  fi

  if id "$TARGET_USER" >/dev/null 2>&1; then
    local home; home="$(get_user_home "$TARGET_USER")"
    if ! grep -q 'Image=file:///usr/share/nostalgia/Nostalgia.png' "$home/.config/plasma-org.kde.plasma.desktop-appletsrc" 2>/dev/null; then
      warn "Verify: Wallpaper not set for $TARGET_USER"
      ok=0
    fi
    if [[ ! -L "$home/$STEAM_MOV_DIR_REL/deck_startup.webm" ]]; then
      warn "Verify: Steam startup video link missing"
      ok=0
    fi
  fi

  return $ok
}

# ===================== run once (+ retry) =====================
run_all(){
  ensure_flathub_and_arduino
  apply_wallpaper_for_user "$TARGET_USER"
  seed_steam_movies_for_user "$TARGET_USER"
}

log "Starting tasks…"
run_all

if ! verify; then
  warn "Verification failed; retrying once after short backoff…"
  sleep 5
  run_all
  if ! verify; then
    err "Verification failed after retry. Leaving system untouched for next boot/force run."
    exit 1
  fi
fi

# Success path: write done flag only when not forced or when we want to persist success
touch "$DONE_FLAG"
log "Completed successfully."
