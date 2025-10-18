#!/usr/bin/bash
set -euo pipefail

TARGET_IMAGE="file:///usr/share/nostalgia/Nostalgia.png"
CONFIG_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/plasma-org.kde.plasma.desktop-appletsrc"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/nostalgia"
MARKER_FILE="${STATE_DIR}/wallpaper-applied"
WAIT_SECONDS=15

# Exit early if the wallpaper asset is missing or we've already applied it.
if [[ ! -f /usr/share/nostalgia/Nostalgia.png ]]; then
  exit 0
fi

if [[ -f "${MARKER_FILE}" ]]; then
  exit 0
fi

mkdir -p "$(dirname "${MARKER_FILE}")"

# Give Plasma a moment on the first login to create its config skeleton.
for _ in $(seq 1 "${WAIT_SECONDS}"); do
  if [[ -f "${CONFIG_FILE}" ]]; then
    break
  fi
  sleep 1
done

if [[ ! -f "${CONFIG_FILE}" ]]; then
  mkdir -p "$(dirname "${CONFIG_FILE}")"
  : > "${CONFIG_FILE}"
fi

if ! command -v kwriteconfig6 >/dev/null 2>&1; then
  exit 0
fi

mapfile -t DESKTOP_CONTAINMENTS < <(
  awk '
    /^\[Containments\]\[[0-9]+\]$/ {
      match($0, /\[Containments\]\[([0-9]+)\]/, arr);
      current=arr[1];
      next;
    }
    /^\[Containments\]\[[0-9]+\]\[/ { next }
    /^plugin=/{ 
      if (current != "" && $0 ~ /org\.kde\.plasma\.folder$/) {
        print current;
      }
    }
  ' "${CONFIG_FILE}" | sort -u
)

# Fall back to the primary containment if Plasma has not populated the file yet.
if [[ ${#DESKTOP_CONTAINMENTS[@]} -eq 0 ]]; then
  DESKTOP_CONTAINMENTS=(1)
fi

for containment_id in "${DESKTOP_CONTAINMENTS[@]}"; do
  kwriteconfig6 --file "${CONFIG_FILE}" \
    --group Containments --group "${containment_id}" \
    --group Wallpaper --group org.kde.image --group General \
    --key Image "${TARGET_IMAGE}"

  kwriteconfig6 --file "${CONFIG_FILE}" \
    --group Containments --group "${containment_id}" \
    --group Wallpaper --group org.kde.image --group General \
    --key PreviewImage "${TARGET_IMAGE}"
done

# Ask plasmashell to refresh the wallpaper immediately if we can.
if command -v qdbus >/dev/null 2>&1; then
  qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "
    var desktops = desktops();
    for (var i = 0; i < desktops.length; ++i) {
      var d = desktops[i];
      d.wallpaperPlugin = 'org.kde.image';
      d.currentConfigGroup = ['Wallpaper', 'org.kde.image', 'General'];
      d.writeConfig('Image', '${TARGET_IMAGE}');
      d.writeConfig('PreviewImage', '${TARGET_IMAGE}');
    }
  " || true
fi

touch "${MARKER_FILE}"
