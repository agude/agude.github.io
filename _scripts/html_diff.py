#!/usr/bin/env python3
import os
import sys
import argparse
import fnmatch
import filecmp
import tempfile
import shutil
from bs4 import BeautifulSoup
from bs4.element import Comment

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
        with open(path, "r", encoding="utf-8") as f:
            return f.read()
    except UnicodeDecodeError:
        return None


def files_differ(file_a, file_b):
    """Returns True if files differ semantically, False if they are the same."""
    is_html = file_a.endswith((".html", ".htm"))
    is_xml = file_a.endswith(".xml")

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
    is_html = src_path.endswith((".html", ".htm"))
    is_xml = src_path.endswith(".xml")

    os.makedirs(os.path.dirname(dest_path), exist_ok=True)

    content = read_file(src_path)
    if content is None:
        shutil.copy2(src_path, dest_path)
        return

    if is_html or is_xml:
        norm_lines = normalize_html(content, is_xml)
        with open(dest_path, "w", encoding="utf-8") as f:
            f.write("\n".join(norm_lines) + "\n")
    else:
        with open(dest_path, "w", encoding="utf-8") as f:
            f.write(content)


def should_ignore(rel_path):
    for pattern in IGNORED_FILES:
        if fnmatch.fnmatch(rel_path, pattern) or fnmatch.fnmatch(
            os.path.basename(rel_path), pattern
        ):
            return True
    return False


def compare_directories(dir_a, dir_b):
    print(f"Comparing:\n A: {dir_a}\n B: {dir_b}\n")

    diffs = []
    only_in_a = []
    only_in_b = []

    # Walk dir_a
    for root, _, files in os.walk(dir_a):
        rel_path = os.path.relpath(root, dir_a)
        if rel_path.startswith("_site"):
            continue

        for file in files:
            rel_file_path = os.path.join(rel_path, file)
            if should_ignore(rel_file_path):
                continue

            path_a = os.path.join(root, file)
            path_b = os.path.normpath(os.path.join(dir_b, rel_path, file))

            if not os.path.exists(path_b):
                only_in_a.append(rel_file_path)
                continue

            if files_differ(path_a, path_b):
                diffs.append(rel_file_path)

    # Walk dir_b for missing files
    for root, _, files in os.walk(dir_b):
        rel_path = os.path.relpath(root, dir_b)
        if rel_path.startswith("_site"):
            continue

        for file in files:
            rel_file_path = os.path.join(rel_path, file)
            if should_ignore(rel_file_path):
                continue

            path_a = os.path.normpath(os.path.join(dir_a, rel_path, file))
            if not os.path.exists(path_a):
                only_in_b.append(rel_file_path)

    return diffs, only_in_a, only_in_b


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

    if not os.path.isdir(args.dir_a) or not os.path.isdir(args.dir_b):
        print("Error: Both arguments must be valid directories.")
        sys.exit(1)

    diffs, only_a, only_b = compare_directories(args.dir_a, args.dir_b)

    if not diffs and not only_a and not only_b:
        print("✅ No semantic differences found.")
        sys.exit(0)

    # Create Export Directory
    export_base = (
        args.out_dir if args.out_dir else tempfile.mkdtemp(prefix="jekyll-diff-")
    )
    dir_a_export = os.path.join(export_base, "A")
    dir_b_export = os.path.join(export_base, "B")

    print(f"📦 Found differences! Exporting normalized files to: {export_base}\n")

    # Export ONLY the files that changed or are unique
    for f in diffs + only_a:
        write_normalized_file(
            os.path.join(args.dir_a, f), os.path.join(dir_a_export, f)
        )
    for f in diffs + only_b:
        write_normalized_file(
            os.path.join(args.dir_b, f), os.path.join(dir_b_export, f)
        )

    # Print Summary
    if only_a:
        print(f"Files only in {args.dir_a} ({len(only_a)}):")
        for f in sorted(only_a)[:10]:
            print(f"  - {f}")
        print("")

    if only_b:
        print(f"Files only in {args.dir_b} ({len(only_b)}):")
        for f in sorted(only_b)[:10]:
            print(f"  - {f}")
        print("")

    if diffs:
        print(f"Files with differences ({len(diffs)}):")
        for f in sorted(diffs)[:10]:
            print(f"  * {f}")
        print("")

    # Print suggested commands
    print("💡 COMMANDS TO VIEW DIFFS:\n")
    print("  Using Git:")
    print(f"    git diff --no-index {dir_a_export} {dir_b_export}\n")

    if diffs:
        print("  Using Neovim:")
        print(f"    nvim -d {dir_a_export}/{diffs[0]} {dir_b_export}/{diffs[0]}")
        if len(diffs) > 1:
            print(
                f"    git difftool --dir-diff --tool=nvimdiff --no-index {dir_a_export} {dir_b_export}"
            )

    sys.exit(1)


if __name__ == "__main__":
    main()
