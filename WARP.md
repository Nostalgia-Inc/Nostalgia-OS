# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Commands

### Build Commands
```bash
# Build bootable QCOW2 image (for QEMU testing)
just build-qcow2

# Build ISO image (for USB installation)
just build-iso

# Build RAW disk image (for direct deployment)
just build-raw

# Clean rebuild (skip cache)
just rebuild-qcow2
```

### Testing Commands
```bash
# Run VM in QEMU (auto-builds if needed)
just run-vm-qcow2

# Run from ISO
just run-vm-iso

# Run from RAW image
just run-vm-raw
```

### Development Commands
```bash
# Lint all shell scripts with shellcheck
just lint

# Format all shell scripts with shfmt
just format

# Check Justfile syntax
just check

# Fix Justfile formatting
just fix

# Clean build artifacts
just clean

# List all available commands
just --list
```

### Testing First Boot
After running `just run-vm-qcow2`, login credentials are:
- Username: `nostalgia`
- Password: `nostalgia`

Verify these on first boot:
- GRUB theme (green text on black)
- Plymouth boot animation
- Wallpaper displays on desktop
- Arduino IDE shortcut exists on desktop
- Performance tuning active: `journalctl -u nostalgia-power-tuning.service`
- First boot setup ran: `journalctl -u nostalgia-setup.service`

### Single Test Development
When testing a single script:
```bash
# Build the container image only (no bootc conversion)
just build localhost/NostalgiaOS latest

# Then use podman to run/test inside container
podman run -it localhost/NostalgiaOS:latest /bin/bash
```

## Architecture Overview

### Build System Architecture
Nostalgia OS uses a **layered bootc-based container build** approach:

1. **Base Image**: Bazzite-Deck (Fedora Atomic with KDE Plasma)
2. **Container Layer**: Custom packages and configurations added via Containerfile
3. **Bootc Conversion**: `bootc-image-builder` converts container → bootable disk image
4. **Task Runner**: `just` orchestrates all build commands

### Directory Structure
```
images/
├── nostalgia-crt/          # LattePanda Delta 3 optimized image
│   ├── Containerfile       # Container build instructions
│   ├── scripts/            # Runtime automation scripts
│   │   ├── 10-nostalgia-setup.sh          # First-login user setup
│   │   ├── nostalgia-power-tuning.sh      # Boot-time performance tuning
│   │   └── nostalgia-apply-wallpaper.sh   # Wallpaper application
│   ├── systemd/            # Systemd service units
│   ├── grub/               # GRUB bootloader theme
│   └── plymouth/           # Boot animation theme
├── nostalgia-arcade/       # Generic x86-64 image (planned)

build_files/
└── build.sh               # Package installation script (runs during image build)

common/
└── branding/              # Shared assets (wallpaper, logos)

disk_config/
├── disk.toml              # QCOW2/RAW disk layout config
└── iso.toml               # ISO installer config
```

### Boot Sequence & Service Execution
Understanding the boot flow is critical when debugging or adding features:

```
1. GRUB (bootloader) → Displays custom green retro theme
2. Plymouth → Shows Nostalgia boot animation
3. systemd boots multi-user.target
   └── nostalgia-power-tuning.service (system-level)
       └── Runs /usr/libexec/nostalgia-power-tuning
           └── CPU governor, I/O scheduler, network tuning, etc.
4. User logs in → graphical.target
   └── nostalgia-setup.service (user-level, first login only)
       └── Runs /usr/libexec/nostalgia-setup
           └── KDE Plasma config, desktop shortcuts, default apps
   └── nostalgia-apply-wallpaper.service (user-level)
       └── Runs /usr/libexec/nostalgia-apply-wallpaper
           └── Sets wallpaper from /usr/share/nostalgia/Nostalgia.png
```

**Key points:**
- `nostalgia-power-tuning.service` is **system-level** (runs at boot, as root)
- `nostalgia-setup.service` is **user-level** (runs after first login, per user)
- `nostalgia-apply-wallpaper.service` is **user-level** (runs after login)
- First-boot scripts use state markers (`~/.local/state/nostalgia/setup-complete`) to run only once

### Containerfile Layers
The build happens in stages within `images/nostalgia-crt/Containerfile`:

1. **Base**: Start from `bazzite-deck` image
2. **GPG Fix**: Disable GPG checks for terra repos (bootc-image-builder compatibility)
3. **Package Installation**: Run `build_files/build.sh` to install Arduino IDE, tmux, etc.
4. **Branding**: Copy `common/` assets to `/usr/share/nostalgia/`
5. **Plymouth**: Install boot theme to `/usr/share/plymouth/themes/nostalgia`
6. **Wallpaper**: Configure KDE default via `/etc/skel/.config/`
7. **Scripts**: Copy automation scripts to `/usr/libexec/`
8. **Services**: Install systemd units and enable them
9. **GRUB**: Copy custom theme to `/usr/share/grub/themes/`
10. **Media**: Copy Steam Deck style intro/outro videos

Each layer ends with `ostree container commit` to persist changes.

### Hardware-Specific Tuning
The system is currently optimized for **LattePanda Delta 3**:
- Intel Celeron N5105 CPU
- LPDDR4 8GB RAM
- 64GB eMMC storage
- Intel UHD Graphics

`nostalgia-power-tuning.sh` contains LattePanda-specific settings:
- `schedutil` CPU governor for dynamic frequency scaling
- Intel Turbo Boost enabled
- `mq-deadline` I/O scheduler
- USB autosuspend disabled
- Disables bluetooth, cups, avahi

When adding support for new hardware, modify or create hardware detection logic in this script.

## Key Technical Decisions

### Why bootc-image-builder?
- Creates **immutable, atomic OS images** from containers
- Based on Fedora's rpm-ostree system (same as Fedora Silverblue/Kinoite)
- Allows testing in containers before deploying as bootable image
- Simplifies updates: just rebuild container and deploy

### Why Bazzite-Deck Base?
- Pre-configured KDE Plasma desktop environment
- Gaming-focused optimizations already included
- Steam Deck compatibility layer
- Strong community support

### Why User-Level Services?
First-boot setup runs as user-level services because:
- KDE Plasma config requires user context (`kwriteconfig6`)
- Desktop shortcuts belong in user's home directory
- Wallpaper preferences are per-user
- Avoids permission issues with `$HOME` access

System-level tuning (CPU, I/O) runs as root service because it requires privileged access.

## Development Workflows

### Adding New Packages
1. Edit `build_files/build.sh`
2. Add `rpm-ostree install package-name`
3. Rebuild: `just rebuild-qcow2`

### Adding New Boot-Time Scripts
1. Create script in `images/nostalgia-crt/scripts/`
2. Create systemd service in `images/nostalgia-crt/systemd/`
3. Add to `Containerfile`:
   ```dockerfile
   COPY images/nostalgia-crt/scripts/myscript.sh /usr/libexec/myscript
   COPY images/nostalgia-crt/systemd/myscript.service /usr/lib/systemd/system/myscript.service
   RUN set -eux; \
       chmod 0755 /usr/libexec/myscript; \
       systemctl enable myscript.service; \
       ostree container commit
   ```

### Modifying Hardware Tuning
Edit `images/nostalgia-crt/scripts/nostalgia-power-tuning.sh`:
- CPU governor: Line ~17 (`cpupower frequency-set --governor`)
- Turbo Boost: Line ~34 (`/sys/devices/system/cpu/intel_pstate/no_turbo`)
- I/O scheduler: Line ~44 (`mq-deadline`)
- Services to disable: Line 115-119 array

### Debugging Build Failures
```bash
# View build logs during build
just build-qcow2 2>&1 | tee build.log

# If GPG errors occur, check terra repo GPG configuration in Containerfile

# If ostree commit fails, verify each RUN command ends with:
# && ostree container commit
```

### Debugging Runtime Issues
Once booted in QEMU:
```bash
# Check power tuning
journalctl -u nostalgia-power-tuning.service

# Check first-boot setup
journalctl -u nostalgia-setup.service

# Check wallpaper application
journalctl -u nostalgia-apply-wallpaper.service

# View all boot logs
journalctl -b

# Check if state marker exists (setup should only run once)
ls -la ~/.local/state/nostalgia/
```

## Environment Variables

Control build behavior:
```bash
# Custom image name (default: NostalgiaOS)
IMAGE_NAME=MyNostalgiaOS just build-qcow2

# Custom tag (default: latest)
DEFAULT_TAG=v1.0 just build-qcow2

# Custom bootc-image-builder version
BIB_IMAGE=quay.io/custom/bootc-image-builder:tag just build-qcow2
```

## Important Notes for AI Agents

### Shell Script Standards
- All scripts MUST start with `set -euo pipefail` for proper error handling
- Use `[[ ]]` for conditionals, not `[ ]`
- Quote all variables: `"${var}"` not `$var`
- Use emoji for clarity in echo statements (🔧 ✅ ⚠️)
- Check command availability before use: `command -v cmd >/dev/null 2>&1`
- Gracefully handle missing tools: `|| true` or `|| echo "warning"`

### Containerfile Standards
- Each significant RUN block must end with `&& ostree container commit`
- Use `set -eux;` at start of multi-line RUN commands
- Minimize layers by combining related commands with `&&`
- Always `chmod +x` scripts before enabling services

### Systemd Service Standards
- System services: `/usr/lib/systemd/system/`
- User services: `/usr/lib/systemd/user/`
- Enable system services: `systemctl enable`
- Enable user services: `systemctl --global enable`
- Scripts go in `/usr/libexec/` not `/usr/local/bin/`

### State Management
First-boot scripts must use state markers to prevent re-running:
```bash
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/nostalgia"
MARKER_FILE="${STATE_DIR}/setup-complete"

if [[ -f "${MARKER_FILE}" ]]; then
    exit 0
fi

# ... do work ...

touch "${MARKER_FILE}"
```

### Testing Before Committing
1. Run `just lint` to check shell scripts
2. Run `just format` to format shell scripts
3. Run `just check` to validate Justfile syntax
4. Build and test: `just build-qcow2 && just run-vm-qcow2`
5. Verify all features work per BUILD_INSTRUCTIONS.md checklist

## Project Context

### Current Status
- **Nostalgia CRT**: ✅ Complete (LattePanda Delta 3 optimized)
- **Nostalgia Arcade**: 🚧 Planned (generic x86-64)

### Base Technology Stack
- **OS Base**: Fedora Atomic (via Bazzite)
- **Desktop**: KDE Plasma 6
- **Package Manager**: rpm-ostree
- **Container Runtime**: Podman
- **Build Tool**: bootc-image-builder
- **Task Runner**: just

### Contributing Guidelines
See CONTRIBUTING.md for:
- Code style standards
- Commit message format
- Testing requirements
- PR submission process
