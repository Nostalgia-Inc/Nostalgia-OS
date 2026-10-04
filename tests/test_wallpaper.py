"""Isolated startup regressions: python3 -m unittest discover -s tests -v.

Startup tests require Linux/POSIX, Bash and coreutils. Node.js checks the Plasma JavaScript
against desktop objects. No real user configuration or D-Bus session is touched.
"""

import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "images/nostalgia-crt/scripts/nostalgia-apply-wallpaper.sh"


@unittest.skipIf(os.name == "nt", "Startup fixtures require a POSIX filesystem; run in WSL")
class WallpaperStartupTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="nostalgia-wallpaper-")
        self.addCleanup(self.temp.cleanup)
        self.base = Path(self.temp.name)
        self.bin = self.base / "bin"
        self.bin.mkdir()
        self.asset = self.base / "Nostalgia.png"
        self.asset.touch()
        self.marker = self.base / "state/nostalgia/wallpaper-applied"
        self.script = self.base / "apply.sh"
        self.script.write_text(
            SOURCE.read_text(encoding="utf-8").replace(
                "/usr/share/nostalgia/Nostalgia.png", str(self.asset)
            ).replace("WAIT_SECONDS=60", "WAIT_SECONDS=2")
        )
        self.bash = shutil.which("bash")
        if not self.bash:
            self.skipTest("Bash is required")
        for command in ("timeout", "sleep", "mkdir", "touch"):
            executable = shutil.which(command)
            if not executable:
                self.skipTest(f"{command} is required")
            (self.bin / command).symlink_to(executable)
        self.env = {
            **os.environ,
            "HOME": str(self.base),
            "XDG_STATE_HOME": str(self.base / "state"),
            "PATH": str(self.bin),
            "TEST_CALLS": str(self.base / "calls"),
        }

    def fake_qdbus(self, name="qdbus6", response="echo nostalgia-wallpaper-applied:2"):
        tool = self.bin / name
        tool.write_text(f"#!{self.bash}\necho call >> \"$TEST_CALLS\"\n{response}\n")
        tool.chmod(0o755)

    def run_script(self):
        return subprocess.run(
            [self.bash, str(self.script)], env=self.env,
            capture_output=True, text=True, timeout=10,
        )

    def test_qt6_success_records_marker(self):
        self.fake_qdbus()
        result = self.run_script()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue(self.marker.exists())

    def test_alternate_qt6_name(self):
        self.fake_qdbus(name="qdbus-qt6")
        self.assertEqual(self.run_script().returncode, 0)
        self.assertTrue(self.marker.exists())

    def test_existing_marker_preserves_user_choice(self):
        self.fake_qdbus()
        self.marker.parent.mkdir(parents=True)
        self.marker.touch()
        self.assertEqual(self.run_script().returncode, 0)
        self.assertFalse((self.base / "calls").exists())

    def test_missing_asset_does_not_record_success(self):
        self.fake_qdbus()
        self.asset.unlink()
        self.assertNotEqual(self.run_script().returncode, 0)
        self.assertFalse(self.marker.exists())

    def test_missing_dbus_tool_does_not_record_success(self):
        self.assertNotEqual(self.run_script().returncode, 0)
        self.assertFalse(self.marker.exists())

    def test_dbus_failure_does_not_record_success(self):
        self.fake_qdbus(response="echo 'Plasma unavailable' >&2; exit 1")
        self.assertNotEqual(self.run_script().returncode, 0)
        self.assertFalse(self.marker.exists())

    def test_empty_or_unexpected_reply_does_not_record_success(self):
        self.fake_qdbus(response="echo nostalgia-wallpaper-applied:0")
        self.assertNotEqual(self.run_script().returncode, 0)
        self.assertFalse(self.marker.exists())

    def test_delayed_plasma_retries_and_then_succeeds(self):
        self.fake_qdbus(response='''
if [[ ! -f "$HOME/ready" ]]; then
    touch "$HOME/ready"
    echo "Plasma desktops are not ready" >&2
    exit 1
fi
echo nostalgia-wallpaper-applied:2
''')
        result = self.run_script()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue(self.marker.exists())
        self.assertEqual((self.base / "calls").read_text().count("call"), 2)

    def test_setup_missing_kde_tool_remains_retryable(self):
        for variant, marker in (
            ("nostalgia-crt", "setup-complete"),
            ("nostalgia-arcade", "arcade-setup-complete"),
        ):
            with self.subTest(variant=variant):
                script = next((ROOT / "images" / variant / "scripts").glob("10-*.sh"))
                result = subprocess.run(
                    [self.bash, str(script)], env=self.env,
                    capture_output=True, text=True, timeout=10,
                )
                self.assertNotEqual(result.returncode, 0)
                self.assertIn("requires kwriteconfig6", result.stderr)
                self.assertFalse((self.marker.parent / marker).exists())


@unittest.skipUnless(shutil.which("node"), "Node.js is required for Plasma script tests")
class PlasmaScriptTests(unittest.TestCase):
    def run_js(self, desktops):
        source = SOURCE.read_text(encoding="utf-8")
        script = source.split('SCRIPT="\n', 1)[1].split('\n"', 1)[0]
        script = script.replace("${TARGET_IMAGE}", "file:///usr/share/nostalgia/Nostalgia.png")
        harness = """
const assert = require('node:assert/strict');
const target = 'file:///usr/share/nostalgia/Nostalgia.png';
function makeDesktop() {
    return {
        config: {},
        writeConfig(key, value) { this.config[key] = value; },
        readConfig(key) { return this.config[key]; }
    };
}
const output = [];
function print(text) { output.push(text); }
""" + desktops + "\n" + script
        return subprocess.run(
            [shutil.which("node"), "-e", harness],
            capture_output=True, text=True, timeout=10,
        )

    def test_multiple_desktops_updated_and_confirmed(self):
        desktops = "const items = [makeDesktop(), makeDesktop()]; function desktops() { return items; }"
        # The assertions run after the script, before the Node process exits.
        suffix = """
process.on('exit', () => {
    assert.deepEqual(output, ['nostalgia-wallpaper-applied:2']);
    for (const item of items) {
        assert.equal(item.wallpaperPlugin, 'org.kde.image');
        assert.deepEqual(item.currentConfigGroup, ['Wallpaper', 'org.kde.image', 'General']);
        assert.equal(item.config.Image, target);
        assert.equal(item.config.PreviewImage, target);
    }
});
"""
        result = self.run_js(desktops + suffix)
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_no_desktops_is_failure(self):
        result = self.run_js("function desktops() { return []; }")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Plasma desktops are not ready", result.stderr)

    def test_rejected_config_is_failure(self):
        result = self.run_js("""
function desktops() {
    const item = makeDesktop();
    item.readConfig = () => 'unchanged';
    return [item];
}
""")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Wallpaper configuration was not accepted", result.stderr)


if __name__ == "__main__":
    unittest.main()
