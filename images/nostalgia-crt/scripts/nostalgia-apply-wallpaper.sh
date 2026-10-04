#!/usr/bin/bash
set -euo pipefail

# Apply the default once through the running Plasma session. Editing its config
# on disk races with plasmashell, which owns and saves the desktop layout.
TARGET_IMAGE="file:///usr/share/nostalgia/Nostalgia.png"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/nostalgia"
MARKER_FILE="${STATE_DIR}/wallpaper-applied"
WAIT_SECONDS=60

# Preserve wallpaper choices after a successful first-login setup.
if [[ -f "${MARKER_FILE}" ]]; then
  exit 0
fi

if [[ ! -r /usr/share/nostalgia/Nostalgia.png ]]; then
  echo "Nostalgia wallpaper asset is missing or unreadable" >&2
  exit 1
fi

# Qt 6's D-Bus tool has different names/locations across distributions.
QDBUS=""
for candidate in qdbus6 qdbus-qt6 /usr/lib64/qt6/bin/qdbus /usr/lib/qt6/bin/qdbus qdbus; do
  if command -v "${candidate}" >/dev/null 2>&1; then
    QDBUS="${candidate}"
    break
  fi
done

if [[ -z "${QDBUS}" ]] || ! command -v timeout >/dev/null 2>&1; then
  echo "Nostalgia wallpaper requires qdbus (Qt 6) and timeout" >&2
  exit 1
fi

SCRIPT="
    var allDesktops = desktops();
    if (allDesktops.length === 0) {
      throw new Error('Plasma desktops are not ready');
    }
    for (var i = 0; i < allDesktops.length; ++i) {
      var desktop = allDesktops[i];
      desktop.wallpaperPlugin = 'org.kde.image';
      desktop.currentConfigGroup = ['Wallpaper', 'org.kde.image', 'General'];
      desktop.writeConfig('Image', '${TARGET_IMAGE}');
      desktop.writeConfig('PreviewImage', '${TARGET_IMAGE}');
      if (desktop.readConfig('Image') !== '${TARGET_IMAGE}') {
        throw new Error('Wallpaper configuration was not accepted');
      }
    }
    print('nostalgia-wallpaper-applied:' + allDesktops.length);
"

# The bus name can exist before Plasma has created any desktop containments.
# Retry connection failures and empty desktop lists, with bounded calls.
DEADLINE=$((SECONDS + WAIT_SECONDS))
RESULT=""
while (( SECONDS < DEADLINE )); do
  if RESULT=$(timeout 5s "${QDBUS}" org.kde.plasmashell /PlasmaShell \
    org.kde.PlasmaShell.evaluateScript "${SCRIPT}" 2>&1); then
    if [[ "${RESULT}" =~ ^nostalgia-wallpaper-applied:[1-9][0-9]*$ ]]; then
      mkdir -p "${STATE_DIR}"
      touch "${MARKER_FILE}"
      echo "Nostalgia wallpaper applied to the Plasma desktops"
      exit 0
    fi
  fi
  sleep 1
done

echo "Nostalgia wallpaper could not be applied; it will retry next desktop login: ${RESULT}" >&2
exit 1
