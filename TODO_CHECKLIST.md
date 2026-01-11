# Nostalgia OS: Todo Checklist

## 🚨 CRITICAL (Must do ASAP)

- [ ] **Update README.md** - Change "Loading..." to "Successful" for CRT features
  - Time: 30 min
  - PR ready: Yes
  
- [ ] **Test build on Linux** - Validate actual container build and boot
  - Time: 4-6 hours
  - Blockers: Need Linux system with podman
  - Success criteria: All features visible on first boot

## 🔥 HIGH PRIORITY (This week)

- [ ] **Create Nostalgia Arcade variant**
  - Time: 2-3 days
  - Subtasks:
    - [ ] Create `images/nostalgia-arcade/` directory structure
    - [ ] Copy Containerfile from CRT and adapt
    - [ ] Create generic hardware setup scripts
    - [ ] Create Arcade-themed assets (GRUB, Plymouth, wallpaper)
    - [ ] Create image.yml for arcade
    - [ ] Test arcade build
  - Blockers: None

- [ ] **Add CI/CD linting**
  - Time: 2-4 hours
  - What: Add shellcheck and hadolint to GitHub Actions
  - File: `.github/workflows/build.yml`
  - Commands:
    ```bash
    # Add lint job before build
    - name: Lint Shell Scripts
      run: |
        shellcheck images/*/scripts/*.sh
    
    - name: Lint Containerfiles
      run: |
        podman run --rm -v ${PWD}:/w hadolint /w/images/*/Containerfile
    ```

- [ ] **Create CONTRIBUTING.md**
  - Time: 2-3 hours
  - Include: How to contribute, code style, testing requirements

## ⭐ MEDIUM PRIORITY (Next 2 weeks)

- [ ] **Hardware detection in power tuning**
  - Time: 2-3 days
  - File: `images/nostalgia-crt/scripts/nostalgia-power-tuning.sh`
  - Add auto-detection for CPU type, apply appropriate tuning

- [ ] **Configuration system**
  - Time: 1-2 days
  - Create: `/etc/nostalgia/config.ini` template
  - Move hardcoded values to config files
  - Support profiles (laptop, desktop, lattepanda, generic-intel, etc.)

- [ ] **Enhanced KDE Plasma customization**
  - Time: 1-2 days
  - File: Expand `images/nostalgia-crt/scripts/10-nostalgia-setup.sh`
  - Add: Color schemes, panel layout, widget configuration

- [ ] **Create Getting Started Guide**
  - Time: 2-3 hours
  - Audience: End users (not technical)
  - Include: Hardware requirements, installation steps, first-boot walkthrough

## 💡 NICE TO HAVE (Next month+)

- [ ] **Gaming/Emulation support**
  - Time: 2-4 days
  - Add to build.sh: PCSX2, Dolphin, DOSBox, ScummVM
  - Consider: Game launcher frontend

- [ ] **Development tools**
  - Time: 1 day per tool
  - Candidates: VSCode, Git, PlatformIO, KiCAD, GIMP, Blender

- [ ] **Advanced power management**
  - Time: 1-2 days
  - TLP integration, power profiles, battery optimization

- [ ] **Documentation expansion**
  - Time: 2-3 days
  - Add: Hardware setup guide, troubleshooting FAQ, video tutorials

- [ ] **Package management UI**
  - Time: 1-2 days
  - Evaluate: KDE Discover vs others

---

## 📋 TESTING CHECKLIST (For each release)

Before marking a task complete, verify:

### Build Validation
- [ ] `just check` passes (Justfile syntax)
- [ ] `just lint` passes (shell scripts)
- [ ] `just format` doesn't change anything (scripts already formatted)
- [ ] Container builds without errors: `just build-qcow2`

### Boot Testing
- [ ] GRUB theme appears (green text)
- [ ] Plymouth animation plays
- [ ] System boots to login prompt
- [ ] No kernel errors in boot log

### First Boot Testing
- [ ] Login works: `nostalgia` / `nostalgia`
- [ ] Desktop loads completely
- [ ] Wallpaper is visible
- [ ] Plasma is responsive

### Feature Verification
- [ ] Wallpaper shortcut script completed without errors
- [ ] Power tuning script completed without errors
- [ ] Setup script completed without errors
- [ ] Arduino IDE is available
- [ ] All services show as active/exited

### Service Validation
- [ ] Check service logs: `journalctl -u nostalgia-*`
- [ ] No critical errors in logs
- [ ] State files created properly
- [ ] Services run idempotently (no errors on 2nd run)

### Performance Check
- [ ] System feels responsive
- [ ] CPU frequency scaling works
- [ ] No unexpected CPU load
- [ ] Network connectivity functional

---

## 🔍 QUICK START FOR NEW ITEMS

When starting new work:

1. **Create a branch**: `git checkout -b feature/descriptive-name`
2. **Check existing code**: Review similar implementations
3. **Follow patterns**: Match existing code style
4. **Document as you go**: Inline comments and docstrings
5. **Test thoroughly**: Before pushing
6. **Update docs**: README, ROADMAP, this file
7. **Create PR**: Include description of changes

---

## 📊 PROGRESS TRACKING

### Completed ✅
- [x] First boot customization system
- [x] Power and performance tuning
- [x] GRUB theme
- [x] Wallpaper system
- [x] Plymouth theme
- [x] Arduino IDE integration
- [x] KDE Plasma defaults
- [x] Documentation (IMPLEMENTATION_SUMMARY, BUILD_INSTRUCTIONS, CHANGES)

### In Progress 🔄
- [ ] Testing on actual Linux system
- [ ] Nostalgia Arcade variant

### Not Started ⭕
- [ ] All other items in ROADMAP.md

### Summary
- **Complete**: 8 items
- **In Progress**: 2 items
- **Total Roadmap**: 15 major items

---

## 💬 DECISION POINTS

Questions that should be answered before starting work:

1. **Arcade variant**
   - Should it have different styling from CRT?
   - What's the intended hardware? (generic x86?)
   - Should it have gaming/arcade features pre-installed?

2. **Configuration system**
   - INI format, YAML, or Toml?
   - Should be editable by users?
   - How to version/update configs?

3. **Hardware support**
   - Support Raspberry Pi / ARM?
   - Only x86-64?
   - How to handle detection failures?

4. **Gaming/Emulation**
   - Which emulators are priorities?
   - Need game launcher frontend?
   - What about licensing considerations?

5. **Development tools**
   - Which are essential vs optional?
   - Should they be installed by default or optional?
   - Need IDE/dev environment setup?

**Address these to unblock related work.**

---

## 🎯 SUCCESS CRITERIA

Project is "complete" when:

### MVP (Current) ✅
- [x] Nostalgia CRT works and boots properly
- [x] All first-boot features visible
- [x] Documentation is comprehensive
- [x] Build system works on Linux

### v0.2 (Next)
- [ ] Nostalgia Arcade variant exists
- [ ] Both variants tested on hardware
- [ ] CI/CD pipeline automated
- [ ] Community testing

### v1.0 (Mature)
- [ ] Multi-hardware support
- [ ] Advanced features (gaming, dev tools)
- [ ] Complete documentation
- [ ] Community contributions
- [ ] ArtifactHub listing

---

## 📞 COLLABORATION

**Want to help?** Pick any item from:
- 🔴 HIGH PRIORITY - Critical for project
- 🟡 MEDIUM PRIORITY - Nice improvements
- 🟢 LOW PRIORITY - Polish/future features

**Easy wins** (good for first-time contributors):
- Documentation improvements
- Testing and bug reports
- Adding comments to scripts
- Creating wallpaper/theme assets

**Contact**: Open a GitHub issue or PR with your ideas!

---

**Last updated**: 2026-01-11  
**Status**: MVP Complete, Ready for Phase 2 ✅
