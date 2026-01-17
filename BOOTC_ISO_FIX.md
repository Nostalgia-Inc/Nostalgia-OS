# Fix for "System not booted via bootc" Installation Error

## Problem
When installing Nostalgia OS from the ISO image, Anaconda installer fails with:
```
ScriptError: error: Switching: Initializing storage: System not booted via bootc
```

## Root Cause
Your OS is built as a **bootc container image** using `bootc-image-builder`. When converted to an ISO, Anaconda's Runtime module attempts to perform bootc-specific operations (like `bootc switch`), but the installation environment hasn't been booted via bootc - it's running in a traditional live installer environment.

## Solution Applied
Disabled the Anaconda Runtime module in `disk_config/iso.toml`:

```toml
[customizations.installer.modules]
disable = [
  "org.fedoraproject.Anaconda.Modules.Network",
  "org.fedoraproject.Anaconda.Modules.Security",
  "org.fedoraproject.Anaconda.Modules.Subscription",
  "org.fedoraproject.Anaconda.Modules.Runtime"  # ← Added this
]
```

## Why This Works
- The **Runtime module** in Anaconda handles bootc-specific switching operations
- Disabling it prevents bootc initialization checks during installation
- The underlying ostree deployment still works correctly
- Your container-based OS features remain intact after installation

## Next Steps

### 1. Rebuild the ISO
```powershell
just rebuild-iso
```

### 2. Test the Installation
- Boot from the new ISO
- Installation should complete without the bootc error
- After installation, your system will have all customizations:
  - Nostalgia GRUB theme
  - Plymouth boot animation
  - Custom wallpaper
  - Arduino IDE
  - Default user `nostalgia`

### 3. Verify After Installation
Once installed and booted:
```bash
# Check ostree deployment
rpm-ostree status

# Verify services
systemctl status nostalgia-power-tuning.service
systemctl --user status nostalgia-setup.service

# Check customizations
ls /usr/share/nostalgia/
```

## Alternative: Use QCOW2 Instead of ISO
If you're deploying to VMs, QCOW2 images work better with bootc:
```powershell
just build-qcow2
just run-vm-qcow2
```

## Alternative: Use RAW for Physical Hardware
For direct hardware deployment:
```powershell
just build-raw
# Then dd the raw image to a USB or disk
```

## Technical Background
- **bootc** = Boot Container technology for container-native OS
- **Anaconda** = Fedora/Red Hat installer
- **ostree** = Git-like filesystem for atomic updates
- Your OS uses ostree (via bootc-image-builder) but installs via Anaconda
- This creates a mismatch that the Runtime module fix resolves

## References
- Bootc-image-builder: https://github.com/osbuild/bootc-image-builder
- Universal Blue (your base): https://universal-blue.org/
- Bazzite (your upstream): https://bazzite.gg/

## Summary
The fix allows your bootc-based container OS to install via traditional ISO while preserving all the benefits of container-based system management.
