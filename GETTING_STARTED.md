# Getting Started with Nostalgia OS

Welcome to Nostalgia OS! This guide will help you get up and running.

## 📋 What You Need

### For Building the OS

**Operating System**: Linux (macOS and Windows can't run native Linux containers)
- Ubuntu 20.04+
- Fedora 38+
- Debian 12+
- Any Linux distro with container support

**Software Requirements**:
- `podman` - Container runtime
- `just` - Command runner (like Make)
- `qemu-system-x86_64` - Virtual machine (for testing)
- Minimum 30GB free disk space

**Install on Ubuntu/Debian**:
```bash
sudo apt update
sudo apt install -y podman just qemu-system-x86-64
```

**Install on Fedora/RHEL**:
```bash
sudo dnf install -y podman just qemu-system-x86-64
```

### For Deployment (Physical Hardware)

- LattePanda Delta 3 (for Nostalgia CRT)
- x86-64 compatible computer (for Nostalgia Arcade)
- USB drive (minimum 8GB for ISO)
- External drive or NAS for storage

## 🚀 Quick Start

### 1. Clone the Repository

```bash
git clone https://github.com/Nostalgia-Inc/Nostalgia-OS.git
cd Nostalgia-OS
```

### 2. Build the OS

**Build QCOW2 Image** (for QEMU testing):
```bash
just build-qcow2
```

**Build ISO Image** (for USB installation):
```bash
just build-iso
```

**Build RAW Image** (for direct deployment):
```bash
just build-raw
```

### 3. Test the Build

**Run in QEMU**:
```bash
just run-vm-qcow2
```

QEMU will start, and you can login with:
- Username: `nostalgia`
- Password: `nostalgia`

## ✨ First Boot Experience

### What Happens on First Boot

1. **GRUB Bootloader** - Green retro-styled menu appears
2. **Plymouth Animation** - Custom boot splash plays
3. **System Optimization** - Performance tuning runs silently
4. **Login Prompt** - Enter your credentials

### What Happens on First Login

1. **KDE Plasma Desktop** loads
2. **First Boot Setup** runs automatically:
   - Sets default applications
   - Applies wallpaper
   - Creates shortcuts
   - Configures preferences
3. **All Customizations** are applied

**Note**: Setup only runs once. Subsequent logins are normal.

## 🎮 Using Nostalgia OS

### Available Applications

**Pre-installed**:
- **Arduino IDE** - Electronics programming
- **Firefox** - Web browser
- **KDE Plasma** - Desktop environment
- **Dolphin** - File manager
- **KWrite** - Text editor
- **Konsole** - Terminal
- **MPV** - Media player
- **Podman** - Container runtime

### Common Tasks

**Open Terminal**:
- Right-click on desktop → "Open Terminal Here"
- Or press: `Ctrl+Alt+T`

**Install Software**:
```bash
# Install a package
sudo dnf install package-name

# Update system
sudo rpm-ostree upgrade
```

**Run Arduino IDE**:
- Look for Arduino icon on desktop, or:
```bash
arduino
```

**Change Wallpaper**:
- Right-click desktop → "Configure Desktop" → "Wallpaper"

**Access System Settings**:
- Click application menu → Settings
- Or search for "System Settings"

## 🔧 Customization

### Change Default User

Edit `images/nostalgia-crt/image.yml`:
```yaml
default-user:
  name: your-username
  password: your-password
  groups:
    - wheel
    - audio
    - video
```

### Add More Software

Edit `build_files/build.sh`:
```bash
# Add packages to install
dnf install -y my-package another-package
```

### Modify Performance Tuning

Edit `images/nostalgia-crt/scripts/nostalgia-power-tuning.sh`:
- CPU governor
- Turbo Boost settings
- I/O scheduler
- Thermal thresholds

### Custom Wallpaper

Replace `common/branding/wallpaper.png` with your image (PNG format recommended).

## 📚 Documentation

| Document | Purpose |
|----------|---------|
| **README.md** | Project overview |
| **BUILD_INSTRUCTIONS.md** | Detailed build guide |
| **IMPLEMENTATION_SUMMARY.md** | Technical overview |
| **ROADMAP.md** | Future plans |
| **CONTRIBUTING.md** | How to contribute |
| **CHANGES.md** | What was built |

## ⚠️ Troubleshooting

### Build Fails

**Problem**: `podman: command not found`
```bash
# Install podman
sudo apt install -y podman  # Debian/Ubuntu
sudo dnf install -y podman  # Fedora
```

**Problem**: Build hangs or times out
```bash
# Try again, increase timeout
timeout 7200 just build-qcow2

# Or clean and rebuild
just clean
just build-qcow2
```

**Problem**: Not enough disk space
```bash
# Check space
df -h

# Clean previous builds
just clean
```

### Boot Issues

**Problem**: System won't boot
- Verify 30GB+ free disk space
- Ensure QEMU/KVM is installed
- Check system logs: `journalctl -xe`

**Problem**: GRUB theme doesn't appear
- Might be hidden, but still there
- Check boot messages

**Problem**: Plymouth animation missing
- Still boots normally
- Check if assets are copied correctly

### First Boot Setup Doesn't Run

**Check logs**:
```bash
journalctl -u nostalgia-setup.service
journalctl -u nostalgia-apply-wallpaper.service
```

**Manually trigger** (if needed):
```bash
/usr/libexec/nostalgia-setup
/usr/libexec/nostalgia-apply-wallpaper
```

## 🆘 Getting Help

### Online Resources
- [KDE Plasma Documentation](https://docs.kde.org/)
- [Fedora Documentation](https://docs.fedoraproject.org/)
- [OStree Documentation](https://ostreedev.github.io/ostree/)

### Community Help
- **GitHub Issues**: Report bugs and ask questions
- **GitHub Discussions**: General questions and ideas
- **Email**: Contact maintainers

### Before Asking for Help

1. **Check logs**:
   ```bash
   journalctl -xe
   dmesg | tail -50
   ```

2. **Provide details**:
   - OS and version
   - Hardware specs
   - Error messages (full logs)
   - Steps to reproduce

3. **Search existing issues**:
   - Someone might have had same problem
   - Solution might be documented

## 📖 Useful Commands

### Build Commands

```bash
just --list              # See all available commands
just check               # Check syntax
just lint                # Lint shell scripts
just format              # Format shell scripts
just build-qcow2         # Build QCOW2 image
just build-iso           # Build ISO image
just build-raw           # Build RAW image
just rebuild-qcow2       # Clean rebuild
just run-vm-qcow2        # Run in QEMU
just clean               # Clean build artifacts
```

### System Commands

```bash
# Check systemd services
systemctl status nostalgia-power-tuning.service
systemctl status nostalgia-setup.service

# View service logs
journalctl -u nostalgia-power-tuning.service
journalctl -u nostalgia-setup.service

# Check disk usage
du -sh output/

# Verify image
ls -lh output/qcow2/disk.qcow2
```

## 🎯 Next Steps

1. **Build the OS**: `just build-qcow2`
2. **Test it**: `just run-vm-qcow2`
3. **Explore**: Log in and check out features
4. **Customize**: Modify wallpaper, software, settings
5. **Share feedback**: Report issues or suggest improvements

## 🤝 Contributing

Want to help improve Nostalgia OS?

- **Documentation**: Fix typos, improve guides
- **Testing**: Test on different hardware
- **Coding**: Add features, fix bugs
- **Design**: Create wallpapers, themes

See [CONTRIBUTING.md](CONTRIBUTING.md) for details.

## 📝 FAQ

**Q: Can I run this on macOS?**
A: You can prepare the files on macOS, but must build on Linux.

**Q: Can I use this on a Raspberry Pi?**
A: Not yet. Currently x86-64 only. ARM support is planned for future versions.

**Q: How do I update the system?**
A: `sudo rpm-ostree upgrade` to get latest updates.

**Q: Can I install my own software?**
A: Yes, use `dnf install package-name` or add to `build.sh` for inclusion in image.

**Q: How do I deploy to real hardware?**
A: Use ISO image on USB, or RAW image for direct disk installation.

**Q: Is this distribution stable?**
A: It's based on Fedora (stable distribution). Our customizations are tested but relatively new.

**Q: Can I contribute?**
A: Yes! See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## 🎮 Have Fun!

Nostalgia OS is designed to bring back the joy of retro computing while using modern, reliable Linux. Enjoy exploring, customizing, and creating!

If you have questions, suggestions, or just want to share what you've built, reach out to the community!

---

**Happy computing! 🚀**
