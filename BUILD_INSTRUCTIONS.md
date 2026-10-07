# Building and Testing Nostalgia OS

## Prerequisites

See [current validation results](REVIEW_NOTES.md) before treating a build as
release-ready. Use a Linux build host with the configured Btrfs filesystem
supported by its kernel. Windows/WSL validation needs additional tooling; see
the recorded builder limitations in the review.

Your system needs:
- `podman` (container runtime)
- `just` (task runner)
- `bootc-image-builder` (for creating bootable images)
- Substantially more than 30GB free for local testing: container layers,
  rootful copies, builder cache and disk artifacts coexist
- QEMU with KVM support (for testing)

## Building the Image

### Quick Build (Recommended for Testing)
```bash
# Build QCOW2 image suitable for QEMU testing
just rebuild-qcow2

# This will:
# 1. Build the container image with all customizations
# 2. Convert it to a bootable QCOW2 disk image
# 3. Place output in ./output/qcow2/disk.qcow2
```

### Other Build Types

The `build-*` disk recipes convert an existing container; `rebuild-*` also runs
the container build, using its normal layer cache.

```bash
# Build RAW image (for direct deployment)
just build-raw

# Build ISO (for USB installation)
just build-iso

# Rebuild the container and disk using the normal layer cache
just rebuild-qcow2
```

## Testing the Build

### Run in QEMU
```bash
# Automatically builds if needed, then runs in QEMU
just run-vm-qcow2

# The VM will:
# 1. Install the Nostalgia GRUB theme during first boot, for the following boot
# 2. Show Plymouth boot animation
# 3. Apply performance tuning
# 4. Prompt for login
```

### First Boot Testing Steps

1. **Login**
   - Username: `nostalgia`
   - Password: `nostalgia`

2. **Verify GRUB Theme** (after the first installed boot and a reboot)
   - Check if bootloader has green (#00ff00) text on black background
   - Title should say "Nostalgia OS"

3. **Verify Plymouth Theme**
   - Watch boot animation with Nostalgia branding

4. **Verify Wallpaper**
   - After login, desktop should show custom wallpaper
   - File: `common/branding/wallpaper.png`

5. **Verify Desktop Setup**
   - Arduino IDE downloads in the background; its shortcut appears after installation
   - KDE Plasma should be fully configured
   - No setup dialogs should appear on subsequent logins

6. **Verify Performance**
   - System should feel responsive
   - CPU frequency should scale dynamically
   - Check logs: `journalctl -u nostalgia-power-tuning.service`

7. **Verify Applications**
   - Arduino IDE should launch: `flatpak run cc.arduino.IDE2`
   - Install Arduino AVR Boards in the IDE before compiling for the LattePanda
   - Use [CRT_VALIDATION.md](CRT_VALIDATION.md) for service and serial-access checks
   - Firefox should work
   - Open terminal: `konsole`

## Troubleshooting

### Build Fails
```bash
# Inspect the actual failure before rebuilding
# The repository's cleanup recipe still needs a separate safety review.
# Rebuild with normal caching
just rebuild-qcow2

# Check for errors in build output
```

### Image Won't Boot
1. Check access to KVM on the build host: `ls -l /dev/kvm`
2. Check disk space: `df -h`
3. Verify image exists: `ls -lh output/qcow2/disk.qcow2`

### Services Not Running
```bash
# Run these commands in the installed system's desktop terminal

# Check service status
systemctl status nostalgia-power-tuning.service
systemctl --user status nostalgia-setup.service
journalctl -u nostalgia-power-tuning.service -n 20
journalctl --user -u nostalgia-setup.service -n 20
```

### Wallpaper Not Showing
1. Verify the installed asset: `ls /usr/share/nostalgia/Nostalgia.png`
2. Check the user service: `journalctl --user -u nostalgia-apply-wallpaper.service`
3. For an affected upgraded account, follow the marker-reset recovery steps in
   [REVIEW_NOTES.md](REVIEW_NOTES.md). These require the rebuilt image first.

## Building for Different Configurations

### For LattePanda Delta 3 (Current Target)
```bash
# Build the CRT container and disk; measure tuning on the physical board
just rebuild-qcow2
```

### For Different Hardware
Edit `images/nostalgia-crt/scripts/nostalgia-power-tuning.sh` to adjust:
- CPU governor settings
- Thermal-management service settings
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

1. **First Boot**: Run `just rebuild-qcow2 && just run-vm-qcow2`
2. **Verify**: Test all features per "First Boot Testing Steps"
3. **Iterate**: Make adjustments based on what you find
4. **Deploy**: Use ISO or RAW image for actual hardware
5. **Collaborate**: Share improvements via git commits

## Useful Commands

```bash
# Check Justfile syntax and formatting
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
