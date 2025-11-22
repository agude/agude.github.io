#!/usr/bin/env python3
import os
import sys
import argparse
import fnmatch
from bs4 import BeautifulSoup
from bs4.element import Comment
import filecmp
import difflib

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
    """
    Parses HTML/XML, strips ignored elements, sorts attributes,
    and normalizes whitespace. Returns a list of lines for difflib.
    """
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
    pretty_content = soup.prettify()

    return pretty_content.splitlines()


def read_file(path):
    try:
        with open(path, "r", encoding="utf-8") as f:
            return f.read()
    except UnicodeDecodeError:
        return None


def generate_diff(list_a, list_b, file_a, file_b):
    diff = difflib.unified_diff(
        list_a, list_b, fromfile=file_a, tofile=file_b, lineterm=""
    )
    return "\n".join(list(diff)[:20])


def compare_files(file_a, file_b):
    is_html = file_a.endswith((".html", ".htm"))
    is_xml = file_a.endswith(".xml")

    content_a = read_file(file_a)
    content_b = read_file(file_b)

    if content_a is None or content_b is None:
        if not filecmp.cmp(file_a, file_b, shallow=False):
            return "Binary files differ"
        return None

    if is_html or is_xml:
        norm_a = normalize_html(content_a, is_xml)
        norm_b = normalize_html(content_b, is_xml)
        if norm_a == norm_b:
            return None
        return generate_diff(norm_a, norm_b, file_a, file_b)

    if content_a != content_b:
        return generate_diff(
            content_a.splitlines(), content_b.splitlines(), file_a, file_b
        )

    return None


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

    sample_diff = None
    sample_is_html = False

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
            path_b = os.path.join(dir_b, rel_path, file)

            if not os.path.exists(path_b):
                only_in_a.append(rel_file_path)
                continue

            # Compare
            diff_result = compare_files(path_a, path_b)
            if diff_result:
                diffs.append(rel_file_path)

                # Prioritize showing HTML diffs over others
                is_html = file.endswith((".html", ".htm"))
                if sample_diff is None or (is_html and not sample_is_html):
                    sample_diff = diff_result
                    sample_is_html = is_html

    # Walk dir_b to find files missing in A
    for root, _, files in os.walk(dir_b):
        rel_path = os.path.relpath(root, dir_b)
        if rel_path.startswith("_site"):
            continue

        for file in files:
            rel_file_path = os.path.join(rel_path, file)
            if should_ignore(rel_file_path):
                continue

            path_a = os.path.join(dir_a, rel_path, file)
            if not os.path.exists(path_a):
                only_in_b.append(rel_file_path)

    return diffs, only_in_a, only_in_b, sample_diff


def main():
    parser = argparse.ArgumentParser(
        description="Semantically compare two Jekyll build directories."
    )
    parser.add_argument("dir_a", help="Path to the first directory")
    parser.add_argument("dir_b", help="Path to the second directory")

    args = parser.parse_args()

    if not os.path.isdir(args.dir_a) or not os.path.isdir(args.dir_b):
        print("Error: Both arguments must be valid directories.")
        sys.exit(1)

    diffs, only_a, only_b, sample = compare_directories(args.dir_a, args.dir_b)

    if not diffs and not only_a and not only_b:
        print("✅ No semantic differences found.")
        sys.exit(0)

    if only_a:
        print(f"Files only in {args.dir_a} ({len(only_a)}):")
        for f in sorted(only_a)[:10]:
            print(f"  - {f}")
        if len(only_a) > 10:
            print("  ... and more")
        print("")

    if only_b:
        print(f"Files only in {args.dir_b} ({len(only_b)}):")
        for f in sorted(only_b)[:10]:
            print(f"  - {f}")
        if len(only_b) > 10:
            print("  ... and more")
        print("")

    if diffs:
        print(f"Files with differences ({len(diffs)}):")
        for f in sorted(diffs)[:10]:
            print(f"  * {f}")
        if len(diffs) > 10:
            print("  ... and more")

        if sample:
            print("\n--- SAMPLE DIFF (Priority: HTML) ---")
            print(sample)
            print("------------------------------------")
        sys.exit(1)


if __name__ == "__main__":
    main()
