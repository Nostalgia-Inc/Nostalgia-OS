# Nostalgia OS: Development Roadmap

## Current Status: MVP Complete ✅
All core first-boot customizations are implemented and integrated. Below are prioritized areas for enhancement.

---

## 🔴 HIGH PRIORITY (Immediate/Essential)

### 1. **Nostalgia Arcade Image Implementation**
**Status**: Mentioned in README but not started  
**Impact**: Core project goal - multi-system support  
**Effort**: Medium (2-3 days)

Currently only Nostalgia CRT exists. Need to create:
- `images/nostalgia-arcade/Containerfile` - Generic hardware variant
- `images/nostalgia-arcade/image.yml` - Standard desktop configuration
- `images/nostalgia-arcade/scripts/` - Arcade-specific setup scripts
- `images/nostalgia-arcade/systemd/` - Arcade-specific services
- `images/nostalgia-arcade/grub/` - Arcade-themed GRUB config

**Key differences from CRT**:
- No LattePanda-specific optimizations
- Generic hardware support
- Arcade-themed aesthetics instead of CRT
- Different Plymouth theme

**Steps**:
1. Create directory structure matching nostalgia-crt
2. Adapt scripts for generic hardware (remove LattePanda-specific code)
3. Create Arcade-themed assets (GRUB, Plymouth, wallpaper)
4. Create image.yml for standard setup
5. Update Containerfile to handle both variants

---

### 2. **Update README.md Status**
**Status**: Still shows "Loading..." for completed features  
**Impact**: Documentation accuracy  
**Effort**: 30 minutes

**Changes needed**:
```markdown
## Current Modifications

### 10-nostalgia-setup.sh
  - Custom Default User - [Successful] ✅
  - Custom Default Wallpaper - [Successful] ✅
  - Download and Install Arduino IDE - [Successful] ✅
  - Configure Custom Nostalgia CRT Plymouth Theme - [Successful] ✅
  - Configure Custom GRUB Theme - [Successful] ✅
  - Power and Performance Tweaks - [Successful] ✅

### Nostalgia Arcade
  - Custom Default User - [In Progress]
  - Custom Default Wallpaper - [In Progress]
  - Configure Custom Nostalgia ARCADE Plymouth Theme - [In Progress]
  - Configure Custom GRUB Theme - [In Progress]
```

---

### 3. **Test Build on Linux System**
**Status**: Not tested in actual container environment  
**Impact**: Validates actual deployment  
**Effort**: 4-6 hours

**Requirements**:
- Linux system with podman (or access to one)
- 30GB+ free disk space
- Run: `just build-qcow2 && just run-vm-qcow2`
- Verify all features work as documented

**What to verify**:
- [ ] GRUB theme appears correctly
- [ ] Plymouth animation plays
- [ ] First login setup completes
- [ ] Wallpaper is applied
- [ ] Arduino IDE shortcut exists
- [ ] Performance optimizations active
- [ ] No error messages in journalctl

---

## 🟡 MEDIUM PRIORITY (Enhancement/Polish)

### 4. **Enhanced Configuration System**
**Status**: Hardcoded values in scripts  
**Impact**: Easier customization for different hardware  
**Effort**: 1-2 days

**Improvements**:
- Create `/etc/nostalgia/config.ini` or similar for runtime configuration
- Move hardcoded values to config file:
  - CPU governor preferences
  - Thermal thresholds
  - Memory tuning parameters
  - Service disable list
- Create config templates for different hardware profiles

**Example structure**:
```ini
[performance]
cpu_governor=schedutil
turbo_boost=enabled
swap_enabled=true

[thermal]
throttle_temp=80
critical_temp=95

[services]
disable_bluetooth=true
disable_cups=true
```

---

### 5. **Hardware Detection & Auto-Tuning**
**Status**: Fixed for LattePanda  
**Impact**: Better multi-hardware support  
**Effort**: 2-3 days

**Add to `nostalgia-power-tuning.sh`**:
```bash
# Detect hardware and apply appropriate tuning
detect_hardware() {
  if grep -q "LattePanda" /proc/cmdline; then
    apply_lattepanda_tuning
  elif grep -q "Intel" /proc/cpuinfo; then
    apply_intel_generic_tuning
  elif grep -q "AMD" /proc/cpuinfo; then
    apply_amd_tuning
  fi
}
```

**Hardware profiles to support**:
- LattePanda Delta 3 (current)
- Generic Intel x86
- Generic AMD x86
- Raspberry Pi (stretch goal)
- ARM devices (future)

---

### 6. **Desktop Environment Customization**
**Status**: Basic KDE defaults only  
**Impact**: More polished retro aesthetic  
**Effort**: 2-3 days

**Enhancements**:
- Custom KDE Plasma color schemes (not just defaults)
- Widget layout templates (panel configuration)
- Keyboard shortcuts for retro feel
- Custom application menu organization
- KDE Plasmoid for system monitoring

**Add to `10-nostalgia-setup.sh`**:
```bash
# Apply KDE Plasma layout
kwriteconfig6 --file kdeglobals --group General --key ColorScheme "NostalgiaRetro"

# Configure panel layout
kwriteconfig6 --file plasmarc --group [Panel Data] --key zoffset "Top"

# Set up taskbar icons
create_taskbar_layout
```

---

### 7. **Advanced Power Management**
**Status**: Basic CPU/thermal only  
**Impact**: Better battery life on portable hardware  
**Effort**: 1-2 days

**Add to `nostalgia-power-tuning.sh`**:
- Dynamic power profile switching (power/balanced/performance)
- TLP integration for battery optimization
- Screen brightness auto-adjust
- Fan curve tuning
- Suspend/hibernate optimization
- Power consumption monitoring

```bash
# Install and configure TLP
dnf install tlp
systemctl enable tlp

# Create profiles
create_power_profile() {
  # Balanced, performance, power-saving
}
```

---

## 🟢 LOW PRIORITY (Nice-to-have/Future)

### 8. **Package Management UI**
**Status**: None  
**Impact**: User-friendly software installation  
**Effort**: 1-2 days

**Options**:
- Add GNOME Software Center
- Add KDE Discover (already available in KDE)
- Create simple package installation menu
- Maintain curated "Nostalgia Apps" list

---

### 9. **Documentation & Guides**
**Status**: Comprehensive technical docs exist  
**Impact**: User-friendly experience  
**Effort**: 2-3 days

**Create**:
- Getting Started Guide (for end users)
- Hardware Setup Guide (LattePanda specific)
- Customization Guide (how to modify for your hardware)
- Troubleshooting FAQ
- Contributing Guidelines (CONTRIBUTING.md)
- Video tutorials

---

### 10. **CI/CD Pipeline Enhancements**
**Status**: Basic GitHub Actions workflow exists  
**Impact**: Automated builds and releases  
**Effort**: 1-2 days

**Current workflows**: `build.yml`, `build-disk.yml`

**Enhancements**:
- Add automated testing on every PR
- Lint checks (shellcheck, hadolint, etc.)
- Automated release creation
- Container signing (already partially implemented)
- ArtifactHub integration
- Changelog generation

**Add linting step**:
```yaml
- name: Lint Containerfile
  run: |
    podman pull ghcr.io/hadolint/hadolint
    podman run --rm -v ${PWD}:/workspace hadolint /workspace/images/*/Containerfile

- name: Lint Shell Scripts
  run: |
    shellcheck images/*/scripts/*.sh
```

---

### 11. **Gaming & Emulation Support**
**Status**: Not started  
**Impact**: Fulfills "Nostalgia" aspect  
**Effort**: 2-4 days (ongoing)

**Potential additions**:
- Retro game emulators (PCSX2, Dolphin, etc.)
- Game controller detection and setup
- Game launcher frontend (Pegasus-Frontend, LaunchBox)
- DOSBox for old PC games
- ScummVM for point-and-click adventures
- Steam/Proton integration

**Add to build.sh**:
```bash
dnf install -y pcsx2 dolphin-emu dosbox scummvm
```

---

### 12. **Development Tools**
**Status**: Minimal (Arduino IDE only)  
**Impact**: Attracts maker community  
**Effort**: 1 day (per tool)

**Consider adding**:
- Visual Studio Code / Codium
- Git and GitHub CLI
- Platform.io (PlatformIO Core)
- KiCAD (electronics design)
- Blender (3D/retro graphics)
- GIMP (image editing)
- Python, Node.js development tools

**Add to build.sh**:
```bash
dnf install -y code git gh platformio kicad blender gimp python3-devel
```

---

## 🔧 TECHNICAL DEBT & IMPROVEMENTS

### 13. **Script Error Handling**
**Status**: Good, but could be better  
**Effort**: 4-6 hours

**Improvements**:
- Add trap handlers for cleanup on errors
- Better logging to syslog
- Error recovery mechanisms
- Timeout handling for long operations

```bash
cleanup() {
  echo "Cleaning up..."
  rm -f /tmp/nostalgia-*
}
trap cleanup EXIT ERR
```

---

### 14. **Systemd Service Improvements**
**Status**: Basic functional  
**Effort**: 2-3 hours

**Enhancements**:
- Add `PartOf=` relationships for service groups
- Add `WantedBy=graphical-session-pre.target` for better ordering
- Add restart policies and restart limits
- Add timeout values
- Add journal hints

```ini
[Unit]
PartOf=graphical-session.target
After=graphical-session-pre.target

[Service]
TimeoutStartSec=30
Restart=on-failure
RestartSec=5
```

---

### 15. **Config File Organization**
**Status**: Scattered throughout codebase  
**Effort**: 1 day

**Centralize**:
- Create `/etc/nostalgia/` directory in Containerfile
- Move all configuration to one place
- Create config management utility
- Add versioning for configs

```
/etc/nostalgia/
├── config.ini (main config)
├── profiles/ (hardware profiles)
├── themes/ (theme configurations)
└── services.d/ (service configs)
```

---

## 📊 ESTIMATED TIMELINE

**Week 1** (Highest Priority):
- [ ] Implement Nostalgia Arcade variant
- [ ] Test build on Linux
- [ ] Update README.md

**Week 2** (Medium Priority):
- [ ] Enhanced configuration system
- [ ] Hardware detection
- [ ] Desktop customization

**Week 3+** (Future):
- [ ] CI/CD enhancements
- [ ] Gaming/emulation
- [ ] Development tools
- [ ] Documentation

---

## 🎯 PROJECT MILESTONES

### Milestone 1: Multi-Image Support (v0.2)
- [x] Nostalgia CRT implementation
- [ ] Nostalgia Arcade implementation
- [ ] Updated README and documentation

### Milestone 2: Enhanced Customization (v0.3)
- [ ] Configuration system
- [ ] Hardware detection
- [ ] Desktop environment polish

### Milestone 3: Community Ready (v1.0)
- [ ] Complete documentation
- [ ] Testing verification
- [ ] GitHub Actions automation
- [ ] ArtifactHub listing

### Milestone 4: Feature-Rich (v1.1+)
- [ ] Gaming support
- [ ] Development tools
- [ ] Advanced power management
- [ ] Community contributions

---

## 💡 SUGGESTED NEXT STEPS

### Immediate (Today/Tomorrow):
1. **Update README.md** with completed feature status (30 min)
2. **Test build** on a Linux system with podman (4-6 hours)
3. **Create testing checklist** in GitHub Issues

### This Week:
1. **Start Nostalgia Arcade** variant implementation
2. **Add shellcheck/hadolint** to GitHub Actions
3. **Create CONTRIBUTING.md**

### This Month:
1. **Implement hardware detection**
2. **Add configuration system**
3. **Refine desktop environment**

---

## 🤝 COLLABORATION OPPORTUNITIES

These are great areas for community contribution:

**Easy** (Good for first-time contributors):
- Documentation improvements
- Script comment expansion
- Testing and bug reports
- Wallpaper/theme assets

**Medium**:
- Hardware profiles
- Desktop customization
- Package additions
- Localization

**Advanced**:
- CI/CD improvements
- Performance optimization
- New image variants
- Tool integration

---

## 📝 NOTES

- All work should maintain idempotency (safe to run multiple times)
- Keep scripts well-documented with comments
- Test on actual hardware when possible
- Maintain backward compatibility
- Follow existing code style and patterns
- Use semantic versioning for releases

---

## ❓ OPEN QUESTIONS

1. **Arcade variant requirements**: What specific features/aesthetics needed?
2. **Target audience**: Power users? Casual users? Makers?
3. **Hardware support scope**: Only x86? Include ARM/Pi support?
4. **Gaming focus level**: Emulation? Retro games? Modern games too?
5. **Update strategy**: How should updates be managed? (automatic? manual?)
6. **Community involvement**: Open to contributions? Public roadmap?

**Discuss these to better prioritize future work.**
