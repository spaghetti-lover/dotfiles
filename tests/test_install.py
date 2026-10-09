import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]


class InstallerTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="dotfiles-test-")
        self.addCleanup(self.temp.cleanup)
        self.base = Path(self.temp.name)
        self.home = self.base / "home with spaces"
        self.home.mkdir()
        self.repo = self.base / "checkout"
        shutil.copytree(ROOT, self.repo, ignore=shutil.ignore_patterns(".git", "__pycache__"))
        self.bin = self.base / "bin"
        self.bin.mkdir()
        self.platform("Linux")

    def platform(self, name):
        uname = self.bin / "uname"
        uname.write_text(f"#!/bin/sh\nprintf '%s\\n' '{name}'\n")
        uname.chmod(0o755)

    def run_link(self, mode, success=True):
        result = subprocess.run(
            ["bash", str(self.repo / "install/link.sh"), mode],
            env={**os.environ, "HOME": str(self.home), "PATH": f"{self.bin}:{os.environ['PATH']}"},
            text=True, capture_output=True,
        )
        if success:
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        else:
            self.assertNotEqual(result.returncode, 0)
        return result

    def assert_links(self, platform):
        for manifest in ("common", platform):
            for row in (self.repo / "install/links" / manifest).read_text().splitlines():
                source, destination = row.split("|")
                self.assertEqual((self.home / destination).resolve(), (self.repo / source).resolve())

    def test_preview_does_not_write(self):
        bashrc = self.home / ".bashrc"
        bashrc.write_text("original")
        self.run_link("--dry-run")
        self.assertEqual(list(self.home.iterdir()), [bashrc])
        self.assertEqual(bashrc.read_text(), "original")

    def test_backup_reapply_and_unlink_both_platforms(self):
        for system, platform in (("Linux", "omarchy"), ("Darwin", "macos")):
            with self.subTest(system=system):
                self.platform(system)
                config = self.home / ".config/nvim"
                config.mkdir(parents=True, exist_ok=True)
                (config / "personal.lua").write_text("original")
                dangling = self.home / ".tmux.conf"
                dangling.symlink_to(self.home / "missing")
                self.run_link("--apply")
                self.assert_links(platform)
                backups = list((self.home / ".local/state/dotfiles-backups").iterdir())
                latest = max(backups, key=lambda p: p.stat().st_mtime_ns)
                self.assertEqual((latest / ".config/nvim/personal.lua").read_text(), "original")
                self.assertTrue((latest / ".tmux.conf").is_symlink())
                self.run_link("--apply")
                self.assertEqual(set(backups), set((self.home / ".local/state/dotfiles-backups").iterdir()))
                self.run_link("--unlink")
                self.assertFalse(os.path.lexists(config))
                self.assertFalse(os.path.lexists(dangling))
                self.assertTrue((self.repo / "Makefile").exists())

    def test_checkout_at_dotfiles_is_never_moved_or_removed(self):
        destination = self.home / "dotfiles"
        self.repo.rename(destination)
        self.repo = destination
        self.run_link("--apply")
        self.run_link("--apply")
        self.run_link("--unlink")
        self.assertFalse(destination.is_symlink())
        self.assertTrue((destination / "Makefile").exists())

    def test_missing_source_fails_before_any_changes(self):
        (self.repo / "modules/bash/.bashrc").unlink()
        self.run_link("--apply", success=False)
        self.assertEqual(list(self.home.iterdir()), [])

    def test_unlink_keeps_files_and_foreign_links(self):
        self.run_link("--apply")
        bashrc = self.home / ".bashrc"
        bashrc.unlink()
        bashrc.write_text("personal")
        tmux = self.home / ".tmux.conf"
        tmux.unlink()
        tmux.symlink_to(self.home / "foreign")
        (self.repo / "modules/bash/.bashrc").unlink()
        self.run_link("--unlink")
        self.assertEqual(bashrc.read_text(), "personal")
        self.assertEqual(os.readlink(tmux), str(self.home / "foreign"))

    def test_legacy_stow_directory_does_not_write_into_repo(self):
        self.platform("Darwin")
        ghostty = self.home / ".config/ghostty"
        ghostty.parent.mkdir()
        source = self.repo / "modules/ghostty/.config/ghostty"
        ghostty.symlink_to(source)
        before = sorted(source.iterdir())
        self.run_link("--dry-run")
        self.assertTrue(ghostty.is_symlink())
        self.run_link("--apply")
        self.assert_links("macos")
        self.assertFalse(ghostty.is_symlink())
        self.assertEqual(sorted(source.iterdir()), before)
        self.run_link("--unlink")
        self.assertEqual(sorted(source.iterdir()), before)

    def test_checkout_inside_destination_is_rejected(self):
        parent = self.home / "dotfiles"
        parent.mkdir()
        self.repo.rename(parent / "checkout")
        self.repo = parent / "checkout"
        self.run_link("--apply", success=False)
        self.assertEqual(list(self.home.iterdir()), [parent])
        self.run_link("--unlink")
        self.assertTrue((self.repo / "Makefile").exists())

    def test_invalid_mode_and_platform_fail_without_writes(self):
        self.run_link("--unknown", success=False)
        self.platform("FreeBSD")
        self.run_link("--apply", success=False)
        self.assertEqual(list(self.home.iterdir()), [])


if __name__ == "__main__":
    unittest.main()
