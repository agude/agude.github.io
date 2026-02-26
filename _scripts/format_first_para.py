#!/usr/bin/env python3
import sys
import textwrap
import glob
from pathlib import Path


def wrap_paragraph(para_lines):
    text = " ".join(para_lines)
    return textwrap.fill(text, width=78, break_long_words=False, break_on_hyphens=False)


def format_first_paragraph(filepath):
    filepath = Path(filepath)
    if not filepath.is_file():
        print(f"Skipping {filepath} (not a regular file)")
        return

    try:
        with open(filepath, "r", encoding="utf-8") as f:
            lines = f.readlines()
    except Exception as e:
        print(f"Error reading {filepath}: {e}", file=sys.stderr)
        return

    out_lines = []
    state = "START"
    para_lines = []

    for line in lines:
        stripped = line.strip()

        if state == "START" and stripped.lstrip("\ufeff") == "---":
            out_lines.append(line)
            state = "IN_FRONTMATTER"

        elif state == "START":
            out_lines.append(line)

        elif state == "IN_FRONTMATTER":
            out_lines.append(line)
            if stripped == "---":
                state = "AFTER_FRONTMATTER"

        elif state == "AFTER_FRONTMATTER":
            if stripped == "":
                out_lines.append(line)
            else:
                state = "IN_FIRST_PARA"
                para_lines.append(stripped)

        elif state == "IN_FIRST_PARA":
            if stripped == "":
                state = "AFTER_FIRST_PARA"

                wrapped_text = wrap_paragraph(para_lines)

                out_lines.append(wrapped_text + "\n")
                out_lines.append(line)  # the blank line itself
            else:
                para_lines.append(stripped)

        elif state == "AFTER_FIRST_PARA":
            out_lines.append(line)

    # Edge case: File ends right in the middle of the first paragraph
    if state == "IN_FIRST_PARA":
        wrapped_text = wrap_paragraph(para_lines)
        out_lines.append(wrapped_text + "\n")

    # Write the modified content back out over the original file
    try:
        with open(filepath, "w", encoding="utf-8") as f:
            f.writelines(out_lines)
    except Exception as e:
        print(f"Error writing to {filepath}: {e}", file=sys.stderr)


def main():
    if len(sys.argv) < 2:
        print("Usage: python format_first_para.py <file1.md> [file2.md] [*.md]")
        sys.exit(1)

    files_to_process = []
    for arg in sys.argv[1:]:
        if "*" in arg or "?" in arg:
            files_to_process.extend(glob.glob(arg, recursive=True))
        else:
            files_to_process.append(arg)

    if not files_to_process:
        print("No files found matching the provided arguments.")
        sys.exit(1)

    for filepath in files_to_process:
        print(f"Processing: {filepath}")
        format_first_paragraph(filepath)

    print("Done!")


if __name__ == "__main__":
    main()
