#!/usr/bin/bash
set -euo pipefail

# Nostalgia Arcade: First Boot Setup
# Configures system for generic x86-64 hardware
# Runs on first user login

STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/nostalgia"
MARKER_FILE="${STATE_DIR}/arcade-setup-complete"

if [[ -f "${MARKER_FILE}" ]]; then
    exit 0
fi

mkdir -p "${STATE_DIR}"

echo "🎮 Nostalgia Arcade - First Boot Setup Starting..."

# ── KDE Plasma Configuration ───────────────────────────────────────────────────
echo "⚙️  Configuring KDE Plasma..."

CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
mkdir -p "${CONFIG_DIR}"

if command -v kwriteconfig6 >/dev/null 2>&1; then
    # Set arcade-themed color scheme
    kwriteconfig6 --file "${CONFIG_DIR}/kdeglobals" \
        --group General \
        --key ColorScheme "Breeze"

    # Disable wallet prompts
    kwriteconfig6 --file "${CONFIG_DIR}/kwalletrc" \
        --group Wallet \
        --key Enabled false

    # Configure taskbar
    kwriteconfig6 --file "${CONFIG_DIR}/plasmashellrc" \
        --group General \
        --key ShowToolTips true

    echo "✓ KDE Plasma configured"
fi

# ── Desktop Applications Setup ─────────────────────────────────────────────────
echo "📚 Setting up applications..."

APPS_DIR="${CONFIG_DIR}/xdg-desktop-portal"
mkdir -p "${APPS_DIR}"

# Verify key applications
COMMON_APPS=("firefox" "kwrite" "dolphin" "konsole" "arduino" "mpv")
for app in "${COMMON_APPS[@]}"; do
    if command -v "${app}" >/dev/null 2>&1; then
        echo "✓ ${app} available"
    fi
done

# ── System Preferences ─────────────────────────────────────────────────────────
echo "🔧 Applying system preferences..."

# Set default applications
kwriteconfig6 --file "${CONFIG_DIR}/mimeapps.list" \
    --group "Default Applications" \
    --key "x-scheme-handler/http" "firefox.desktop" 2>/dev/null || true

kwriteconfig6 --file "${CONFIG_DIR}/mimeapps.list" \
    --group "Default Applications" \
    --key "text/plain" "kwrite.desktop" 2>/dev/null || true

# ── Create Desktop Shortcuts ───────────────────────────────────────────────────
echo "🎮 Creating desktop shortcuts..."

DESKTOP_DIR="${XDG_DESKTOP_DIR:-$HOME/Desktop}"
mkdir -p "${DESKTOP_DIR}"

# Arduino shortcut
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

# Media player shortcut
cat > "${DESKTOP_DIR}/Media Player.desktop" << 'EOF'
[Desktop Entry]
Type=Application
Name=Media Player
Comment=Play multimedia files
Exec=mpv
Icon=media-player
Categories=AudioVideo;Player;
Terminal=false
EOF
chmod +x "${DESKTOP_DIR}/Media Player.desktop"

echo "✓ Desktop shortcuts created"

# ── Verify Wallpaper ───────────────────────────────────────────────────────────
echo "🎨 Checking wallpaper setup..."

if [[ -f /usr/share/nostalgia/Nostalgia.png ]]; then
    echo "✓ Wallpaper asset found"
else
    echo "⚠️  Wallpaper not found"
fi

# ── Log Completion ────────────────────────────────────────────────────────────
touch "${MARKER_FILE}"

echo ""
echo "✅ Nostalgia Arcade Setup Complete!"
echo "🎮 Ready for gaming and retro computing"
echo ""
