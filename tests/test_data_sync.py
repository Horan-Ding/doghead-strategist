"""Offline integration tests: isolated repos only; never read real archives."""
import fcntl
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import time
import unittest

ROOT = Path(__file__).resolve().parents[1]


class DataSyncTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix='goutou-sync-test-')
        self.addCleanup(self.tmp.cleanup)
        self.base = Path(self.tmp.name)
        self.code = self.base / 'code'
        (self.code / 'scripts').mkdir(parents=True)
        for name in ('sync-data-repo.sh', 'auto-sync-data-repo.sh', 'ensure-data-repo.sh', 'init-local-data.sh'):
            shutil.copy2(ROOT / 'scripts' / name, self.code / 'scripts' / name)
        self.remote = self.base / 'remote.git'
        self.data = self.base / 'data'
        self.git('init', '--bare', '--initial-branch=main', str(self.remote), cwd=self.base)
        self.git('clone', str(self.remote), str(self.data), cwd=self.base)
        self.git('config', 'user.name', 'Synthetic Test')
        self.git('config', 'user.email', 'test@example.invalid')
        (self.data / 'record.txt').write_text('initial\n')
        self.git('add', '.')
        self.git('commit', '-m', 'initial')
        self.git('push', 'origin', 'main')
        self.env = os.environ.copy()
        self.env.update(GOUTOU_DATA_DIR=str(self.data), GOUTOU_DATA_REPO_URL=str(self.remote), GOUTOU_DATA_BRANCH='main', GOUTOU_SYNC_INTERVAL_SECONDS='1')

    def git(self, *args, cwd=None):
        return subprocess.check_output(['git', *args], cwd=cwd or self.data, stderr=subprocess.DEVNULL, text=True).strip()

    def run_script(self, name='sync-data-repo.sh', *args):
        return subprocess.run(['bash', str(self.code / 'scripts' / name), *args], env=self.env, capture_output=True, text=True, timeout=15)

    def assert_synced(self):
        self.assertEqual(self.git('rev-parse', 'HEAD'), self.git('rev-parse', 'main', cwd=self.remote))

    def test_retry_pushes_existing_commit_without_new_edits(self):
        hook = self.remote / 'hooks' / 'pre-receive'
        hook.write_text('#!/bin/sh\nexit 1\n')
        hook.chmod(0o700)
        (self.data / 'record.txt').write_text('new\n')
        self.assertEqual(self.run_script().returncode, 1)
        committed = self.git('rev-parse', 'HEAD')
        hook.unlink()
        self.assertEqual(self.run_script().returncode, 0)
        self.assertEqual(committed, self.git('rev-parse', 'HEAD'))
        self.assert_synced()

    def test_fetch_failure_preserves_visible_edits_without_stash(self):
        self.git('remote', 'set-url', 'origin', str(self.base / 'missing.git'))
        (self.data / 'new.txt').write_text('saved locally\n')
        self.assertEqual(self.run_script().returncode, 1)
        self.assertEqual((self.data / 'new.txt').read_text(), 'saved locally\n')
        self.assertEqual(self.git('show', 'HEAD:new.txt'), 'saved locally')
        self.assertEqual(self.git('stash', 'list'), '')

    def other_commit(self, name, content):
        other = self.base / 'other'
        self.git('clone', str(self.remote), str(other), cwd=self.base)
        self.git('config', 'user.name', 'Synthetic Test', cwd=other)
        self.git('config', 'user.email', 'test@example.invalid', cwd=other)
        (other / name).write_text(content)
        self.git('add', '.', cwd=other)
        self.git('commit', '-m', 'remote change', cwd=other)
        self.git('push', 'origin', 'main', cwd=other)

    def test_remote_pull_and_branch_override(self):
        self.git('branch', '-m', 'main', 'work')
        self.other_commit('remote.txt', 'remote\n')
        (self.data / 'local.txt').write_text('local\n')
        self.assertEqual(self.run_script().returncode, 0)
        self.assertEqual((self.data / 'remote.txt').read_text(), 'remote\n')
        self.assertEqual((self.data / 'local.txt').read_text(), 'local\n')
        self.assert_synced()

    def test_conflict_pauses_retries(self):
        self.other_commit('record.txt', 'remote\n')
        (self.data / 'record.txt').write_text('local\n')
        self.assertEqual(self.run_script().returncode, 2)
        contents = (self.data / 'record.txt').read_bytes()
        self.assertEqual(self.run_script().returncode, 2)
        self.assertEqual(contents, (self.data / 'record.txt').read_bytes())

    def test_writer_lock_defers_sync(self):
        with (self.data / '.git' / 'goutou-sync.lock').open('w') as lock:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
            self.assertEqual(self.run_script().returncode, 75)

    def test_ensure_existing_checkout_does_not_pull(self):
        (self.data / 'config.yaml').write_text('version: 1\n')
        (self.data / 'me').mkdir()
        (self.data / 'me' / 'profile.yaml').write_text('version: 1\n')
        self.git('remote', 'set-url', 'origin', str(self.base / 'missing.git'))
        self.assertEqual(self.run_script('ensure-data-repo.sh').returncode, 0)

    def test_scheduler_start_repeat_sync_status_stop(self):
        def stop():
            self.run_script('auto-sync-data-repo.sh', 'stop')
            deadline = time.monotonic() + 5
            while time.monotonic() < deadline:
                if self.run_script('auto-sync-data-repo.sh', 'status').returncode:
                    return
                time.sleep(.05)
            self.fail('scheduler did not stop')
        self.addCleanup(stop)
        (self.data / 'new.txt').write_text('scheduled\n')
        result = self.run_script('auto-sync-data-repo.sh', 'start')
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        state = self.code / '.goutou' / 'auto-sync'
        pid = (state / 'pid').read_text()
        self.assertEqual(self.run_script('auto-sync-data-repo.sh', 'start').returncode, 0)
        self.assertEqual(pid, (state / 'pid').read_text())
        self.assertFalse((state / 'last-result').exists(), 'sync should wait one interval')
        deadline = time.monotonic() + 8
        while not (state / 'last-result').exists() and time.monotonic() < deadline:
            time.sleep(.05)
        self.assertIn('exit=0', (state / 'last-result').read_text())
        self.assert_synced()
        self.assertIn('exit=0', self.run_script('auto-sync-data-repo.sh', 'status').stdout)


if __name__ == '__main__':
    unittest.main()
