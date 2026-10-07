# CRT first-boot and LattePanda acceptance checks

Repository fixes take effect after rebuilding and installing/rebasing to the new
image. A successful container build alone does not establish hardware readiness.
See [review results](REVIEW_NOTES.md) for completed checks.

## Arduino IDE 2

The system service downloads Flathub's `cc.arduino.IDE2` after startup. Internet
access is required for the initial application/runtime download. Download failures
retry every two minutes without blocking desktop startup.

```bash
systemctl status nostalgia-arduino-install.service
journalctl -b -u nostalgia-arduino-install.service --no-pager
flatpak info --system cc.arduino.IDE2
flatpak run cc.arduino.IDE2
```

The installer exits after success, so an inactive service is normal when
`flatpak info` confirms installation. The separate user service creates the
shortcut in the XDG Desktop directory after installation. It also migrates the
old `Exec=arduino` launcher. Personal shortcuts and later shortcut deletions are
preserved.

CRT seeds `~/Arduino/hardware/lattepanda/avr` with its LattePanda Leonardo sketch
profile. In IDE 2, install **Arduino AVR Boards** in Boards Manager, restart the
IDE if necessary, then select **LattePanda AVR Boards > LattePanda Leonardo** and
the onboard serial port. A custom Sketchbook location needs the profile copied
from `/usr/share/nostalgia/arduino/lattepanda` into that location's
`hardware/lattepanda/avr` directory. This profile supports sketch uploads;
bootloader flashing needs the vendor's complete hardware package.

Fresh disk/ISO installations put `nostalgia` in `dialout`. For an existing account
that needs serial access outside the active graphical session:

```bash
sudo usermod -aG dialout "$USER"
```

Log out and back in after a group change. The udev rules also grant active-seat
access to the vendor's normal and bootloader USB IDs.

**Hardware acceptance:** upload Blink to the onboard ATmega32U4, check the LED,
open Serial Monitor with a serial-output sketch, and repeat after reboot. Confirm
the port is accessible after the 1200-baud reset into upload mode.

Vendor reference: [Delta 3 Leonardo configuration](https://docs.lattepanda.com/content/3rd_delta_edition/drivers_and_software/).
Core/variant/tool reuse follows [Arduino's platform specification](https://arduino.github.io/arduino-cli/1.5/platform-specification/#referencing-another-core-variant-or-tool).

## GRUB and Plymouth

The GRUB service installs assets into `/boot/grub2/themes/nostalgia` and adds a
managed block to the existing `custom.cfg` hook. It preserves BLS boot entries and
unmanaged custom configuration. Its first run saves the original custom file as
`custom.cfg.nostalgia-backup` when one exists. Unsupported bootloader layouts fail
without rewriting their configuration.

```bash
systemctl status nostalgia-boot-branding.service
journalctl -b -u nostalgia-boot-branding.service --no-pager
sudo grub2-script-check /boot/grub2/custom.cfg
plymouth-set-default-theme
```

For disk images, the theme installed during the first boot appears on the next
boot. The ISO post-install helper can apply it before the first installed boot.
Removing the `BEGIN NOSTALGIA THEME` through `END NOSTALGIA THEME` block disables
this GRUB integration; stop/disable its service to prevent reinstallation.

**Boot acceptance:** verify the green GRUB menu, readable selection/timeout,
normal boot and rollback entries, Plymouth animation, and graphical login. Test
an encrypted installation's password prompt if encrypted disks will be offered.

## Wallpaper and power

```bash
journalctl --user -b -u nostalgia-setup.service -u nostalgia-apply-wallpaper.service --no-pager
journalctl -b -u nostalgia-power-tuning.service --no-pager
cat /sys/devices/system/cpu/cpufreq/policy*/scaling_governor
cat /sys/devices/system/cpu/intel_pstate/no_turbo
systemctl status thermald.service
```

Verify the Nostalgia wallpaper on a fresh account and multiple monitors. Change
it manually and confirm the choice survives another login. An upgraded account
with an old success marker needs the recovery steps in REVIEW_NOTES.md to reapply
the wallpaper.

**Power acceptance:** measure idle power, CPU temperatures/frequency under load,
fan behavior, storage performance, USB stability and suspend/resume on the Delta
3. Existing Bluetooth/printing/discovery and write-cache policies are retained;
performance gains have not been established by mock tests or container checks.
