#!/usr/bin/bash
set -euo pipefail

# Nostalgia OS First Boot Setup
# This script runs on first login to apply system-wide customizations and user preferences

STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/nostalgia"
MARKER_FILE="${STATE_DIR}/setup-complete"

# Skip if already run
if [[ -f "${MARKER_FILE}" ]]; then
    exit 0
fi

mkdir -p "${STATE_DIR}"

# Missing KDE tools must not produce a false setup-complete marker.
if ! command -v kwriteconfig6 >/dev/null 2>&1; then
    echo "KDE setup requires kwriteconfig6; retrying next desktop login" >&2
    exit 1
fi

echo "🎮 Nostalgia OS - First Boot Setup Starting..."

# ── KDE Plasma Configuration ───────────────────────────────────────────────────
echo "⚙️  Configuring KDE Plasma defaults..."

CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
mkdir -p "${CONFIG_DIR}"

# Enable animations and visual effects for nostalgia aesthetic
if command -v kwriteconfig6 >/dev/null 2>&1; then
    # Only select the custom scheme when it is actually installed.
    if [[ -f /usr/share/color-schemes/Nostalgia.colors ]]; then
        kwriteconfig6 --file "${CONFIG_DIR}/kdeglobals" \
            --group General \
            --key ColorScheme "Nostalgia"
    fi

    # Disable wallet prompts for better UX
    kwriteconfig6 --file "${CONFIG_DIR}/kwalletrc" \
        --group Wallet \
        --key Enabled false

    # Configure taskbar and panel
    kwriteconfig6 --file "${CONFIG_DIR}/plasmashellrc" \
        --group General \
        --key ShowToolTips true

    echo "✓ KDE Plasma configured"
fi

# ── Desktop shortcuts and applications menu ────────────────────────────────────
echo "📚 Setting up desktop applications..."

APPS_DIR="${CONFIG_DIR}/xdg-desktop-portal"
mkdir -p "${APPS_DIR}"

# Ensure common applications are available
COMMON_APPS=("firefox" "kwrite" "dolphin" "konsole")
for app in "${COMMON_APPS[@]}"; do
    if command -v "${app}" >/dev/null 2>&1; then
        echo "✓ ${app} is available"
    fi
done

# ── System preferences ─────────────────────────────────────────────────────────
echo "🔧 Applying system preferences..."

# Set a browser only when installed. Bazzite normally supplies Firefox as Flatpak.
BROWSER_DESKTOP=""
if [[ -f /usr/share/applications/firefox.desktop ]]; then
    BROWSER_DESKTOP="firefox.desktop"
elif command -v flatpak >/dev/null 2>&1 && flatpak info org.mozilla.firefox >/dev/null 2>&1; then
    BROWSER_DESKTOP="org.mozilla.firefox.desktop"
fi
if [[ -n "${BROWSER_DESKTOP}" ]]; then
    for scheme in http https; do
        kwriteconfig6 --file "${CONFIG_DIR}/mimeapps.list" \
            --group "Default Applications" \
            --key "x-scheme-handler/${scheme}" "${BROWSER_DESKTOP};"
    done
fi

kwriteconfig6 --file "${CONFIG_DIR}/mimeapps.list" \
    --group "Default Applications" \
    --key "text/plain" "org.kde.kwrite.desktop;"

# ── Ensure wallpaper is set ────────────────────────────────────────────────────
if [[ -f /usr/share/nostalgia/Nostalgia.png ]]; then
    echo "🎨 Wallpaper asset verified"
else
    echo "⚠️  Wallpaper not found at expected location"
fi

# ── Validate Arduino IDE ───────────────────────────────────────────────────────
# Arduino's independent installer/shortcut services also handle existing users.
if flatpak info --system cc.arduino.IDE2 >/dev/null 2>&1; then
    echo "Arduino IDE 2 is installed"
else
    echo "Arduino IDE 2 download is pending; see nostalgia-arduino-install.service"
fi

echo "📝 Recording setup completion..."
touch "${MARKER_FILE}"

echo ""
echo "✅ Nostalgia OS First Boot Setup Complete!"
echo "🎮 Welcome to Nostalgia OS - Enjoy your retro experience!"
echo ""
