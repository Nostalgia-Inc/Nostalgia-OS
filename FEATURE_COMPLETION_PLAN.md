# Approved completion of CRT features

The base update to Bazzite `44.20260929` is approved and applied. Arduino IDE 2 and CRT boot branding were also explicitly approved.
The implementation and validation results are recorded in REVIEW_NOTES.md.

## Arduino IDE

- Standardize on Arduino IDE 2 from Flathub, application ID `cc.arduino.IDE2`.
- Remove the best-effort legacy Arduino RPM installation and the ISO-only
  `cc.arduino.arduinoide` installation, which do not match the intended launcher.
- Install IDE 2 system-wide with a dedicated service after networking is
  available. Run the installer in the background so it does not block desktop
  startup; retry failed downloads and check the actual installed application.
- Generate a matching launcher and desktop shortcut using the user's XDG
  Desktop directory. Include the required serial-port permissions for the
  LattePanda's ATmega32U4, with narrowly scoped udev rules and serial group access.
- First installation requires internet access. IDE launch and upload to the
  physical coprocessor must be verified on the LattePanda before release.

## Boot branding

- Replace the invalid GRUB theme properties with a complete theme containing a
  boot menu and timeout display, preserving the existing green-on-black style.
- Activate the theme through the bootloader's existing `custom.cfg` hook and
  copy its theme/font assets to `/boot`. Preserve existing custom configuration
  and boot entries; validate the inserted GRUB code before installation.
- Use a dedicated boot-branding service for installed systems and the same
  helper from ISO installation. A first-boot installation takes effect on the
  following boot; the installer can seed it before the first installed boot.
- Fix Plymouth's unsupported animation calls and install the script plugin,
  select the theme, and ensure the theme is included in the initramfs. Verify a
  render before claiming the animation works.

## Power tuning

The current code requests dynamic CPU scaling, Intel turbo, `mq-deadline`,
thermald, memory/network adjustments, and disabled USB autosuspend. It also
disables Bluetooth, printing, and network discovery. The service ordering cycle and unsupported governor selection are corrected.
Some retained tuning commands still hide failures.

The routine corrections select a supported CPU governor and report its readback,
and log turbo/thermald failures. Changes to Bluetooth/printing/discovery defaults,
write-cache policy, or a configurable power-profile system are separate decisions
and are not included in this proposal.

## Validation and scope

Build CRT, inspect installed packages/services and boot assets, run isolated
regressions, and attempt a VM boot if acceleration and an image builder are
available. Record hardware-dependent checks as pending until a real LattePanda
boot and serial upload are performed. Arcade completion, production passwords,
repository signature policy, and GitHub publishing are separate work.
