"""Exercise CPU policy selection against fake sysfs files, without host tuning."""

from pathlib import Path
import os
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "images/nostalgia-crt/scripts/nostalgia-power-tuning.sh"


@unittest.skipIf(os.name == "nt", "CPU sysfs fixtures require a POSIX filesystem; run in WSL")
class CpuGovernorTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="nostalgia-cpu-policy-")
        self.addCleanup(self.temp.cleanup)
        self.base = Path(self.temp.name)
        self.policy = self.base / "cpufreq/policy0"
        self.policy.mkdir(parents=True)
        self.current = self.policy / "scaling_governor"
        self.current.write_text("performance\n")
        source = SOURCE.read_text(encoding="utf-8")
        # Stop before every non-CPU operation; the one remaining sysfs path is
        # replaced by our fixture. No real /sys paths are executed in this test.
        source = source.split("# ── Turbo Boost Configuration", 1)[0]
        source = source.replace("/sys/devices/system/cpu/cpufreq", str(self.base / "cpufreq"))
        self.script = self.base / "cpu.sh"
        self.script.write_text(source)
        self.bash = shutil.which("bash")
        if not self.bash:
            self.skipTest("Bash is required")

    def select(self, available):
        (self.policy / "scaling_available_governors").write_text(available + "\n")
        result = subprocess.run(
            [self.bash, str(self.script)],
            capture_output=True, text=True, timeout=10,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        return self.current.read_text().strip(), result.stdout

    def test_schedutil_when_supported(self):
        actual, output = self.select("performance powersave schedutil")
        self.assertEqual(actual, "schedutil")
        self.assertIn("policy0: schedutil governor", output)

    def test_intel_pstate_uses_supported_powersave(self):
        actual, output = self.select("performance powersave")
        self.assertEqual(actual, "powersave")
        self.assertIn("policy0: powersave governor", output)

    def test_unsupported_policy_is_preserved(self):
        actual, output = self.select("performance")
        self.assertEqual(actual, "performance")
        self.assertIn("retaining current policy", output)


if __name__ == "__main__":
    unittest.main()
