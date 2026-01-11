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
dnf install -y --skip-unavailable tmux || echo "⚠️  tmux installation skipped (unavailable)"

# Install arduino - electronics development platform
echo "  Installing: arduino"
dnf install -y --skip-unavailable arduino || echo "⚠️  arduino installation skipped (unavailable)"

echo "✅ Package installation complete"

# Enable system services
echo "⚙️  Enabling system services..."
echo "  Enabling: podman.socket"
systemctl enable podman.socket

echo "✅ System configuration complete"
echo "🎉 Build script finished successfully!"
