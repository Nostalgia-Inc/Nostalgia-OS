"""Exercise installer failures and retries without downloading Flatpaks."""

import os
from pathlib import Path
import subprocess
import tempfile
import unittest

SCRIPT = Path(__file__).resolve().parents[1] / "common/scripts/nostalgia-arduino-install.sh"


@unittest.skipIf(os.name == "nt", "POSIX installer fixture requires Linux")
class ArduinoInstallerTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.log = self.root / "calls"
        self.installed = self.root / "installed"
        flatpak = self.root / "flatpak"
        flatpak.write_text("""#!/usr/bin/bash
echo "$*" >> "$CALLS"
case "$1" in
  info) test -f "$INSTALLED" ;;
  remote-add) exit 0 ;;
  install)
    [[ "$FAIL_DOWNLOAD" != 1 ]] || exit 1
    [[ "$FALSE_SUCCESS" == 1 ]] || touch "$INSTALLED"
    exit 0 ;;
  *) exit 2 ;;
esac
""")
        flatpak.chmod(0o755)
        self.env = dict(os.environ, PATH=str(self.root) + ":" + os.environ["PATH"],
                        CALLS=str(self.log), INSTALLED=str(self.installed),
                        FAIL_DOWNLOAD="0", FALSE_SUCCESS="0")

    def run_installer(self):
        return subprocess.run(["bash", str(SCRIPT)], env=self.env, capture_output=True, text=True)

    def test_installed_application_skips_network(self):
        self.installed.touch()
        self.assertEqual(self.run_installer().returncode, 0)
        self.assertEqual(self.log.read_text(), "info --system cc.arduino.IDE2\n")

    def test_failed_download_can_be_retried(self):
        self.env["FAIL_DOWNLOAD"] = "1"
        self.assertNotEqual(self.run_installer().returncode, 0)
        self.assertFalse(self.installed.exists())
        self.env["FAIL_DOWNLOAD"] = "0"
        self.assertEqual(self.run_installer().returncode, 0)
        self.assertTrue(self.installed.exists())
        self.assertIn("install --system --assumeyes --noninteractive flathub cc.arduino.IDE2", self.log.read_text())

    def test_false_installer_success_is_rejected(self):
        self.env["FALSE_SUCCESS"] = "1"
        self.assertNotEqual(self.run_installer().returncode, 0)


if __name__ == "__main__":
    unittest.main()
