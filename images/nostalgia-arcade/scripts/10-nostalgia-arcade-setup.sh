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

# Missing KDE tools must not produce a false setup-complete marker.
if ! command -v kwriteconfig6 >/dev/null 2>&1; then
    echo "KDE setup requires kwriteconfig6; retrying next desktop login" >&2
    exit 1
fi

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
COMMON_APPS=("firefox" "kwrite" "dolphin" "konsole" "mpv")
for app in "${COMMON_APPS[@]}"; do
    if command -v "${app}" >/dev/null 2>&1; then
        echo "✓ ${app} available"
    fi
done

# ── System Preferences ─────────────────────────────────────────────────────────
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

# ── Create Desktop Shortcuts ───────────────────────────────────────────────────
echo "🎮 Creating desktop shortcuts..."

DESKTOP_DIR="$(xdg-user-dir DESKTOP)"
# Arduino's independent shortcut service handles its asynchronous installation.
if [[ -n "$DESKTOP_DIR" && "$DESKTOP_DIR" != "$HOME" ]]; then
mkdir -p "$DESKTOP_DIR"

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
fi

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
