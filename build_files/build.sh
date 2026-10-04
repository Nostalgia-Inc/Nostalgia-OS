#!/bin/bash

set -euo pipefail

# Nostalgia OS: Package installation and system setup
# Runs during container image build
# Purpose: Install required packages and enable system services

echo "🔧 Nostalgia OS: Starting package installation..."

# Error handling
trap 'echo "❌ Error in build.sh at line $LINENO"; exit 1' ERR
set -E

echo "📦 Installing core packages..."

# Install tmux - terminal multiplexer
echo "  Installing: tmux"
rpm-ostree install --idempotent tmux plymouth-plugin-script mpv

# Arduino IDE 2 is installed system-wide by nostalgia-arduino-install.service.
# Required packages must fail the build when unavailable.

echo "✅ Package installation complete"

# Enable system services
echo "⚙️  Enabling system services..."
echo "  Enabling: podman.socket"
systemctl enable podman.socket

echo "✅ System configuration complete"
echo "🎉 Build script finished successfully!"
