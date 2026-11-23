"""Regression fixtures for the golden comparator's path and byte checks."""

import os
import subprocess
import sys
from pathlib import Path

SCRIPT = Path(__file__).resolve().parents[2] / "_scripts/diagnostics/golden_diff.py"


def test_complete_tree_diff(tmp_path):
    before = tmp_path / "before"
    after = tmp_path / "after"
    asset = Path(".well-known/binary")
    for root in (before, after):
        (root / asset.parent).mkdir(parents=True)
        (root / asset).write_bytes(b"\x00\xff")
        (root / "link").symlink_to("missing-target")
    command = [sys.executable, SCRIPT, before, after]
    assert subprocess.check_output(command) == b""

    # A shallow comparison mistakes different bytes of equal size and mtime for a match.
    (after / asset).write_bytes(b"\x00\xfe")
    for root in (before, after):
        os.utime(root / asset, (1, 1))
    (before / "old.html").touch()
    (after / "new.html").touch()
    (after / "link").unlink()
    (after / "link").symlink_to("./missing-target")

    diff = subprocess.run(command, capture_output=True, text=True)
    assert diff.returncode == 1
    assert diff.stdout.splitlines() == [
        "missing old.html",
        "extra new.html",
        "changed .well-known/binary",
        "changed link",
    ]
