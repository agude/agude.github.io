# /// script
# requires-python = ">=3.10"
# dependencies = []
# ///
"""Generate paste-ready Liquid captures for confirmed review references.

The script deliberately formats supplied entities instead of extracting them
from prose. Review notes can contain ambiguous or voice-transcribed names; a
person or agent must resolve those names before passing them to the generator.
"""

from __future__ import annotations

import argparse
import re
import sys
import unicodedata
from dataclasses import dataclass

VARIABLE_NAME_RE = re.compile(r"^[a-z][a-z0-9_]*$")
TRANSLITERATIONS = str.maketrans(
    {
        "Æ": "AE",
        "æ": "ae",
        "Ð": "D",
        "ð": "d",
        "Ł": "L",
        "ł": "l",
        "Ø": "O",
        "ø": "o",
        "Œ": "OE",
        "œ": "oe",
        "Þ": "TH",
        "þ": "th",
        "ẞ": "SS",
        "ß": "ss",
    }
)


@dataclass(frozen=True)
class EntitySpec:
    """A referenced entity and the Liquid variable name assigned to it."""

    value: str
    variable_name: str


@dataclass(frozen=True)
class Capture:
    """One Liquid capture and the entity that produced it."""

    name: str
    content: str
    source: str

    def render(self) -> str:
        return f"{{% capture {self.name} %}}{self.content}{{% endcapture %}}"


class CaptureRegistry:
    """Collect captures while rejecting incompatible variable-name collisions."""

    def __init__(self) -> None:
        self._captures_by_name: dict[str, Capture] = {}

    def add(self, capture: Capture) -> bool:
        """Store a capture, returning false when it duplicates an earlier one."""
        existing = self._captures_by_name.get(capture.name)
        if existing is None:
            self._captures_by_name[capture.name] = capture
            return True
        if existing.content == capture.content:
            return False
        raise ValueError(
            f"capture name '{capture.name}' conflicts between {existing.source} "
            f"and {capture.source}; give one entity an explicit =variable_name suffix"
        )


def default_variable_name(value: str) -> str:
    """Convert a title or surname to an ASCII snake_case Liquid variable name."""
    transliterated = value.translate(TRANSLITERATIONS)
    decomposed = unicodedata.normalize("NFKD", transliterated)
    ascii_value = decomposed.encode("ascii", "ignore").decode("ascii")
    variable_name = re.sub(r"[^a-z0-9]+", "_", ascii_value.lower()).strip("_")
    validate_variable_name(variable_name, value)
    return variable_name


def validate_variable_name(variable_name: str, value: str) -> None:
    """Reject names that Liquid cannot use as a conventional variable name."""
    if VARIABLE_NAME_RE.fullmatch(variable_name):
        return
    raise ValueError(
        f"cannot derive a valid variable name from {value!r}; "
        "use NAME=variable_name with a lowercase letter first"
    )


def parse_entity_spec(raw_value: str, option_name: str) -> EntitySpec:
    """Parse TITLE or TITLE=variable_name command-line input."""
    value, separator, variable_name = raw_value.rpartition("=")
    if not separator:
        value = raw_value
        variable_name = default_variable_name(value)

    value = value.strip()
    variable_name = variable_name.strip()
    if not value:
        raise ValueError(f"{option_name} needs a non-empty title or name")
    validate_variable_name(variable_name, raw_value)
    return EntitySpec(value=value, variable_name=variable_name)


def parse_author_spec(raw_value: str) -> EntitySpec:
    """Parse NAME or NAME=variable_name, defaulting to the author's surname."""
    value, separator, variable_name = raw_value.rpartition("=")
    if not separator:
        value = raw_value.strip()
        if not value:
            raise ValueError("--author needs a non-empty name")
        variable_name = default_variable_name(value.split()[-1])

    value = value.strip()
    variable_name = variable_name.strip()
    if not value:
        raise ValueError("--author needs a non-empty name")
    validate_variable_name(variable_name, raw_value)
    return EntitySpec(value=value, variable_name=variable_name)


def parse_author_pair(raw_value: str) -> tuple[EntitySpec, EntitySpec, str]:
    """Parse AUTHOR|AUTHOR or AUTHOR|AUTHOR=variable_name input."""
    pair, separator, variable_name = raw_value.rpartition("=")
    if not separator:
        pair = raw_value

    author_names = [name.strip() for name in pair.split("|")]
    if len(author_names) != 2 or not all(author_names):
        raise ValueError("--author-pair needs exactly two names: 'First Author|Second Author'")

    first_author = EntitySpec(author_names[0], default_variable_name(author_names[0].split()[-1]))
    second_author = EntitySpec(author_names[1], default_variable_name(author_names[1].split()[-1]))
    if separator:
        pair_variable_name = variable_name.strip()
        validate_variable_name(pair_variable_name, raw_value)
    else:
        pair_variable_name = f"{first_author.variable_name}_and_{second_author.variable_name}"
    return first_author, second_author, pair_variable_name


def liquid_string(value: str) -> str:
    """Return a safely quoted Liquid tag argument."""
    if "\n" in value or "\r" in value:
        raise ValueError("titles and names must be single-line values")
    escaped = value.replace("\\", "\\\\").replace('"', '\\"')
    return f'"{escaped}"'


def author_captures(author: EntitySpec) -> list[Capture]:
    """Return the standard full-name and surname capture variants for an author."""
    surname = author.value.split()[-1]
    author_name = liquid_string(author.value)
    surname_name = liquid_string(surname)
    key = author.variable_name
    source = f"author {author.value!r}"
    return [
        Capture(key, f"{{% author_link {author_name} %}}", source),
        Capture(f"{key}s", f"{{% author_link {author_name} possessive %}}", source),
        Capture(
            f"{key}_lastname",
            f"{{% author_link {author_name} link_text={surname_name} %}}",
            source,
        ),
        Capture(
            f"{key}s_lastname",
            f"{{% author_link {author_name} link_text={surname_name} possessive %}}",
            source,
        ),
    ]


def author_pair_captures(
    first_author: EntitySpec,
    second_author: EntitySpec,
    variable_name: str,
) -> list[Capture]:
    """Return the standard full-name and possessive captures for an author pair."""
    first_name = liquid_string(first_author.value)
    second_name = liquid_string(second_author.value)
    source = f"author pair {first_author.value!r}, {second_author.value!r}"
    return [
        Capture(
            variable_name,
            f"{{% author_link {first_name} %}} and {{% author_link {second_name} %}}",
            source,
        ),
        Capture(
            f"{variable_name}s",
            f"{{% author_link {first_name} %}} and {{% author_link {second_name} possessive %}}",
            source,
        ),
    ]


def link_capture(entity: EntitySpec, tag_name: str, entity_kind: str) -> Capture:
    """Return one capture for a title tag or link tag."""
    return Capture(
        entity.variable_name,
        f"{{% {tag_name} {liquid_string(entity.value)} %}}",
        f"{entity_kind} {entity.value!r}",
    )


def add_captures(registry: CaptureRegistry, captures: list[Capture]) -> list[Capture]:
    """Add a capture group and return only the newly emitted captures."""
    return [capture for capture in captures if registry.add(capture)]


def build_capture_groups(arguments: argparse.Namespace) -> list[list[Capture]]:
    """Build deduplicated capture groups in their paste-ready output order."""
    registry = CaptureRegistry()
    groups: list[list[Capture]] = []

    def add_group(captures: list[Capture]) -> None:
        emitted = add_captures(registry, captures)
        if emitted:
            groups.append(emitted)

    for raw_value in arguments.author:
        add_group(author_captures(parse_author_spec(raw_value)))
    for raw_value in arguments.author_pair:
        first_author, second_author, variable_name = parse_author_pair(raw_value)
        add_group(author_pair_captures(first_author, second_author, variable_name))
    for raw_value in arguments.series:
        add_group([link_capture(parse_entity_spec(raw_value, "--series"), "series_link", "series")])
    for raw_value in arguments.book:
        add_group([link_capture(parse_entity_spec(raw_value, "--book"), "book_link", "book")])
    for raw_value in arguments.movie:
        add_group([link_capture(parse_entity_spec(raw_value, "--movie"), "movie_title", "movie")])
    for raw_value in arguments.game:
        add_group([link_capture(parse_entity_spec(raw_value, "--game"), "game_title", "game")])
    for raw_value in arguments.tv_show:
        add_group(
            [
                link_capture(
                    parse_entity_spec(raw_value, "--tv-show"),
                    "tv_show_title",
                    "TV show",
                )
            ]
        )

    return groups


def parse_arguments() -> argparse.Namespace:
    """Define the non-interactive capture-generation command-line interface."""
    parser = argparse.ArgumentParser(
        description="Generate paste-ready Liquid captures for confirmed review references.",
        epilog=(
            "Each repeatable value accepts TITLE or TITLE=variable_name. "
            "Use --author-pair 'First Author|Second Author' for a combined capture."
        ),
    )
    parser.add_argument(
        "--author",
        action="append",
        default=[],
        metavar="NAME[=VARIABLE]",
        help="add a four-variant author capture bundle",
    )
    parser.add_argument(
        "--author-pair",
        action="append",
        default=[],
        metavar="NAME|NAME[=VARIABLE]",
        help="add full-name and possessive captures for two authors",
    )
    parser.add_argument(
        "--book",
        action="append",
        default=[],
        metavar="TITLE[=VARIABLE]",
        help="add a book_link capture; repeat for multiple books",
    )
    parser.add_argument(
        "--series",
        action="append",
        default=[],
        metavar="TITLE[=VARIABLE]",
        help="add a series_link capture",
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
        help="emit the default paste-ready Liquid output without headings",
    )
    arguments = parser.parse_args()
    if not any(
        [
            arguments.author,
            arguments.author_pair,
            arguments.book,
            arguments.series,
            arguments.movie,
            arguments.game,
            arguments.tv_show,
        ]
    ):
        parser.error("provide at least one reference flag, such as --author or --book")
    return arguments


def main() -> None:
    """Generate captures and report invalid input through argparse."""
    arguments = parse_arguments()
    try:
        capture_groups = build_capture_groups(arguments)
    except ValueError as error:
        print(f"error: {error}", file=sys.stderr)
        raise SystemExit(2) from error

    print("\n\n".join("\n".join(capture.render() for capture in group) for group in capture_groups))


if __name__ == "__main__":
    main()
