#!/usr/bin/env python3
# /// script
# requires-python = ">=3.10"
# ///
"""List available scripts with descriptions and invocation examples."""

import ast
import re
import sys
from pathlib import Path

SCRIPT_ROOT = Path(__file__).resolve().parent
SKIP_MARKER = "# not-a-script"

# ANSI escape codes.
BOLD = "\033[1m"
DIM = "\033[2m"
CYAN = "\033[36m"
RESET = "\033[0m"


def has_local_imports(source: str, directory: Path) -> bool:
    """Return True if the source imports a module that exists as a sibling .py file."""
    sibling_names = {p.stem for p in directory.glob("*.py")}
    for node in ast.walk(ast.parse(source)):
        if isinstance(node, ast.ImportFrom) and node.level == 0 and node.module:
            top = node.module.split(".")[0]
            if top in sibling_names:
                return True
    return False


def parse_docstring(source: str) -> tuple[str, str]:
    """Return (first_line, example_args) from a module docstring.

    Looks for a line matching ``Example: <args>`` in the docstring body.
    """
    try:
        docstring = ast.get_docstring(ast.parse(source))
    except SyntaxError:
        docstring = None

    if not docstring:
        return ("** missing docstring **", "")

    lines = docstring.split("\n")
    first_line = lines[0]

    example_args = ""
    for line in lines[1:]:
        match = re.match(r"\s*Example:\s*(.*)", line)
        if match:
            example_args = match.group(1).strip()
            break

    return (first_line, example_args)


def main() -> None:
    # Disable colors when stdout is not a terminal (e.g. piped to a file).
    if not sys.stdout.isatty():
        bold = dim = cyan = reset = ""
    else:
        bold, dim, cyan, reset = BOLD, DIM, CYAN, RESET

    print(
        f"{bold}Available scripts{reset} {dim}(run from repo root unless noted){reset}"
    )

    subdirs = sorted(
        p.name
        for p in SCRIPT_ROOT.iterdir()
        if p.is_dir() and not p.name.startswith((".", "__")) and p.name != "tests"
    )

    first_group = True
    for subdir in subdirs:
        dirpath = SCRIPT_ROOT / subdir
        scripts: list[tuple[str, str, str, bool]] = []
        for pyfile in sorted(dirpath.glob("*.py")):
            source = pyfile.read_text()
            if SKIP_MARKER in source.splitlines()[:10]:
                continue
            desc, example_args = parse_docstring(source)
            local = has_local_imports(source, dirpath)
            scripts.append((pyfile.name, desc, example_args, local))

        if not scripts:
            continue

        any_local = any(local for _, _, _, local in scripts)
        header = subdir
        if any_local:
            header += f" {dim}(run from _scripts/{subdir}/){reset}"

        if not first_group:
            print()
        first_group = False
        print()
        print(f"{bold}{cyan}{header}{reset}")
        for i, (name, desc, example_args, local) in enumerate(scripts):
            if i > 0:
                print()
            print(f"  {bold}{name}{reset}  {desc}")
            if local:
                invocation = f"cd _scripts/{subdir} && uv run {name}"
            else:
                invocation = f"uv run _scripts/{subdir}/{name}"
            if example_args:
                invocation += f" {example_args}"
            print(f"  {dim}$ {invocation}{reset}")

    print()


if __name__ == "__main__":
    main()
