"""Regressions for preserving boot configuration during theme activation."""

import importlib.util
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch

MODULE_PATH = Path(__file__).resolve().parents[1] / "images/nostalgia-crt/scripts/nostalgia-boot-branding.py"
SPEC = importlib.util.spec_from_file_location("boot_branding", MODULE_PATH)
BRANDING = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(BRANDING)


class BootBrandingTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.boot = self.root / "grub2"
        self.boot.mkdir()
        (self.boot / "grub.cfg").write_text("blscfg\nsource $prefix/custom.cfg\n")
        self.assets = self.root / "assets"
        self.assets.mkdir()
        (self.assets / "theme.txt").write_text("theme asset")
        self.font = self.root / "font.pf2"
        self.font.write_bytes(b"font asset")

    def configure(self):
        BRANDING.configure(self.boot, self.assets, self.font)

    @patch.object(BRANDING.subprocess, "run")
    def test_preserves_custom_entries_and_is_idempotent(self, check):
        original = "# user's configuration\nmenuentry 'Rescue' { echo rescue; }\n"
        custom = self.boot / "custom.cfg"
        custom.write_text(original)
        self.configure()
        first = custom.read_text()
        self.configure()
        self.assertEqual(custom.read_text(), first)
        self.assertTrue(first.startswith(original))
        self.assertEqual(first.count(BRANDING.BEGIN), 1)
        self.assertEqual((self.boot / "custom.cfg.nostalgia-backup").read_text(), original)
        self.assertEqual((self.boot / "grub.cfg").read_text(), "blscfg\nsource $prefix/custom.cfg\n")
        self.assertEqual((self.boot / "themes/nostalgia/unicode.pf2").read_bytes(), b"font asset")
        self.assertTrue(check.call_args.kwargs["check"])

    def test_replaces_only_managed_block(self):
        old = f"before\n{BRANDING.BEGIN}\nold theme\n{BRANDING.END}\nafter\n"
        self.assertEqual(BRANDING.merge_config(old), "before\n" + BRANDING.BLOCK + "after\n")

    def test_refuses_malformed_markers(self):
        for invalid in (BRANDING.BEGIN, BRANDING.END, BRANDING.BLOCK * 2,
                        BRANDING.END + "\n" + BRANDING.BEGIN):
            with self.subTest(invalid=invalid), self.assertRaises(ValueError):
                BRANDING.merge_config(invalid)

    @patch.object(BRANDING.subprocess, "run", side_effect=subprocess.CalledProcessError(1, "grub2-script-check"))
    def test_failed_validation_leaves_configuration_and_assets_unchanged(self, check):
        custom = self.boot / "custom.cfg"
        custom.write_text("original\n")
        with self.assertRaises(subprocess.CalledProcessError):
            self.configure()
        self.assertEqual(custom.read_text(), "original\n")
        self.assertFalse((self.boot / "themes").exists())
        self.assertFalse(list(self.boot.glob(".nostalgia-*")))

    def test_unsupported_hook_leaves_boot_directory_unchanged(self):
        (self.boot / "grub.cfg").write_text("blscfg\n")
        with self.assertRaises(RuntimeError):
            self.configure()
        self.assertFalse((self.boot / "custom.cfg").exists())


if __name__ == "__main__":
    unittest.main()
