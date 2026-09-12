# /// script
# requires-python = ">=3.10"
# dependencies = []
# ///
"""Generate Liquid captures for movie, game, and television titles."""

from __future__ import annotations

import argparse

from capture_generation import build_media_references, render_captures


def create_argument_parser() -> argparse.ArgumentParser:
    """Create the media-reference command-line parser."""
    parser = argparse.ArgumentParser(
        description="Generate Liquid captures for movie, game, and television titles.",
        epilog="Each repeatable value accepts TITLE or TITLE=variable_name.",
    )
    parser.add_argument(
        "--movie",
        action="append",
        default=[],
        metavar="TITLE[=VARIABLE]",
        help="add a movie_title capture",
    )
    parser.add_argument(
        "--game",
        action="append",
        default=[],
        metavar="TITLE[=VARIABLE]",
        help="add a game_title capture",
    )
    parser.add_argument(
        "--tv-show",
        action="append",
        default=[],
        metavar="TITLE[=VARIABLE]",
        help="add a tv_show_title capture",
    )
    parser.add_argument(
        "--porcelain",
        action="store_true",
        help="emit plain paste-ready Liquid; this is already the default",
    )
    return parser


def main(raw_arguments: list[str] | None = None) -> None:
    """Validate and print media-title captures."""
    parser = create_argument_parser()
    arguments = parser.parse_args(raw_arguments)
    if not arguments.movie and not arguments.game and not arguments.tv_show:
        parser.error("provide at least one --movie, --game, or --tv-show")
    try:
        captures = build_media_references(
            arguments.movie,
            arguments.game,
            arguments.tv_show,
        )
    except ValueError as error:
        parser.error(str(error))
    print(render_captures(captures))


if __name__ == "__main__":
    main()
