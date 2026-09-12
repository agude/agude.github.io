# /// script
# requires-python = ">=3.10"
# dependencies = []
# ///
"""Generate one complete author/work Liquid capture group."""

from __future__ import annotations

import argparse

from capture_generation import build_reference_group, render_captures


def create_argument_parser() -> argparse.ArgumentParser:
    """Create the strict reference-group command-line parser."""
    parser = argparse.ArgumentParser(
        description="Generate one complete author/work Liquid capture group.",
        epilog=(
            "Run this script separately for each unrelated author group. "
            "Each value accepts NAME or NAME=variable_name."
        ),
    )
    parser.add_argument(
        "--author",
        action="append",
        default=[],
        metavar="NAME[=VARIABLE]",
        help="add a four-variant author bundle; repeat for coauthors",
    )
    parser.add_argument(
        "--author-pair",
        action="append",
        default=[],
        metavar="NAME|NAME[=VARIABLE]",
        help="add full-name and possessive captures for two coauthors",
    )
    parser.add_argument(
        "--book",
        action="append",
        default=[],
        metavar="TITLE[=VARIABLE]",
        help="add an associated book_link capture; repeat for multiple books",
    )
    parser.add_argument(
        "--series",
        action="append",
        default=[],
        metavar="TITLE[=VARIABLE]",
        help="add an associated series_link capture",
    )
    parser.add_argument(
        "--porcelain",
        action="store_true",
        help="emit plain paste-ready Liquid; this is already the default",
    )
    return parser


def main(raw_arguments: list[str] | None = None) -> None:
    """Validate and print one complete reference group."""
    parser = create_argument_parser()
    arguments = parser.parse_args(raw_arguments)
    try:
        captures = build_reference_group(
            arguments.author,
            arguments.author_pair,
            arguments.book,
            arguments.series,
        )
    except ValueError as error:
        parser.error(str(error))
    print(render_captures(captures))


if __name__ == "__main__":
    main()
