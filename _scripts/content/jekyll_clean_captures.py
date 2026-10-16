#!/usr/bin/env python3
# /// script
# requires-python = ">=3.10"
# ///
"""Find and remove unused Liquid capture blocks from Markdown files.

Reports unused captures without changing files. Pass --write to remove them.
A file with nested capture blocks is refused and never rewritten; the tool
exits non-zero after processing the remaining files.

Example: _posts/some_post.md
"""

import argparse
import re
import sys
from glob import glob
from pathlib import Path

# A whole capture block, with or without whitespace control. Group 1 is the
# variable name and group 2 the body. The body match is non-greedy, so for
# nested blocks it ends at the inner `endcapture`; see capture_blocks.
CAPTURE_RE = re.compile(
    r"{%-?\s*capture\s+([A-Za-z0-9_]+)\s*-?%}(.*?){%-?\s*endcapture\s*-?%}", re.DOTALL
)

# Any Liquid output or tag region: {{ ... }}, {%- ... -%}, and so on.
LIQUID_REGION_RE = re.compile(r"{{.*?}}|{%.*?%}", re.DOTALL)

# A region's delimiters, with their whitespace-control hyphens.
DELIMITER_RE = re.compile(r"\A(?:{{|{%)-?|-?(?:}}|%})\Z")

# A capture's opening tag. In a region it defines its variable, which is not
# a use; in a capture body it marks a nested block.
CAPTURE_OPEN_RE = re.compile(r"{%-?\s*capture\b")

IDENTIFIER_RE = re.compile(r"[A-Za-z_][A-Za-z0-9_-]*")


class NestedCaptureError(ValueError):
    """A capture block contains another capture block."""


def used_identifiers(content):
    """Return every identifier that appears in a Liquid region of `content`.

    Capture opening tags are skipped, so defining a variable never counts
    as using it. Prose outside Liquid regions is ignored. Delimiters are
    stripped first, so the hyphen in `{{x-}}` is whitespace control and not
    part of the name, while `x-y` stays one identifier.
    """
    identifiers = set()
    for region in LIQUID_REGION_RE.finditer(content):
        text = region.group(0)
        if CAPTURE_OPEN_RE.match(text):
            continue
        identifiers.update(IDENTIFIER_RE.findall(DELIMITER_RE.sub("", text)))
    return identifiers


def capture_blocks(content):
    """Return the match for every capture block in `content`.

    Raises:
        NestedCaptureError: a block's body opens another capture. The
            non-greedy match pairs the outer opening tag with the inner
            closing tag, so the spans it reports would be wrong.
    """
    blocks = list(CAPTURE_RE.finditer(content))
    for block in blocks:
        if CAPTURE_OPEN_RE.search(block.group(2)):
            line = content.count("\n", 0, block.start()) + 1
            raise NestedCaptureError(
                f"capture '{block.group(1)}' on line {line} contains a nested capture block"
            )
    return blocks


def find_unused_captures(content):
    """
    Finds all capture blocks whose variable is never read.

    A variable is read if its name appears as an identifier in any Liquid
    output or tag region, including inside other capture bodies.

    Returns:
        A list of (variable_name, full_match_object) tuples for unused captures.

    Raises:
        NestedCaptureError: the content has nested capture blocks.
    """
    used = used_identifiers(content)
    return [
        (match.group(1), match) for match in capture_blocks(content) if match.group(1) not in used
    ]


def remove_blocks(content, matches):
    """Return `content` without the matched blocks and each block's newline."""
    pieces = []
    position = 0
    for match in sorted(matches, key=lambda m: m.start()):
        pieces.append(content[position : match.start()])
        position = match.end()
        if content.startswith("\n", position):
            position += 1
    pieces.append(content[position:])
    return "".join(pieces)


def process_file(file_path, dry_run=True):
    """
    Processes a single file to find and optionally remove unused captures.

    Returns:
        False if the file could not be processed, True otherwise.
    """
    try:
        path = Path(file_path)
        content = path.read_text()

        unused_captures = find_unused_captures(content)

        if not unused_captures:
            print(f"No unused captures found in {path.name}")
            return True

        print(f"Found {len(unused_captures)} unused captures in {path.name}:")

        for var, match in unused_captures:
            # Get the line numbers for the entire match
            start_line = content.count("\n", 0, match.start()) + 1
            end_line = content.count("\n", 0, match.end()) + 1
            line_info = (
                f"line {start_line}" if start_line == end_line else f"lines {start_line}-{end_line}"
            )
            print(f"  - Unused variable '{var}' (on {line_info})")

        if dry_run:
            print("  (Dry run: no changes made; pass --write to remove them)")
        else:
            path.write_text(remove_blocks(content, [match for _, match in unused_captures]))
            print(f"  Cleaned up {path.name}")
        return True

    except NestedCaptureError as e:
        print(
            f"Error: {file_path}: {e}; nested captures are not supported, file left unchanged",
            file=sys.stderr,
        )
    except FileNotFoundError:
        print(f"Error: File not found at {file_path}", file=sys.stderr)
    except Exception as e:
        print(f"An unexpected error occurred with {file_path}: {e}", file=sys.stderr)
    return False


def main(argv=None):
    parser = argparse.ArgumentParser(
        description="Find and remove unused Jekyll {% capture %} variables from markdown files.",
        formatter_class=argparse.RawTextHelpFormatter,
    )
    parser.add_argument(
        "files",
        metavar="FILE",
        nargs="+",
        help="One or more file paths to process. Supports shell globbing (e.g., 'posts/*.md').",
    )
    parser.add_argument(
        "--write",
        action="store_true",
        help="Remove the unused captures. Without it, only report them.",
    )

    args = parser.parse_args(argv)

    # Expand glob patterns from the shell
    file_paths = []
    for pattern in args.files:
        file_paths.extend(glob(pattern))

    if not file_paths:
        print("Error: No files matched the provided pattern.", file=sys.stderr)
        sys.exit(1)

    print("--- Starting Jekyll Capture Cleanup ---")
    if not args.write:
        print("--- Dry run: pass --write to remove captures ---")

    failed = False
    for file_path in file_paths:
        if not process_file(file_path, dry_run=not args.write):
            failed = True
        print("-" * 20)

    if failed:
        sys.exit(1)


if __name__ == "__main__":
    main()
