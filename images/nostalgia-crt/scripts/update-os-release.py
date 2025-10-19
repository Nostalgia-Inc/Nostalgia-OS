#!/usr/bin/python3
import pathlib

release_path = pathlib.Path("/usr/lib/os-release")
if release_path.exists():
    replacements = {
        "NAME": "Nostalgia OS",
        "PRETTY_NAME": "Nostalgia OS 42",
        "VARIANT": "Nostalgia CRT (KDE)",
        "VARIANT_ID": "nostalgia-crt",
    }

    lines = release_path.read_text().splitlines()
    updated = []
    for line in lines:
        if "=" not in line or line.startswith("#"):
            updated.append(line)
            continue
        key, value = line.split("=", 1)
        if key in replacements:
            updated.append(f'{key}="{replacements[key]}"')
        else:
            updated.append(line)

    release_path.write_text("\n".join(updated) + "\n")

link = pathlib.Path("/etc/os-release")
if link.exists() or link.is_symlink():
    link.unlink()
link.symlink_to("../usr/lib/os-release")
