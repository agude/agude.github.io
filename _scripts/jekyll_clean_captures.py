#!/usr/bin/env python3
import argparse
import re
import sys
from pathlib import Path
from glob import glob


def find_unused_captures(content):
    """
    Finds all capture blocks and checks if they are used in the content.

    Returns:
        A list of (variable_name, full_match_object) tuples for unused captures.
    """
    # Regex to find all capture blocks, including multi-line ones.
    # It captures the variable name (group 1) and the full block (group 0).
    capture_regex = re.compile(
        r"({%\s*capture\s+([a-zA-Z0-9_]+)\s+%}.*?{%\s*endcapture\s*%})", re.DOTALL
    )

    captures = list(capture_regex.finditer(content))
    unused = []

    for i, match in enumerate(captures):
        variable_name = match.group(2)

        # To check for usage, we search the entire document *except* for the
        # current capture block's definition.
        search_content = content[: match.start()] + content[match.end() :]

        # Regex to find usage of the variable, e.g., {{ my_variable }}
        usage_regex = re.compile(r"{{\s*" + re.escape(variable_name) + r"\s*}}")

        if not usage_regex.search(search_content):
            unused.append((variable_name, match))

    return unused


def process_file(file_path, dry_run=True):
    """
    Processes a single file to find and optionally remove unused captures.
    """
    try:
        path = Path(file_path)
        content = path.read_text()

        unused_captures = find_unused_captures(content)

        if not unused_captures:
            print(f"No unused captures found in {path.name}")
            return

        print(f"Found {len(unused_captures)} unused captures in {path.name}:")

        lines_to_remove = []
        for var, match in unused_captures:
            # Get the line numbers for the entire match
            start_line = content.count("\n", 0, match.start()) + 1
            end_line = content.count("\n", 0, match.end()) + 1
            line_info = (
                f"line {start_line}"
                if start_line == end_line
                else f"lines {start_line}-{end_line}"
            )
            print(f"  - Unused variable '{var}' (on {line_info})")
            lines_to_remove.append(match.group(1))

        if dry_run:
            print("  (Dry run mode: No changes made)")
        else:
            # Remove the unused blocks from the content
            new_content = content
            for block in lines_to_remove:
                # Also remove the newline character that follows the block
                # to prevent empty lines from being left behind.
                new_content = new_content.replace(block + "\n", "")

            path.write_text(new_content)
            print(f"  Cleaned up {path.name}")

    except FileNotFoundError:
        print(f"Error: File not found at {file_path}", file=sys.stderr)
    except Exception as e:
        print(f"An unexpected error occurred with {file_path}: {e}", file=sys.stderr)


def main():
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
        "--dry-run",
        action="store_true",
        help="Show which variables would be removed without modifying files.",
    )

    args = parser.parse_args()

    # Expand glob patterns from the shell
    file_paths = []
    for pattern in args.files:
        file_paths.extend(glob(pattern))

    if not file_paths:
        print("Error: No files matched the provided pattern.", file=sys.stderr)
        sys.exit(1)

    print("--- Starting Jekyll Capture Cleanup ---")
    if args.dry_run:
        print("--- Running in Dry Run Mode ---")

    for file_path in file_paths:
        process_file(file_path, dry_run=args.dry_run)
        print("-" * 20)


if __name__ == "__main__":
    main()
