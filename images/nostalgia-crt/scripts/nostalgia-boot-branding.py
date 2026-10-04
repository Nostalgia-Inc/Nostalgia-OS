#!/usr/bin/python3
"""Install GRUB branding through its custom.cfg hook without regenerating BLS."""

import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile

BEGIN = "# BEGIN NOSTALGIA THEME"
END = "# END NOSTALGIA THEME"
BLOCK = f"""{BEGIN}
insmod all_video
insmod gfxterm
insmod gfxmenu
if loadfont $prefix/themes/nostalgia/unicode.pf2; then
  set gfxmode=auto
  terminal_output gfxterm
  set theme=$prefix/themes/nostalgia/theme.txt
  export theme
  set timeout_style=menu
  if [ -z "$timeout" ]; then
    set timeout=5
  elif [ "$timeout" -ge 0 -a "$timeout" -lt 5 ]; then
    set timeout=5
  fi
fi
{END}
"""


def merge_config(original):
    """Replace only our marked block; refuse ambiguous or incomplete markers."""
    if original.count(BEGIN) != original.count(END) or original.count(BEGIN) > 1:
        raise ValueError("Unbalanced or repeated Nostalgia markers in custom.cfg")
    if BEGIN in original:
        pattern = rf"(?m)^{re.escape(BEGIN)}\n.*?^{re.escape(END)}(?:\n|$)"
        result, count = re.subn(pattern, BLOCK, original, flags=re.S)
        if count != 1:
            raise ValueError("Invalid Nostalgia block in custom.cfg")
        return result
    return original + ("\n" if original and not original.endswith("\n") else "") + BLOCK


def configure(boot_dir=Path("/boot/grub2"), asset_dir=Path("/usr/share/grub/themes/nostalgia-grub"),
              font=Path("/usr/share/grub/unicode.pf2"), checker="grub2-script-check"):
    grub_config = boot_dir / "grub.cfg"
    if not grub_config.is_file() or "custom.cfg" not in grub_config.read_text():
        raise RuntimeError("No supported /boot/grub2/grub.cfg custom.cfg hook; leaving boot configuration unchanged")
    target = boot_dir / "custom.cfg"
    if target.is_symlink():
        raise RuntimeError("custom.cfg is a symlink; refusing to replace it")
    original = target.read_text() if target.exists() else ""
    updated = merge_config(original)
    with tempfile.NamedTemporaryFile(mode="w", dir=boot_dir, prefix=".nostalgia-", delete=False) as pending:
        pending.write(updated)
        temporary = Path(pending.name)
    try:
        subprocess.run([checker, str(temporary)], check=True)
        theme_dir = boot_dir / "themes/nostalgia"
        theme_dir.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(asset_dir / "theme.txt", theme_dir / "theme.txt")
        shutil.copyfile(font, theme_dir / "unicode.pf2")
        for asset in theme_dir.iterdir():
            asset.chmod(0o644)
        if updated != original:
            backup = target.with_name("custom.cfg.nostalgia-backup")
            if target.exists() and not backup.exists():
                with backup.open("x") as previous:
                    previous.write(original)
                backup.chmod(0o600)
            temporary.chmod(0o644)
            os.replace(temporary, target)
        print("Nostalgia GRUB theme installed; it will appear at the next boot")
    finally:
        temporary.unlink(missing_ok=True)


if __name__ == "__main__":
    configure()
