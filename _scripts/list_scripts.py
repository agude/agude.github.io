#!/usr/bin/env python3
# /// script
# requires-python = ">=3.10"
# ///
"""List available scripts with descriptions and invocation examples."""

import ast
import sys
from pathlib import Path

SCRIPT_ROOT = Path(__file__).resolve().parent
SUBDIRS = ["content", "diagnostics", "metadata", "ranking"]
SKIP_MARKER = "# not-a-script"

# ANSI escape codes.
BOLD = "\033[1m"
DIM = "\033[2m"
CYAN = "\033[36m"
RESET = "\033[0m"


def has_local_imports(source: str) -> bool:
    """Return True if the source contains from-imports of local modules."""
    for node in ast.walk(ast.parse(source)):
        if isinstance(node, ast.ImportFrom) and node.level == 0 and node.module:
            top = node.module.split(".")[0]
            if top in sys.stdlib_module_names:
                continue
            # Known third-party packages used by scripts in this repo.
            if top in {"yaml", "bs4", "lxml", "isbnlib"}:
                continue
            return True
    return False


def main() -> None:
    # Disable colors when stdout is not a terminal (e.g. piped to a file).
    if not sys.stdout.isatty():
        bold = dim = cyan = reset = ""
    else:
        bold, dim, cyan, reset = BOLD, DIM, CYAN, RESET

    print(
        f"{bold}Available scripts{reset} {dim}(run from repo root unless noted){reset}"
    )

    for subdir in SUBDIRS:
        dirpath = SCRIPT_ROOT / subdir
        if not dirpath.is_dir():
            continue

        scripts: list[tuple[str, str, bool]] = []
        for pyfile in sorted(dirpath.glob("*.py")):
            source = pyfile.read_text()
            if SKIP_MARKER in source:
                continue
            try:
                docstring = ast.get_docstring(ast.parse(source))
            except SyntaxError:
                docstring = None
            desc = docstring.split("\n")[0] if docstring else "** missing docstring **"
            local = has_local_imports(source)
            scripts.append((pyfile.name, desc, local))

        if not scripts:
            continue

        any_local = any(local for _, _, local in scripts)
        header = subdir
        if any_local:
            header += f" {dim}(run from _scripts/{subdir}/){reset}"

        print()
        print(f"{bold}{cyan}{header}{reset}")
        for name, desc, local in scripts:
            print(f"  {bold}{name}{reset}  {desc}")
            if local:
                invocation = f"cd _scripts/{subdir} && uv run {name}"
            else:
                invocation = f"uv run _scripts/{subdir}/{name}"
            print(f"  {dim}$ {invocation}{reset}")
            print()


if __name__ == "__main__":
    main()
