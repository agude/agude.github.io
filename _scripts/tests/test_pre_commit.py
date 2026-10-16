"""Tests for _bin/pre-commit.sh, run as a subprocess in a temporary Git repository.

The hook needs a real Git index, so these tests run on the host, not in the
Ruby test container. Stub `docker` and `uv` executables go first on PATH and
apply a deterministic "format" (stripping trailing whitespace) to the files
they are handed. A `git` wrapper can be told to fail `git stash push`.
"""

import os
import shutil
import subprocess
import textwrap
from pathlib import Path

import pytest

HOOK = Path(__file__).resolve().parents[2] / "_bin" / "pre-commit.sh"
REAL_GIT = shutil.which("git")

# Formats every argument that names a source file in the current directory.
# STUB_FORMATTER_EXIT sets the exit code; each call is logged.
FORMATTER_STUB = textwrap.dedent(
    """\
    #!/bin/bash
    echo "$(basename "$0") $*" >> "$STUB_LOG"
    for arg in "$@"; do
      case "$arg" in
        *.rb|*.md|*.py)
          [ -f "$arg" ] && sed -i 's/[[:space:]]*$//' "$arg"
          ;;
      esac
    done
    exit "${STUB_FORMATTER_EXIT:-0}"
    """
)

GIT_WRAPPER = textwrap.dedent(
    f"""\
    #!/bin/bash
    if [ "$FAIL_STASH_PUSH" = 1 ] && [ "$1" = stash ] && [ "$2" = push ]; then
      echo "fatal: simulated stash push failure" >&2
      exit 1
    fi
    exec {REAL_GIT} "$@"
    """
)

ORIGINAL = "".join(f"line {n}\n" for n in range(1, 11))


def replace_line(text: str, number: int, new: str) -> str:
    lines = text.splitlines(keepends=True)
    lines[number - 1] = new + "\n"
    return "".join(lines)


class Repo:
    """A throwaway Git repository with the hook and PATH stubs installed."""

    def __init__(self, root: Path):
        self.root = root / "repo"
        self.bin = root / "bin"
        self.log = root / "stub.log"
        self.root.mkdir()
        self.bin.mkdir()
        for name in ("docker", "uv"):
            self._write_executable(self.bin / name, FORMATTER_STUB)
        self._write_executable(self.bin / "git", GIT_WRAPPER)
        self.env = {key: value for key, value in os.environ.items() if not key.startswith("GIT_")}
        self.env.update(
            PATH=f"{self.bin}{os.pathsep}{os.environ['PATH']}",
            STUB_LOG=str(self.log),
            GIT_AUTHOR_NAME="Test",
            GIT_AUTHOR_EMAIL="test@example.com",
            GIT_COMMITTER_NAME="Test",
            GIT_COMMITTER_EMAIL="test@example.com",
            GIT_CONFIG_GLOBAL=os.devnull,
            GIT_CONFIG_SYSTEM=os.devnull,
        )
        self.git("init", "-q", "-b", "main")
        self.write("a.rb", ORIGINAL)
        self.git("add", "a.rb")
        self.git("commit", "-q", "-m", "initial")

    @staticmethod
    def _write_executable(path: Path, content: str) -> None:
        path.write_text(content)
        path.chmod(0o755)

    def git(self, *args: str) -> str:
        result = subprocess.run(
            [REAL_GIT, *args],
            cwd=self.root,
            env=self.env,
            capture_output=True,
            text=True,
            check=True,
        )
        return result.stdout

    def write(self, name: str, content: str) -> None:
        (self.root / name).write_text(content)

    def read(self, name: str) -> str:
        return (self.root / name).read_text()

    def stage_then_write(self, name: str, staged: str, worktree: str) -> None:
        """Stage `staged` as the file's content, then leave `worktree` on disk."""
        self.write(name, staged)
        self.git("add", name)
        self.write(name, worktree)

    def stash_commits(self) -> list[str]:
        return self.git("stash", "list", "--format=%H").split()

    def run_hook(self, **env: str) -> subprocess.CompletedProcess:
        return subprocess.run(
            ["bash", str(HOOK)],
            cwd=self.root,
            env={**self.env, **env},
            capture_output=True,
            text=True,
            check=False,
        )

    def formatter_calls(self) -> list[str]:
        return self.log.read_text().splitlines() if self.log.exists() else []


@pytest.fixture
def repo(tmp_path):
    return Repo(tmp_path)


def partially_staged(repo: Repo) -> tuple[str, str]:
    """Stage a hunk that needs formatting; leave a distant hunk unstaged.

    Returns the expected (index, working tree) contents after the hook.
    """
    staged = replace_line(ORIGINAL, 2, "staged   ")
    worktree = replace_line(staged, 9, "unstaged")
    repo.stage_then_write("a.rb", staged, worktree)
    expected_index = replace_line(ORIGINAL, 2, "staged")
    return expected_index, replace_line(expected_index, 9, "unstaged")


def test_partial_staging_keeps_unstaged_hunk_out_of_index(repo):
    expected_index, expected_worktree = partially_staged(repo)

    result = repo.run_hook()

    assert result.returncode == 0, result.stdout + result.stderr
    assert repo.git("show", ":a.rb") == expected_index
    assert repo.read("a.rb") == expected_worktree
    assert repo.stash_commits() == []


def test_untracked_files_survive(repo):
    partially_staged(repo)
    repo.write("notes.txt", "untracked\n")

    result = repo.run_hook()

    assert result.returncode == 0, result.stdout + result.stderr
    assert repo.read("notes.txt") == "untracked\n"
    assert "notes.txt" not in repo.git("ls-files")


def test_pre_existing_stash_is_untouched(repo):
    repo.write("a.rb", replace_line(ORIGINAL, 5, "someone else's work"))
    repo.git("stash", "push", "-q", "-m", "user stash")
    before = repo.stash_commits()
    partially_staged(repo)

    result = repo.run_hook()

    assert result.returncode == 0, result.stdout + result.stderr
    assert repo.stash_commits() == before


def test_stash_push_failure_aborts_before_formatting(repo):
    repo.write("a.rb", replace_line(ORIGINAL, 5, "someone else's work"))
    repo.git("stash", "push", "-q", "-m", "user stash")
    before = repo.stash_commits()
    partially_staged(repo)
    worktree = repo.read("a.rb")

    result = repo.run_hook(FAIL_STASH_PUSH="1")

    assert result.returncode != 0
    assert repo.formatter_calls() == []
    assert repo.stash_commits() == before
    assert repo.read("a.rb") == worktree


def test_formatter_failure_restores_working_tree(repo):
    _, expected_worktree = partially_staged(repo)

    result = repo.run_hook(STUB_FORMATTER_EXIT="1")

    assert result.returncode != 0
    assert repo.formatter_calls() != []
    assert repo.read("a.rb") == expected_worktree
    assert repo.stash_commits() == []


def test_restore_conflict_keeps_stash_and_explains_recovery(repo):
    # The unstaged hunk sits next to the line the formatter rewrites, so
    # the saved unstaged diff no longer applies on top of the formatted file.
    staged = replace_line(ORIGINAL, 5, "staged   ")
    worktree = replace_line(staged, 6, "unstaged")
    repo.stage_then_write("a.rb", staged, worktree)

    result = repo.run_hook()

    assert result.returncode != 0
    stashes = repo.stash_commits()
    assert len(stashes) == 1
    assert stashes[0] in result.stderr
    assert "git restore" in result.stderr
    assert "<<<<<<<" not in repo.read("a.rb")
    assert repo.git("diff", "--name-only", "--diff-filter=U") == ""

    restore = f"git restore --source={stashes[0]} --worktree -- ."
    assert restore in result.stderr
    subprocess.run(restore, shell=True, cwd=repo.root, env=repo.env, check=True)
    assert repo.read("a.rb") == worktree


def test_no_unstaged_changes_creates_no_stash(repo):
    repo.write("a.rb", replace_line(ORIGINAL, 3, "staged   "))
    repo.git("add", "a.rb")

    result = repo.run_hook()

    assert result.returncode == 0, result.stdout + result.stderr
    assert repo.git("show", ":a.rb") == replace_line(ORIGINAL, 3, "staged")
    assert repo.stash_commits() == []
