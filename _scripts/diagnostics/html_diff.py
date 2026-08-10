#!/usr/bin/env python3
# /// script
# requires-python = ">=3.10"
# dependencies = ["beautifulsoup4", "lxml"]
# ///
"""Semantically diff two Jekyll builds, ignoring volatile elements.

Example: old/ new/
"""

import argparse
import filecmp
import fnmatch
import shutil
import sys
import tempfile
from pathlib import Path

from bs4 import BeautifulSoup
from bs4.element import Comment

# Configuration: how many paths to print per summary list
MAX_LISTED_FILES = 10

# Configuration: Files to skip entirely
IGNORED_FILES = [
    "feed.xml",
    "feed/books.xml",
    "*.css",
    "*.map",
    "sitemap.xml",
    "robots.txt",
]

# Configuration: CSS selectors to strip ENTIRELY (tag + content)
IGNORED_SELECTORS = [
    "meta[name='generator']",
    ".build-date",
    "script[data-ignore='true']",
    "meta[property='og:url']",
    "link[rel='canonical']",
    "updated",
    "lastBuildDate",
    "pubDate",
]


def normalize_html(content, is_xml=False):
    """Parses HTML/XML, strips ignored elements, and normalizes whitespace."""
    parser = "xml" if is_xml else "lxml"
    soup = BeautifulSoup(content, parser)

    # 1. Remove ignored elements entirely
    for selector in IGNORED_SELECTORS:
        for tag in soup.select(selector):
            tag.decompose()

    # 2. Remove specific attributes that cause noise
    for tag in soup.find_all("time"):
        if "datetime" in tag.attrs:
            del tag["datetime"]

    # 3. Remove comments
    for comment in soup.find_all(string=lambda text: isinstance(text, Comment)):
        comment.extract()

    # 4. Prettify
    return soup.prettify().splitlines()


def read_file(path):
    try:
        return path.read_text(encoding="utf-8")
    except UnicodeDecodeError:
        return None


def files_differ(file_a, file_b):
    """Returns True if files differ semantically, False if they are the same."""
    is_html = file_a.suffix in (".html", ".htm")
    is_xml = file_a.suffix == ".xml"

    content_a = read_file(file_a)
    content_b = read_file(file_b)

    if content_a is None or content_b is None:
        return not filecmp.cmp(file_a, file_b, shallow=False)

    if is_html or is_xml:
        norm_a = normalize_html(content_a, is_xml)
        norm_b = normalize_html(content_b, is_xml)
        return norm_a != norm_b

    return content_a != content_b


def write_normalized_file(src_path, dest_path):
    """Writes a cleaned version of the file to the destination for external diffing."""
    is_html = src_path.suffix in (".html", ".htm")
    is_xml = src_path.suffix == ".xml"

    dest_path.parent.mkdir(parents=True, exist_ok=True)

    content = read_file(src_path)
    if content is None:
        shutil.copy2(src_path, dest_path)
        return

    if is_html or is_xml:
        content = "\n".join(normalize_html(content, is_xml)) + "\n"
    dest_path.write_text(content, encoding="utf-8")


def should_ignore(rel_path):
    return any(
        fnmatch.fnmatch(str(rel_path), pattern) or fnmatch.fnmatch(rel_path.name, pattern)
        for pattern in IGNORED_FILES
    )


def compare_directories(dir_a, dir_b):
    print(f"Comparing:\n A: {dir_a}\n B: {dir_b}\n")

    diffs = []
    only_in_a = []
    only_in_b = []

    for path_a in _comparable_files(dir_a):
        rel_file_path = path_a.relative_to(dir_a)
        path_b = dir_b / rel_file_path

        if not path_b.exists():
            only_in_a.append(rel_file_path)
        elif files_differ(path_a, path_b):
            diffs.append(rel_file_path)

    for path_b in _comparable_files(dir_b):
        rel_file_path = path_b.relative_to(dir_b)
        if not (dir_a / rel_file_path).exists():
            only_in_b.append(rel_file_path)

    return diffs, only_in_a, only_in_b


def _comparable_files(root):
    """Yield files under root, skipping nested builds and ignored patterns."""
    for path in root.rglob("*"):
        if not path.is_file():
            continue
        rel_path = path.relative_to(root)
        if rel_path.parts[0].startswith("_site"):
            continue
        if should_ignore(rel_path):
            continue
        yield path


def print_file_list(header, paths, bullet):
    """Print a file list, capped, saying so when there are more.

    The count in the header is the real total; without the trailing note a
    truncated list reads as complete, and a file that did change looks
    untouched. Every listed file is exported regardless.
    """
    print(f"{header} ({len(paths)}):")
    for path in sorted(paths)[:MAX_LISTED_FILES]:
        print(f"  {bullet} {path}")
    if len(paths) > MAX_LISTED_FILES:
        print(f"  ... and {len(paths) - MAX_LISTED_FILES} more (all are exported)")
    print("")


def main():
    parser = argparse.ArgumentParser(
        description="Semantically compare two Jekyll builds and export clean files for diffing."
    )
    parser.add_argument("dir_a", help="Path to the first directory")
    parser.add_argument("dir_b", help="Path to the second directory")
    parser.add_argument(
        "--out-dir",
        type=str,
        help="Directory to export the cleaned files to. Defaults to a random temp dir.",
    )
    args = parser.parse_args()

    dir_a = Path(args.dir_a)
    dir_b = Path(args.dir_b)
    if not dir_a.is_dir() or not dir_b.is_dir():
        print("Error: Both arguments must be valid directories.")
        sys.exit(1)

    diffs, only_a, only_b = compare_directories(dir_a, dir_b)

    if not diffs and not only_a and not only_b:
        print("✅ No semantic differences found.")
        sys.exit(0)

    # Create Export Directory
    export_base = (
        Path(args.out_dir) if args.out_dir else Path(tempfile.mkdtemp(prefix="jekyll-diff-"))
    )
    dir_a_export = export_base / "A"
    dir_b_export = export_base / "B"

    print(f"📦 Found differences! Exporting normalized files to: {export_base}\n")

    # Export ONLY the files that changed or are unique
    for f in diffs + only_a:
        write_normalized_file(dir_a / f, dir_a_export / f)
    for f in diffs + only_b:
        write_normalized_file(dir_b / f, dir_b_export / f)

    # Print Summary
    if only_a:
        print_file_list(f"Files only in {dir_a}", only_a, "-")
    if only_b:
        print_file_list(f"Files only in {dir_b}", only_b, "-")
    if diffs:
        print_file_list("Files with differences", diffs, "*")

    # Print suggested commands
    print("💡 COMMANDS TO VIEW DIFFS:\n")
    print("  Using Git:")
    print(f"    git diff --no-index --word-diff {dir_a_export} {dir_b_export}\n")

    sys.exit(1)


if __name__ == "__main__":
    main()
