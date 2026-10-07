# Startup fixes and release review

## Wallpaper failure

The old service started with the user manager's `default.target`, before Plasma
was necessarily available. The script guessed containment ID 1 when no desktop
was found, edited Plasma's config file while Plasma could overwrite it, only
checked for a command named `qdbus`, and wrote its completion marker even when
the D-Bus update failed. The cached Bazzite image has its Qt 6 tool at
`/usr/lib64/qt6/bin/qdbus`, which the old PATH lookup did not find.

The shared wallpaper script now updates the live desktops through Plasma's
scripting API. It locates Qt 6's D-Bus tool, waits up to 60 seconds for usable
desktops, bounds each request, checks the written Image value, and requires a
positive desktop-count acknowledgment before recording success. Failures return
an error and remain eligible for the next desktop login. A successful setup is
still applied once per user so later personal wallpaper choices are preserved.

The wallpaper and setup services now belong to `plasma-workspace.target` and
stop with `graphical-session.target`. Setup runs before plasmashell and wallpaper
application runs after it. The previous setup units had `After=default.target`
while being wanted by that same target, creating an ordering cycle.

The Containerfiles and ISO installer no longer seed a partial desktop layout
with a guessed containment ID. Both variants install the shared wallpaper asset.

References: [KDE scripting API](https://develop.kde.org/docs/plasma/scripting/api/),
[Plasma evaluateScript implementation](https://github.com/KDE/plasma-workspace/blob/Plasma/6.3/shell/shellcorona.cpp),
[Plasma session target](https://github.com/KDE/plasma-workspace/blob/master/startkde/systemd/plasma-workspace.target).

## Other small fixes applied

- Both setup scripts fail without `kwriteconfig6`, leaving completion retryable.
  Arcade no longer hides failures when writing the default applications.
- CRT selects the Nostalgia color scheme only if its `.colors` file is installed;
  this repository does not provide that scheme.
- CRT's shipped `CRT-BOOT.webm` is aliased to the `boot-intro.webm` filename used
  by the Steam startup configuration and ISO installer.
- Local builds specify the CRT Containerfile instead of looking for a nonexistent
  root Containerfile. The default container name is lowercase.
- Transparent huge pages use the valid `madvise` policy instead of the invalid
  value `1`. Other tuning policies are unchanged.
- `.gitattributes` requires LF line endings for Linux build/runtime files.
- Justfile formatting was corrected so `just check` passes.

## Recover an already-installed user's wallpaper

These repository edits must be included in a rebuilt image and deployed to the
machine before the following commands use the new implementation. Run them as
the affected user from a KDE desktop terminal. Removing the old marker explicitly
reapplies Nostalgia's wallpaper, replacing that user's current wallpaper.

```bash
rm -f "${XDG_STATE_HOME:-$HOME/.local/state}/nostalgia/wallpaper-applied"
systemctl --user daemon-reload
systemctl --user restart nostalgia-apply-wallpaper.service
journalctl --user -u nostalgia-apply-wallpaper.service -b --no-pager
```

If an upgraded installation retains old global enablement links under
`default.target.wants`, migrate those links once:

```bash
sudo systemctl --global reenable nostalgia-setup.service nostalgia-apply-wallpaper.service
```

Log out and back into KDE after migrating the links. To inspect first-login
setup, use `journalctl --user -u nostalgia-setup.service -b`; these are user units.

## Approved Arduino and boot-branding completion

The base pin, Arduino IDE 2, and CRT boot-branding changes were explicitly
approved. Both Containerfiles use Bazzite Deck `44.20260929`:

```dockerfile
FROM ghcr.io/ublue-os/bazzite-deck@sha256:286ed98549609b2790d3430f4ad796e888804a695faa65268ea5e6e20381f9d8
```

The old digest returned `manifest unknown`. The old Arduino RPM install returned
`Packages not found: arduino` but ignored the error. Both variants now use a
background system Flatpak installer for `cc.arduino.IDE2`. Failed downloads retry,
and completion requires a successful `flatpak info --system` check. The ISO-only
legacy app ID and invalid `Exec=arduino` shortcuts have been removed. An
independent user service creates/migrates the exported IDE 2 shortcut, including
accounts whose old first-login setup already completed. It honors localized and
disabled Desktop directories and preserves personal shortcuts.

The image seeds a local `dialout` entry from Fedora's NSS group database so
shadow user-management tools and installers can assign the group. New
installation accounts belong to `dialout`. Scoped udev rules cover the
LattePanda Leonardo's vendor normal/upload IDs (`3343:803a`/`3343:003a` and the
vendor-listed `2a03` alternatives), plus standard Leonardo IDs. These came from
the [vendor's configuration bundle](https://docs.lattepanda.com/content/3rd_delta_edition/drivers_and_software/).
CRT also seeds a thin LattePanda sketch profile referencing Arduino's maintained
AVR core, Leonardo variant, and avrdude tool. Users install Arduino AVR Boards
from IDE 2's Boards Manager before compiling; the full old vendor toolchain is
not bundled. The profile supports sketch uploads, not bootloader flashing.

CRT GRUB now has actual boot-menu, help, and timeout components and uses the
shipped Unifont font. Its system helper validates a managed `custom.cfg` block,
backs up existing custom configuration, preserves unmanaged entries and file
permissions, and copies theme/font assets to `/boot/grub2`. It refuses missing
hooks, malformed managed blocks, or symlinked custom configuration. It leaves
BLS entries and the main GRUB configuration intact. The ISO invokes the same
helper; disk images apply it on their first boot for the following boot.

Plymouth now stores scaled images, crops complete spinner frames with Image.Crop,
and animates through SetRefreshFunction. It includes password/question callbacks.
The required script plugin is installed, the theme is selected, and dracut rebuilds
an explicit image kernel's initramfs with checks for the script, theme and text
renderer. A real VM test caught an omitted OSTree dracut module: container builds
do not autodetect the installed system's root setup. The rebuild now explicitly
includes `ostree` and checks for its root-setup service and binary. CRT also ships
bootc kernel arguments to activate the splash. The GRUB service remounts `/boot`
writable only inside a private mount namespace, following bootc's read-only mount
policy. Windows CRLF in the .plymouth descriptor previously made Plymouth look
for `script\r.so`; LF rules now cover theme scripts, descriptors and udev rules.

## Power and other routine corrections

Both power services had an ordering cycle involving `multi-user.target`; it is
removed. CRT chooses a supported CPU governor per policy (`schedutil`, or
`powersave` on Intel P-state), reads it back, and logs turbo/thermald failures.
Anonymous huge pages use `madvise`; shmem uses the kernel's valid `advise` value.
Existing service-disabling, USB-autosuspend, and write-cache policies are retained.
These are requested settings, not demonstrated LattePanda performance gains.

Default-app setup now uses KWrite's actual desktop ID and selects native/Flatpak
Firefox only when installed, for both HTTP and HTTPS. Required build packages
fail the build instead of silently being skipped. The lint recipe now propagates
ShellCheck failures rather than discarding each find-exec command's status.

## Verified checks

- 29 regression cases cover wallpaper startup/Plasma scripting, CPU governors,
  Arduino download failure/retry, localized shortcuts, and GRUB preservation.
  Linux and Windows run their respective fixtures; platform-dependent skips are
  explicit. All cases have passed across the two environments.
- ShellCheck 0.10.0, Bash syntax, Justfile formatting, disk/ISO TOML parsing and
  extracted kickstart post-install syntax checks passed.
- A CRT container built successfully with the updated base and required tmux,
  mpv, thermald and Plymouth script plugin. Initramfs listings contain the theme,
  script plugin, label renderer and fonts.
- Six installed system/user services passed systemd verification; all unit files
  have mode 0644. Scoped serial rules passed udevadm verify.
- A normal test account was created with both `wheel` and `dialout` inside the
  final image. Running the installed shortcut helper as that account copied the
  actual Flatpak launcher and LattePanda board profile successfully.
- The GRUB helper passed the actual grub2-script-check inside the image, twice,
  while preserving a fixture's original custom settings and backup.
- A real isolated system Flatpak installation downloaded Arduino IDE 2.3.10,
  its runtime and exported launcher. The manifest grants device access. Container
  sandbox post-install hooks emitted namespace warnings; application GUI startup
  on an installed OS remains a separate check.
- The IDE-bundled Arduino CLI 1.5.1 installed Arduino AVR Boards 1.8.8 and compiled
  Blink for `lattepanda:avr:lpleonardo`: 3956 bytes flash, 149 bytes RAM.
- The actual Plymouth script rendered its existing artwork and spinner using
  Plymouth 24.004.60's X11 renderer in an isolated Debian container. The
  password prompt also rendered visibly; the final Fedora image uses
  DRM/framebuffer renderers and includes its text renderer/fonts.

The final local CRT image is `localhost/nostalgia-os:finalization`, image ID
`156ad4bde9fdf5783c6d97e84ab2af7433714e53bed83646296749606193a43a`.
The disk builder produced an ext4 QCOW2 for local QA. The configured Btrfs build
failed at an upstream virtiofs socket-startup race; a bounded readiness fix was
applied only to the local validation tool, outside this OS repository. WSL's
kernel lacks Btrfs, so production Btrfs installation remains unverified.
The QA disk initially contained image `8a7b02f...`; its initramfs was replaced
with the corrected build and splash arguments staged for diagnostic booting.
The custom Plymouth artwork and animation rendered in the VM, and OSTree root
setup and switch-root completed. This is staged boot evidence, not a fresh
installation of the final image. Full desktop/GRUB acceptance is still pending. No
physical LattePanda boot, IDE GUI upload, thermal measurement or suspend/resume
test has been performed.

## Remaining release work outside this approval

| Priority | Finding | Next decision/check |
| --- | --- | --- |
| High | CRT still disables Terra RPM signature checks. | Replace the bypass with verified repository keys/configuration. |
| High | Installers retain the shared nostalgia administrator/password. | Choose production credential handling; current credentials are for development. |
| Medium | ISO PR builds now default to x86-64, matching the container build; explicit ARM support remains unvalidated. | Verify a real workflow run and separately decide whether to support ARM. |
| High | Arcade has only a media .gitkeep and references three missing Plymouth PNGs. | Supply Arcade assets and separately build/boot-test that variant. |
| Medium | Some power commands still hide errors; Bluetooth/printing/discovery and write-cache defaults are broad. | Decide on configurable policies, then measure on the Delta 3. |
| Medium | Local disk/ISO/VM/cleanup recipes need end-to-end validation. | Validate the selected builder and make cleanup target only known generated artifacts. |

The apparent CI build/push image-name mismatch is not itself a confirmed bug:
fully qualified metadata tags override those inputs. Digest-based signing is a
possible improvement; a real publishing workflow remains untested. See
[buildah tag handling](https://github.com/redhat-actions/buildah-build/blob/v2/src/utils.ts)
and [push-to-registry inputs](https://github.com/redhat-actions/push-to-registry/tree/v2#image-tag-inputs).

[CRT_VALIDATION.md](CRT_VALIDATION.md) contains first-boot troubleshooting and the
remaining physical acceptance checks. README's table distinguishes tested image
behavior from hardware readiness. No GitHub publishing or OS deployment was
performed by this review.
