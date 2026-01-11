# Building and Testing Nostalgia OS

## Prerequisites

Your system needs:
- `podman` (container runtime)
- `just` (task runner)
- `bootc-image-builder` (for creating bootable images)
- At least 30GB free disk space for builds
- QEMU with KVM support (for testing)

## Building the Image

### Quick Build (Recommended for Testing)
```bash
# Build QCOW2 image suitable for QEMU testing
just build-qcow2

# This will:
# 1. Build the container image with all customizations
# 2. Convert it to a bootable QCOW2 disk image
# 3. Place output in ./output/qcow2/disk.qcow2
```

### Other Build Types
```bash
# Build RAW image (for direct deployment)
just build-raw

# Build ISO (for USB installation)
just build-iso

# Rebuild (clean rebuild, skipping cache)
just rebuild-qcow2
```

## Testing the Build

### Run in QEMU
```bash
# Automatically builds if needed, then runs in QEMU
just run-vm-qcow2

# The VM will:
# 1. Boot with Nostalgia GRUB theme (green text)
# 2. Show Plymouth boot animation
# 3. Apply performance tuning
# 4. Prompt for login
```

### First Boot Testing Steps

1. **Login**
   - Username: `nostalgia`
   - Password: `nostalgia`

2. **Verify GRUB Theme** (before login)
   - Check if bootloader has green (#00ff00) text on black background
   - Title should say "Nostalgia OS"

3. **Verify Plymouth Theme**
   - Watch boot animation with Nostalgia branding

4. **Verify Wallpaper**
   - After login, desktop should show custom wallpaper
   - File: `common/branding/wallpaper.png`

5. **Verify Desktop Setup**
   - Arduino IDE shortcut should exist on desktop
   - KDE Plasma should be fully configured
   - No setup dialogs should appear on subsequent logins

6. **Verify Performance**
   - System should feel responsive
   - CPU frequency should scale dynamically
   - Check logs: `journalctl -u nostalgia-power-tuning.service`

7. **Verify Applications**
   - Arduino IDE should launch: `arduino`
   - Firefox should work
   - Open terminal: `konsole`

## Troubleshooting

### Build Fails
```bash
# Clean build artifacts
just clean

# Try rebuilding
just rebuild-qcow2

# Check for errors in build output
```

### Image Won't Boot
1. Ensure QEMU has KVM support: `grep kvm /proc/cpuinfo`
2. Check disk space: `df -h`
3. Verify image exists: `ls -lh output/qcow2/disk.qcow2`

### Services Not Running
```bash
# SSH into running VM (if networking configured)
ssh -p 2222 nostalgia@localhost

# Check service status
systemctl status nostalgia-power-tuning.service
systemctl status nostalgia-setup.service
journalctl -u nostalgia-power-tuning.service -n 20
journalctl -u nostalgia-setup.service -n 20
```

### Wallpaper Not Showing
1. Verify wallpaper file exists: `ls common/branding/wallpaper.png`
2. Check wallpaper script ran: `journalctl -u nostalgia-apply-wallpaper.service`
3. Manually trigger: `/usr/libexec/nostalgia-apply-wallpaper`

## Building for Different Configurations

### For LattePanda Delta 3 (Current Target)
```bash
# Default build - optimized for LattePanda specs
just build-qcow2
```

### For Different Hardware
Edit `images/nostalgia-crt/scripts/nostalgia-power-tuning.sh` to adjust:
- CPU governor settings
- Thermal limits
- I/O scheduler preferences

## Verifying Build Success

The build is successful when:
- ✅ Container image builds without errors
- ✅ Bootc-image-builder completes
- ✅ QCOW2/ISO file is created (>3GB)
- ✅ QEMU VM boots successfully
- ✅ GRUB theme appears
- ✅ Plymouth animation plays
- ✅ Can login with `nostalgia:nostalgia`
- ✅ Desktop shows wallpaper
- ✅ Arduino IDE shortcut exists

## Next Steps

1. **First Boot**: Run `just build-qcow2 && just run-vm-qcow2`
2. **Verify**: Test all features per "First Boot Testing Steps"
3. **Iterate**: Make adjustments based on what you find
4. **Deploy**: Use ISO or RAW image for actual hardware
5. **Collaborate**: Share improvements via git commits

## Useful Commands

```bash
# Check Containerfile syntax
just check

# Fix formatting
just fix

# Lint shell scripts
just lint

# Format shell scripts
just format

# List all available tasks
just --list

# Run specific task with parameters
just build localhost/nostalgia custom-tag
```

## Environment Variables

Control builds with environment variables:
```bash
# Custom image name (default: NostalgiaOS)
IMAGE_NAME=MyNostalgiaOS just build-qcow2

# Custom tag (default: latest)
DEFAULT_TAG=v1.0 just build-qcow2

# Custom bootc-image-builder image
BIB_IMAGE=quay.io/custom/bootc-image-builder:tag just build-qcow2
```

## File Locations

- **Source Files**: `images/nostalgia-crt/`
- **Build Output**: `output/` (created during build)
- **Disk Config**: `disk_config/disk.toml` and `iso.toml`
- **Common Assets**: `common/branding/`

## Performance Notes

The power tuning script optimizes for:
- **Intel Celeron N5105** (LattePanda CPU)
- Dynamic frequency scaling (not max performance)
- Balanced power/performance
- Thermal efficiency

Adjust in `nostalgia-power-tuning.sh` if needed for different hardware.

## Support

For issues:
1. Check `IMPLEMENTATION_SUMMARY.md` for feature overview
2. Review service logs: `journalctl -xe`
3. Check systemd service files in `images/nostalgia-crt/systemd/`
4. Review script outputs in service status

Happy building! 🎮
