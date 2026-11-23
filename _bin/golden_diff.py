"""Compare names, file types, symlink targets and bytes in two output trees."""

import filecmp
import os
import sys
from pathlib import Path


def entries(directory: Path, root: Path) -> dict[Path, str]:
    result = {}
    for path in directory.iterdir():
        relative = path.relative_to(root)
        if path.is_symlink():
            result[relative] = "link"
        elif path.is_dir():
            result[relative] = "directory"
            result.update(entries(path, root))
        elif path.is_file():
            result[relative] = "file"
        else:
            raise ValueError(f"Unsupported output entry: {path}")
    return result


def matches(before: Path, after: Path, kind: str) -> bool:
    if kind == "directory":
        return True
    if kind == "link":
        # Path.readlink() discards spelling differences such as a leading "./".
        return os.readlink(before) == os.readlink(after)
    return filecmp.cmp(before, after, shallow=False)


def compare(before: Path, after: Path) -> bool:
    base = entries(before, before)
    candidate = entries(after, after)
    missing = base.keys() - candidate.keys()
    extra = candidate.keys() - base.keys()
    changed = {
        path
        for path in base.keys() & candidate.keys()
        if base[path] != candidate[path]
        or not matches(before / path, after / path, base[path])
    }

    for kind, paths in (("missing", missing), ("extra", extra), ("changed", changed)):
        for path in sorted(paths):
            print(f"{kind} {path}")
    return not (missing or extra or changed)


if __name__ == "__main__":
    sys.exit(0 if compare(Path(sys.argv[1]), Path(sys.argv[2])) else 1)
