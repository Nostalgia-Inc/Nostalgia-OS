"""Exercise desktop-directory handling and migration of the old launcher."""

import os
from pathlib import Path
import subprocess
import tempfile
import unittest

SCRIPT = Path(__file__).resolve().parents[1] / "common/scripts/nostalgia-arduino-shortcut.sh"


@unittest.skipIf(os.name == "nt", "POSIX shortcut fixture requires Linux")
class ArduinoShortcutTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.home = self.root / "home"
        self.home.mkdir()
        self.desktop = self.home / "Escritorio"
        self.source = self.root / "cc.arduino.IDE2.desktop"
        self.source.write_text("[Desktop Entry]\nName=Arduino IDE 2\nExec=flatpak run cc.arduino.IDE2\n")
        self.script = self.root / "shortcut.sh"
        self.script.write_text(SCRIPT.read_text().replace(
            "/var/lib/flatpak/exports/share/applications/cc.arduino.IDE2.desktop", str(self.source)))
        for name, code in {"flatpak": "exit $APP_MISSING",
                           "xdg-user-dir": 'printf "%s\\n" "$DESKTOP_PATH"'}.items():
            tool = self.root / name
            tool.write_text("#!/usr/bin/bash\n" + code + "\n")
            tool.chmod(0o755)
        self.env = dict(os.environ, HOME=str(self.home), XDG_STATE_HOME=str(self.root / "state"),
                        PATH=str(self.root) + ":" + os.environ["PATH"],
                        DESKTOP_PATH=str(self.desktop), APP_MISSING="0")
        self.marker = self.root / "state/nostalgia/arduino-shortcut-v2"

    def run_shortcut(self):
        return subprocess.run(["bash", str(self.script)], env=self.env, capture_output=True, text=True)

    def test_localized_desktop_receives_actual_flatpak_launcher(self):
        self.assertEqual(self.run_shortcut().returncode, 0)
        target = self.desktop / "Arduino.desktop"
        self.assertEqual(target.read_text(), self.source.read_text())
        self.assertTrue(target.stat().st_mode & 0o100)
        self.assertTrue(self.marker.exists())

    def test_old_launcher_is_migrated(self):
        self.desktop.mkdir()
        (self.desktop / "Arduino.desktop").write_text("[Desktop Entry]\nExec=arduino\n")
        self.assertEqual(self.run_shortcut().returncode, 0)
        self.assertIn("cc.arduino.IDE2", (self.desktop / "Arduino.desktop").read_text())

    def test_user_shortcut_is_preserved(self):
        self.desktop.mkdir()
        target = self.desktop / "Arduino.desktop"
        target.write_text("Exec=my-custom-arduino\n")
        self.assertEqual(self.run_shortcut().returncode, 0)
        self.assertEqual(target.read_text(), "Exec=my-custom-arduino\n")

    def test_missing_application_remains_retryable(self):
        self.env["APP_MISSING"] = "1"
        self.assertNotEqual(self.run_shortcut().returncode, 0)
        self.assertFalse(self.marker.exists())
        self.assertFalse(self.desktop.exists())

    def test_disabled_desktop_does_not_create_icon_in_home(self):
        self.env["DESKTOP_PATH"] = str(self.home)
        self.assertEqual(self.run_shortcut().returncode, 0)
        self.assertFalse((self.home / "Arduino.desktop").exists())
        self.assertTrue(self.marker.exists())

    def test_completed_marker_preserves_subsequent_user_deletion(self):
        self.assertEqual(self.run_shortcut().returncode, 0)
        (self.desktop / "Arduino.desktop").unlink()
        self.assertEqual(self.run_shortcut().returncode, 0)
        self.assertFalse((self.desktop / "Arduino.desktop").exists())


if __name__ == "__main__":
    unittest.main()
