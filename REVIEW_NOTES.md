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

## Larger changes awaiting confirmation

These findings are from the source review. They have not been corrected as part
of the startup patch.

The stable registry manifest resolved on 4 October 2026 to Bazzite version
`44.20260929`, published 29 September 2026, with digest
`sha256:286ed98549609b2790d3430f4ad796e888804a695faa65268ea5e6e20381f9d8`.
The base change was approved and applied to both Containerfiles. They now use:

```dockerfile
FROM ghcr.io/ublue-os/bazzite-deck@sha256:286ed98549609b2790d3430f4ad796e888804a695faa65268ea5e6e20381f9d8
```

The replacement base downloaded successfully and a full CRT container build
completed with local tag `localhost/nostalgia-os:feature-validation`. That build
still skipped Arduino after the package resolver returned `Packages not found:
arduino`; a successful container build is therefore not proof that every feature
works. A cached follow-up build verifies corrected unit-file permissions.

| Priority | Finding | Proposed change |
| --- | --- | --- |
| Resolved | The previous Bazzite digest returned `manifest unknown`. | Both pins were updated with approval to the available stable digest above. Full build validation is in progress. |
| High | CRT explicitly disables Terra RPM signature verification. | Replace the repository bypass with verified keys or repository configuration compatible with the image builder; fail visibly on verification errors. |
| High | Disk and ISO configurations ship the shared `nostalgia` administrator account/password. | Require installer-selected credentials for release images; keep known credentials only in an explicit development configuration. |
| Medium | Build/push image inputs differ, but the metadata output provides fully qualified tags, which both actions accept. This is not a confirmed publishing failure. Signing references those tags and leaves the digest variable unused. | Simplify the redundant image inputs, consider digest-based signing, and verify a real workflow run before release. |
| High | ISO pull requests default to the ARM runner when no workflow input exists. The container build has no corresponding ARM platform build. | Make x86-64 the explicit supported default, or add a validated multi-architecture image/ISO pipeline. |
| High | Arcade's `gamescope/media` directory contains only `.gitkeep`, so no boot video is supplied. Its Plymouth theme references three PNG files that are absent. | Decide whether Arcade should reuse CRT assets or receive its own assets, then complete and boot-test that variant. |
| Medium | The boot scripts disable Bluetooth every boot (and CRT also disables printing/discovery), disable USB autosuspend, force performance settings, and mostly hide failures. | Make device/service policies configurable, respect available governors and user choices, and log what actually succeeds. |
| Medium | Arduino RPM installation is optional and can silently fail, while desktop shortcuts always execute `arduino`. The ISO separately installs a Flatpak with a different launch command. | Choose one supported Arduino installation method and generate shortcuts only for installed applications. Honor the localized XDG Desktop location. |
| Medium | GRUB files are copied but no custom `GRUB_THEME` configuration is supplied. Plymouth animations need a boot-time rendering check. | Finish the boot-branding integration and verify GRUB/Plymouth on a booted image before marking those features complete. |
| Medium | Local ISO recipes use `iso`, whereas the workflow uses `anaconda-iso`; several image-building and cleanup recipes need separate validation. | Align recipes with the selected builder version and make cleanup target only documented generated artifacts. |

## Validation

- Nine isolated Bash/startup tests passed under Fedora WSL.
- Three Plasma JavaScript tests passed under Node.js on Windows: multiple
  desktops, no desktops, and rejected configuration. No live desktop was changed.
- All six repository shell scripts passed ShellCheck 0.10.0 and Bash syntax checks.
- `just check`, recipe parsing, and a local build dry run passed.
- Disk/ISO TOML parsed; the extracted ISO `%post` script passed Bash syntax checks.
- Updated CRT user units passed `systemd-analyze --user verify` inside the cached
  Bazzite-based image. Warnings concerned the Windows mount's file permissions.
- A full CRT image build was attempted with a distinct local `wallpaper-fix` tag.
  It stopped at `FROM`: the pinned base is not cached and GHCR reports its
  manifest as unknown. No replacement base, new OS image, or deployment was made.

## Follow-up feature audit

The cached `localhost/nostalgia-os:latest` image and the replacement Bazzite base
both report that neither `arduino` nor `plymouth-plugin-script` is installed.
`thermald` is installed (2.5.13 in the new base). The fresh CRT build also reports
`Packages not found: arduino`, skips it, and continues successfully. This confirms
that Arduino installation is broken and the script-based Plymouth theme lacks
its required renderer. The fresh build installs mpv 0.41.0 successfully.

The CRT power service and the Arcade equivalent also had
`After=multi-user.target` while being enabled under that target. This ordering
cycle is now removed. CRT's governor logic checks each CPU frequency policy's
available governors, chooses `schedutil` where supported and `powersave` for
Intel P-state, and reports the actual resulting governor. Turbo/thermald errors
are reported. The shmem hugepage policy is corrected to `advise`; anonymous
memory uses `madvise`, per the [kernel documentation](https://docs.kernel.org/admin-guide/mm/transhuge.html).

All three new CPU governor regression cases passed (schedutil, Intel P-state,
and preservation of an unsupported policy), bringing the combined regression
suite to 15 passing cases. Both power units passed systemd verification in the
cached image. The existing service-disabling and write-cache policies remain
unchanged pending a separate decision.

Two initial audit details were corrected after checking the upstream action
implementations and tracked hidden files: Arcade's media directory exists with
`.gitkeep` (it has no actual video), and full image tags override the build/push
action image fields. The apparent name mismatch alone is not a publishing bug.
See [buildah-build's tag handling](https://github.com/redhat-actions/buildah-build/blob/v2/src/utils.ts)
and [push-to-registry's documented inputs](https://github.com/redhat-actions/push-to-registry/tree/v2#image-tag-inputs).

The remaining Arduino and boot-integration implementation is described in
[FEATURE_COMPLETION_PLAN.md](FEATURE_COMPLETION_PLAN.md) and awaits confirmation.
README's feature table now reflects evidence rather than claiming that every
feature has already succeeded.

Default-application setup also referenced the wrong KWrite desktop ID and
unconditionally selected a native Firefox launcher that is absent in the cached
image. Both variants now use `org.kde.kwrite.desktop`, recognize native or
Flatpak Firefox, and configure both HTTP and HTTPS only when Firefox is installed.

A complete graphical boot on the target hardware remains necessary to confirm
the visible wallpaper, boot animations, and persistence across reboot. Unit tests
and service validation do not establish hardware readiness or release completion.

Containerfiles explicitly copy service units with mode 0644 so Windows checkouts
do not produce executable, world-writable units in the OS image. The final CRT
rebuild passed with image ID
`dff21cf5cd70f665a84220107b38ce054d93c6dab936bf4379398eca7a36902a`.
Inspection of this image verified all three unit modes as 0644, the readable
wallpaper, the resolvable Steam boot-video override, and installed tmux 3.7c,
mpv 0.41.0, and thermald 2.5.13. Both user units and the power unit passed systemd
verification without the earlier permission warnings. Arduino and
`plymouth-plugin-script` are absent. No bootable disk/ISO or hardware boot was
performed because the larger Arduino/boot-branding completion still awaits
confirmation.
