#!/usr/bin/bash
set -euo pipefail

# Container builds have no root home after ostree's /var cleanup. Dracut's
# generic user lookup still attempts to include it, so supply an empty directory.
install -d /var/roothome
find /usr/share/plymouth/themes/nostalgia -type f -exec chmod 0644 '{}' +
find /usr/share/plymouth/themes/nostalgia -type d -exec chmod 0755 '{}' +
plymouth-set-default-theme nostalgia
found=0
for kernel_dir in /usr/lib/modules/*; do
    [[ -f "$kernel_dir/vmlinuz" ]] || continue
    found=1
    # Explicit image kernel: uname here would select the container host's kernel.
    # A container build is not booted through OSTree, so dracut's automatic
    # module detection can omit the root setup required by the installed OS.
    DRACUT_NO_XATTR=1 dracut --force --no-hostonly --add ostree --kver "${kernel_dir##*/}" "$kernel_dir/initramfs.img"
    # Inspect the complete listing without causing a pipefail/SIGPIPE failure.
    lsinitrd "$kernel_dir/initramfs.img" > /tmp/nostalgia-initramfs-list
    grep 'usr/lib64/plymouth/script.so' /tmp/nostalgia-initramfs-list
    grep 'usr/lib64/plymouth/label-' /tmp/nostalgia-initramfs-list
    grep 'usr/share/plymouth/themes/nostalgia/nostalgia.script' /tmp/nostalgia-initramfs-list
    grep 'usr/lib/systemd/system/ostree-prepare-root.service' /tmp/nostalgia-initramfs-list
    grep -E 'usr/lib(exec)?/ostree/ostree-prepare-root' /tmp/nostalgia-initramfs-list
    rm /tmp/nostalgia-initramfs-list
done
[[ "$found" == 1 ]] || { echo "No image kernel found for initramfs generation" >&2; exit 1; }
