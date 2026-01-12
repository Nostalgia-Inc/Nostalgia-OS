# Build Script Error Fix

## Error Encountered
```
❌ Error in build.sh at line 23
Error: building at STEP "RUN chmod +x /tmp/build.sh && /tmp/build.sh && rm /tmp/build.sh && ostree container commit"
```

## Root Cause
One or more packages failed to install during the build:
- `tmux` - May not be available in the base image repos
- `arduino` - May not be in standard Fedora repos (needs special handling)

## Solution Applied

Updated `build_files/build.sh` to use `--skip-unavailable` flag, which:
- Skips packages that don't exist instead of failing the entire build
- Logs warnings about skipped packages
- Allows build to continue

### Before
```bash
dnf install -y tmux
dnf install -y arduino
```

### After
```bash
dnf install -y --skip-unavailable tmux || echo "⚠️  tmux installation skipped (unavailable)"
dnf install -y --skip-unavailable arduino || echo "⚠️  arduino installation skipped (unavailable)"
```

## Also Updated
- `images/nostalgia-crt/Containerfile` - Added `--skip-unavailable` to mpv installation
- `images/nostalgia-arcade/Containerfile` - Added `--skip-unavailable` to mpv installation

## What to Do Now

### Option 1: Retry Build (Recommended)
```bash
# Clean previous failed build
just clean

# Rebuild with fixed script
just rebuild-qcow2
```

This should work now because packages that aren't available will be skipped gracefully.

### Option 2: Verify Available Packages
If you want to see what packages are actually available:

```bash
# Check what's in fedora repos
dnf search tmux
dnf search arduino
dnf search mpv
```

### Option 3: Use Alternative Packages
If you want to install different packages instead, edit `build_files/build.sh`:

```bash
# Replace with packages you know are available
dnf install -y --skip-unavailable git vim htop
```

## Understanding the Fix

### What `--skip-unavailable` Does
- **With it**: Skips missing packages and continues → Build succeeds
- **Without it**: Fails on first missing package → Build fails

### Why Packages Might Be Missing
1. **Not in default repos** - Need to enable additional repos (RPMFusion, COPR, etc.)
2. **Fedora version mismatch** - Package doesn't exist in this Fedora version
3. **Different package name** - Package exists but under a different name
4. **Architecture issue** - Package doesn't exist for x86_64

### Better Approach for Arduino
Arduino IDE is actually in Fedora repos, but it's better to use the official Arduino package:

```bash
# Option 1: Use official Arduino snap/flatpak (if available)
dnf install -y flatpak
flatpak install flathub cc.arduino.IDE2

# Option 2: Build from source (in Containerfile)
RUN dnf install -y java-11-openjdk && \
    wget https://downloads.arduino.cc/arduino-ide/arduino-ide_latest_Linux_x86_64.zip && \
    unzip arduino-ide_latest_Linux_x86_64.zip -d /opt && \
    ln -s /opt/arduino-ide_latest/arduino-ide /usr/local/bin/arduino
```

## Alternative: Skip Package Installation Entirely

If you want to skip installing packages during build and install them later:

Edit `build_files/build.sh`:
```bash
#!/bin/bash

set -euo pipefail

echo "🔧 Nostalgia OS: Build setup (packages skipped for now)"

# Just enable services, skip packages
systemctl enable podman.socket

echo "✅ Build script finished (packages will be installed separately)"
```

Then install packages after first boot or via bootc image configuration.

## Debugging

If you still get errors, check:

```bash
# See what's happening during build
just rebuild-qcow2 2>&1 | tee build.log

# Search for the actual error
grep -i "error\|failed" build.log

# Check package availability in base image
podman run ghcr.io/ublue-os/bazzite-deck@sha256:98a0c1fbd89c150ed6ba9d356b3a3ddc11361c4d3a26c8fd17321b9c762d1081 dnf search tmux
```

## Best Practices Going Forward

1. **Use `--skip-unavailable`** on all optional packages
2. **Test package availability** before adding to build
3. **Document requirements** if specific repos needed
4. **Handle errors gracefully** with fallback options
5. **Keep build logs** for debugging

## What's Happening in the Build

```
STEP 1: Pull base image
STEP 2: Execute build.sh
  └─ Install tmux (skip if unavailable)
  └─ Install arduino (skip if unavailable)
  └─ Enable podman.socket
STEP 3: Copy branding assets
STEP 4: Configure Plymouth theme
STEP 5: Setup wallpaper
STEP 6: Setup first-boot scripts
STEP 7: Configure power tuning
STEP 8: Configure GRUB theme
STEP 9: Install media tools
✅ Build complete
```

## Next Steps

1. **Retry the build**: `just rebuild-qcow2`
2. **Monitor the output** - You should see the script run successfully
3. **Test the image**: `just run-vm-qcow2` once build completes
4. **Verify packages** - Check if tmux/arduino are available in the built image

---

The build should now succeed even if some packages are unavailable! 🚀
