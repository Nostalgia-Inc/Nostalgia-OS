# Nostalgia CRT implementation summary

The approved startup, Arduino IDE 2 and CRT boot-branding fixes are implemented.
The CRT container builds successfully. Current test evidence and remaining
release work are recorded in [REVIEW_NOTES.md](REVIEW_NOTES.md); installed boot
and physical acceptance must be verified before calling the OS release-ready.

## Startup and desktop

The shared wallpaper service starts with Plasma, updates its live desktops through
Qt 6 D-Bus scripting, and records completion only after a verified update. New
accounts no longer inherit a guessed Plasma containment. Successful setup runs
once, preserving later wallpaper choices. Existing affected accounts need the
marker-reset recovery steps in the review after deploying the rebuilt image.

Default applications use installed desktop IDs. The setup script selects the
Nostalgia color scheme only when an actual scheme file exists; none is supplied
by this repository.

## Arduino IDE 2

Both variants install Flathub's `cc.arduino.IDE2` through a background system
service with download retries. A separate user service creates the exported
launcher in the XDG Desktop directory and migrates the old broken shortcut.
Fresh installation accounts join `dialout`, and scoped udev rules cover the
LattePanda Leonardo's normal/upload USB IDs.

CRT seeds a LattePanda Leonardo sketch profile in the default Arduino sketchbook.
Users install Arduino AVR Boards through the IDE's Boards Manager. Real IDE
installation and Blink compilation have passed; graphical launch and upload to
the physical coprocessor remain acceptance checks.

## Boot branding

CRT's green-on-black GRUB theme includes a boot menu, navigation help and timeout
bar using the shipped Unifont font. Its helper validates and manages only its
`custom.cfg` block, preserves existing configuration and boot entries, and copies
assets to `/boot/grub2`. Disk installations apply it during the first boot for
subsequent boots; the ISO invokes the helper during installation.

Plymouth's script plugin is installed, its animation uses supported image/refresh
APIs, and password/question prompts are visible. Dracut rebuilds the explicit
image kernel's initramfs and checks the theme and text renderer. Isolated rendering
passes; installed graphical boot is a separate acceptance check.

## Power and build behavior

The tuning service's ordering cycle is removed. CRT selects a supported governor
per CPU policy and logs turbo/thermald failures. Huge-page settings use valid
kernel policies. Existing service-disabling, USB-autosuspend and write-cache
policies remain configured; their benefits need measurement on the LattePanda.

The base is pinned to Bazzite Deck `44.20260929`. Required package failures stop
the build. Linux runtime files use LF line endings, and lint failures propagate.

Use [BUILD_INSTRUCTIONS.md](BUILD_INSTRUCTIONS.md) for the build commands and
[CRT_VALIDATION.md](CRT_VALIDATION.md) for first-boot troubleshooting, serial
upload, wallpaper and physical power checks. Arcade assets, production credential
handling and repository signature policy remain separate release work.
