# /// script
# requires-python = ">=3.10"
# dependencies = []
# ///
"""Generate one intentionally unlinked Liquid capture."""

from __future__ import annotations

import argparse
import sys

from capture_generation import build_standalone_reference, render_captures


def create_argument_parser() -> argparse.ArgumentParser:
    """Create the exceptional standalone-reference parser."""
    parser = argparse.ArgumentParser(
        description="Generate one intentionally unlinked author, book, or series capture.",
        epilog="Use generate_reference_group.py for the normal author/work workflow.",
    )
    reference = parser.add_mutually_exclusive_group(required=True)
    reference.add_argument(
        "--author",
        metavar="NAME[=VARIABLE]",
        help="generate one unlinked four-variant author bundle",
    )
    reference.add_argument(
        "--book",
        metavar="TITLE[=VARIABLE]",
        help="generate one unlinked book_link capture",
    )
    reference.add_argument(
        "--series",
        metavar="TITLE[=VARIABLE]",
        help="generate one unlinked series_link capture",
    )
    parser.add_argument(
        "--porcelain",
        action="store_true",
        help="emit plain paste-ready Liquid; warnings remain on stderr",
    )
    return parser


def selected_reference(arguments: argparse.Namespace) -> tuple[str, str]:
    """Return the one standalone reference selected by the parser."""
    for reference_kind in ("author", "book", "series"):
        raw_value = getattr(arguments, reference_kind)
        if raw_value is not None:
            return reference_kind, raw_value
    raise ValueError("select exactly one standalone reference")


def warning_messages(reference_kind: str) -> list[str]:
    """Explain why standalone output needs deliberate review."""
    if reference_kind == "author":
        correction = "use generate_reference_group.py unless the prose intentionally names only this author."
    else:
        correction = (
            "use generate_reference_group.py unless the related author is already captured "
            "or the prose intentionally uses title-only shorthand."
        )
    return [
        "standalone reference mode is exceptional. You are probably doing this wrong.",
        "this script cannot preserve an author/work relationship.",
        correction,
        "verify this exception against the planned sentence before using the Liquid output.",
    ]


def emit_warnings(messages: list[str]) -> None:
    """Write warnings to stderr without contaminating Liquid output."""
    for message in messages:
        print(f"WARNING: {message}", file=sys.stderr)


def main(raw_arguments: list[str] | None = None) -> None:
    """Validate, warn, and print one standalone reference."""
    parser = create_argument_parser()
    arguments = parser.parse_args(raw_arguments)
    reference_kind, raw_value = selected_reference(arguments)
    try:
        captures = build_standalone_reference(reference_kind, raw_value)
    except ValueError as error:
        parser.error(str(error))
    emit_warnings(warning_messages(reference_kind))
    print(render_captures(captures))


if __name__ == "__main__":
    main()
