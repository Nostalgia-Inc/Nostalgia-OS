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

echo "🎮 Nostalgia OS - First Boot Setup Starting..."

# ── KDE Plasma Configuration ───────────────────────────────────────────────────
echo "⚙️  Configuring KDE Plasma defaults..."

CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
mkdir -p "${CONFIG_DIR}"

# Enable animations and visual effects for nostalgia aesthetic
if command -v kwriteconfig6 >/dev/null 2>&1; then
    # KDE General settings
    kwriteconfig6 --file "${CONFIG_DIR}/kdeglobals" \
        --group General \
        --key ColorScheme "Nostalgia"

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
COMMON_APPS=("firefox" "kwrite" "dolphin" "konsole" "arduino")
for app in "${COMMON_APPS[@]}"; do
    if command -v "${app}" >/dev/null 2>&1; then
        echo "✓ ${app} is available"
    fi
done

# ── System preferences ─────────────────────────────────────────────────────────
echo "🔧 Applying system preferences..."

# Configure default terminals and text editors
kwriteconfig6 --file "${CONFIG_DIR}/mimeapps.list" \
    --group "Default Applications" \
    --key "x-scheme-handler/http" "firefox.desktop"

kwriteconfig6 --file "${CONFIG_DIR}/mimeapps.list" \
    --group "Default Applications" \
    --key "text/plain" "kwrite.desktop"

# ── Ensure wallpaper is set ────────────────────────────────────────────────────
if [[ -f /usr/share/nostalgia/Nostalgia.png ]]; then
    echo "🎨 Wallpaper asset verified"
else
    echo "⚠️  Wallpaper not found at expected location"
fi

# ── Validate Arduino IDE ───────────────────────────────────────────────────────
if command -v arduino >/dev/null 2>&1; then
    echo "✓ Arduino IDE installed and ready"
    # Create Arduino directory in home
    mkdir -p "${HOME}/.local/share/arduino"
else
    echo "⚠️  Arduino IDE not found - installation may have failed"
fi

# ── Create Desktop shortcuts ───────────────────────────────────────────────────
DESKTOP_DIR="${XDG_DESKTOP_DIR:-$HOME/Desktop}"
mkdir -p "${DESKTOP_DIR}"

# Arduino IDE shortcut
cat > "${DESKTOP_DIR}/Arduino.desktop" << 'EOF'
[Desktop Entry]
Type=Application
Name=Arduino IDE
Comment=Electronics development platform
Exec=arduino
Icon=arduino
Categories=Development;Electronics;
Terminal=false
EOF
chmod +x "${DESKTOP_DIR}/Arduino.desktop"

# ── Log completion ─────────────────────────────────────────────────────────────
echo "📝 Recording setup completion..."
touch "${MARKER_FILE}"

echo ""
echo "✅ Nostalgia OS First Boot Setup Complete!"
echo "🎮 Welcome to Nostalgia OS - Enjoy your retro experience!"
echo ""
