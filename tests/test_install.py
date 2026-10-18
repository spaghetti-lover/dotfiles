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

    def run_link(self, mode, *modules, success=True):
        return self.run_script("link.sh", mode, *modules, success=success)

    def run_script(self, script, *args, success=True):
        result = subprocess.run(
            ["bash", str(self.repo / "install" / script), *args],
            env={**os.environ, "HOME": str(self.home), "PATH": f"{self.bin}:{os.environ['PATH']}"},
            text=True, capture_output=True,
        )
        if success:
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        else:
            self.assertNotEqual(result.returncode, 0)
        return result

    def manifest(self, module, platform):
        """Entries of a module.conf that apply on platform, as (kind, value) pairs."""
        entries = []
        for line in (self.repo / "modules" / module / "module.conf").read_text().splitlines():
            if not line.strip() or line.lstrip().startswith("#"):
                continue
            key, value = line.split(maxsplit=1)
            kind, _, scope = key.partition("@")
            if scope in ("", platform):
                entries.append((kind, value.strip()))
        return entries

    def expected_links(self, platform, modules=None):
        links = {"dotfiles": "."}
        for conf in sorted((self.repo / "modules").glob("*/module.conf")):
            module = conf.parent.name
            entries = self.manifest(module, platform)
            allowed = [p for kind, value in entries if kind == "platforms" for p in value.split()]
            if (modules and module not in modules) or (allowed and platform not in allowed):
                continue
            for kind, value in entries:
                if kind == "link":
                    source, _, destination = value.partition("|")
                    links[destination or source] = f"modules/{module}/{source}"
        return links

    def assert_links(self, platform, modules=None):
        for destination, source in self.expected_links(platform, modules).items():
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

    def test_invalid_manifest_entry_fails_before_any_changes(self):
        with (self.repo / "modules/yazi/module.conf").open("a") as conf:
            conf.write("lnk .config/typo\n")
        self.run_link("--apply", success=False)
        self.run_link("--apply", "nope", success=False)
        self.assertEqual(list(self.home.iterdir()), [])

    def test_named_modules_link_only_themselves(self):
        self.run_link("--apply", "yazi", "tmux")
        self.assert_links("omarchy", {"yazi", "tmux"})
        self.assertFalse((self.home / ".bashrc").exists())
        result = self.run_link("--apply", "zsh")
        self.assertIn("skip: zsh", result.stderr)
        self.assertFalse((self.home / ".zshrc").exists())

    def test_stale_repo_link_is_replaced_without_backup(self):
        platform_conf = self.home / ".config/ghostty/platform.conf"
        platform_conf.parent.mkdir(parents=True)
        platform_conf.symlink_to(self.repo / "modules/ghostty-omarchy/platform.conf")
        self.run_link("--apply", "ghostty")
        self.assert_links("omarchy", {"ghostty"})
        self.assertFalse((self.home / ".local/state/dotfiles-backups").exists())

    def test_brewfile_follows_platform(self):
        for system, platform in (("Linux", "omarchy"), ("Darwin", "macos")):
            with self.subTest(system=system):
                self.platform(system)
                lines = self.run_script("packages.sh", "--print").stdout.splitlines()
                self.assertEqual(len(lines), len(set(lines)))
                kinds = [line.split()[0] for line in lines]
                self.assertEqual(kinds, sorted(kinds, key=["tap", "brew", "cask", "go", "cargo"].index))
                expected = set()
                for conf in (self.repo / "modules").glob("*/module.conf"):
                    entries = self.manifest(conf.parent.name, platform)
                    allowed = [p for kind, value in entries if kind == "platforms" for p in value.split()]
                    if allowed and platform not in allowed:
                        continue
                    for kind, value in entries:
                        if kind in ("tap", "brew", "go", "cargo") or (kind == "cask" and platform == "macos"):
                            expected.add(f'{kind} "{value}"')
                self.assertEqual(set(lines), expected)
        self.assertIn('cask "ghostty"', lines)
        self.assertIn('brew "asmvik/formulae/yabai"', lines)

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
