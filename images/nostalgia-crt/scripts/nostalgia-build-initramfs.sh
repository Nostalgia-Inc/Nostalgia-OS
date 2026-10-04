#!/usr/bin/bash
set -euo pipefail

plymouth-set-default-theme nostalgia
found=0
for kernel_dir in /usr/lib/modules/*; do
    [[ -f "$kernel_dir/vmlinuz" ]] || continue
    found=1
    # Explicit image kernel: uname here would select the container host's kernel.
    dracut --force --no-hostonly --kver "${kernel_dir##*/}" "$kernel_dir/initramfs.img"
    # Inspect the complete listing without causing a pipefail/SIGPIPE failure.
    lsinitrd "$kernel_dir/initramfs.img" > /tmp/nostalgia-initramfs-list
    grep 'usr/lib64/plymouth/script.so' /tmp/nostalgia-initramfs-list
    grep 'usr/share/plymouth/themes/nostalgia/nostalgia.script' /tmp/nostalgia-initramfs-list
    rm /tmp/nostalgia-initramfs-list
done
[[ "$found" == 1 ]] || { echo "No image kernel found for initramfs generation" >&2; exit 1; }
