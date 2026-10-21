"""Exercise the real shell launcher with isolated USB/debug-tool stand-ins."""
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class LauncherTests(unittest.TestCase):
    def run_launcher(self, *, connected=True, stop_status=255, launch_status=0):
        with tempfile.TemporaryDirectory() as tmp:
            folder = Path(tmp)
            log = folder / 'calls'
            mock = '''#!/bin/bash
name="${0##*/}"
echo "$name $*" >> "$CALL_LOG"
case "$name" in
  idevice_id) [[ "$CONNECTED" == 1 ]] && echo test-device; exit 0 ;;
  ideviceimagemounter) echo 'ImagePresent: true' ;;
  idevicedebug) [[ "$*" == *' kill '* ]] && exit "$STOP_STATUS"; exit "$LAUNCH_STATUS" ;;
  open) exit 0 ;;
esac
'''
            for name in ('idevice_id', 'ideviceimagemounter', 'idevicedebug', 'open'):
                path = folder / name
                path.write_text(mock)
                path.chmod(0o755)
            env = dict(os.environ, PATH=f'{folder}:/usr/bin:/bin', CALL_LOG=str(log),
                       CONNECTED=str(int(connected)), STOP_STATUS=str(stop_status),
                       LAUNCH_STATUS=str(launch_status))
            result = subprocess.run(['/bin/bash', str(ROOT / 'scripts/launch.sh'),
                                     'test-device', str(folder / 'image.dmg')],
                                    env=env, capture_output=True, text=True, timeout=10)
            return result, log.read_text().splitlines() if log.exists() else []

    def test_stop_precedes_launch_even_with_legacy_kill_status(self):
        result, calls = self.run_launcher()
        self.assertEqual(result.returncode, 0, result.stderr)
        debug = [line for line in calls if line.startswith('idevicedebug ')]
        self.assertEqual(debug, [
            'idevicedebug -u test-device kill com.sheneyan.oldipad.display',
            'idevicedebug -u test-device --detach run com.sheneyan.oldipad.display'])
        self.assertEqual(calls[-1], 'open -g -a OpenDisplay')

    def test_missing_device_does_not_stop_or_launch(self):
        result, calls = self.run_launcher(connected=False)
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse(any('idevicedebug' in line for line in calls))

    def test_failed_launch_is_not_reported_as_success(self):
        result, calls = self.run_launcher(launch_status=1)
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse(any(line.startswith('open ') for line in calls))

    def test_stop_timeout_does_not_launch(self):
        result, calls = self.run_launcher(stop_status=142)
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse(any('--detach run' in line for line in calls))


if __name__ == '__main__':
    unittest.main()
