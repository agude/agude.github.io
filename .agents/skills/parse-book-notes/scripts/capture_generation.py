"""Build paste-ready Liquid captures from confirmed review references."""

from __future__ import annotations

import re
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
    """A referenced entity and its Liquid variable name."""

    value: str
    variable_name: str


@dataclass(frozen=True)
class Capture:
    """One Liquid capture and the entity that produced it."""

    name: str
    content: str
    source: str

    def render(self) -> str:
        """Render this capture as Liquid."""
        return f"{{% capture {self.name} %}}{self.content}{{% endcapture %}}"


class CaptureRegistry:
    """Collect captures while rejecting incompatible name collisions."""

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
    """Convert a title or surname to an ASCII snake_case variable name."""
    transliterated = value.translate(TRANSLITERATIONS)
    decomposed = unicodedata.normalize("NFKD", transliterated)
    ascii_value = decomposed.encode("ascii", "ignore").decode("ascii")
    variable_name = re.sub(r"[^a-z0-9]+", "_", ascii_value.lower()).strip("_")
    validate_variable_name(variable_name, value)
    return variable_name


def validate_variable_name(variable_name: str, value: str) -> None:
    """Reject names that Liquid cannot use as conventional variables."""
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
    """Parse NAME or NAME=variable_name, defaulting to the surname."""
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
    """Return the four standard capture variants for an author."""
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
    """Return the full-name and possessive captures for an author pair."""
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


def deduplicate_captures(capture_groups: list[list[Capture]]) -> list[Capture]:
    """Flatten capture groups while removing exact duplicates."""
    registry = CaptureRegistry()
    captures: list[Capture] = []
    for capture_group in capture_groups:
        for capture in capture_group:
            if registry.add(capture):
                captures.append(capture)
    return captures


def build_reference_group(
    raw_authors: list[str],
    raw_author_pairs: list[str],
    raw_books: list[str],
    raw_series: list[str],
) -> list[Capture]:
    """Build one complete author, series, and book reference group."""
    authors = [parse_author_spec(raw_author) for raw_author in raw_authors]
    author_pairs = [parse_author_pair(raw_pair) for raw_pair in raw_author_pairs]
    if not authors:
        raise ValueError("a reference group requires at least one --author")
    if not raw_books and not raw_series:
        raise ValueError("a reference group requires at least one --book or --series")

    author_names = [author.value for author in authors]
    distinct_author_names = set(author_names)
    if len(distinct_author_names) != len(author_names):
        raise ValueError("pass each author only once per reference group")

    for first_author, second_author, _variable_name in author_pairs:
        missing_authors = {first_author.value, second_author.value} - distinct_author_names
        if missing_authors:
            formatted_names = ", ".join(sorted(missing_authors))
            raise ValueError(
                f"--author-pair requires individual --author bundles for {formatted_names}"
            )

    if len(authors) == 2:
        if len(author_pairs) != 1:
            raise ValueError("a two-author reference group requires exactly one --author-pair")
        paired_names = {author_pairs[0][0].value, author_pairs[0][1].value}
        if paired_names != distinct_author_names:
            raise ValueError("--author-pair must contain both authors in the reference group")

    capture_groups = [author_captures(author) for author in authors]
    capture_groups.extend(
        author_pair_captures(first_author, second_author, variable_name)
        for first_author, second_author, variable_name in author_pairs
    )
    capture_groups.extend(
        [link_capture(parse_entity_spec(raw_value, "--series"), "series_link", "series")]
        for raw_value in raw_series
    )
    capture_groups.extend(
        [link_capture(parse_entity_spec(raw_value, "--book"), "book_link", "book")]
        for raw_value in raw_books
    )
    return deduplicate_captures(capture_groups)


def build_standalone_reference(reference_kind: str, raw_value: str) -> list[Capture]:
    """Build one deliberately unlinked author, book, or series reference."""
    if reference_kind == "author":
        return author_captures(parse_author_spec(raw_value))

    tag_names = {"book": "book_link", "series": "series_link"}
    try:
        tag_name = tag_names[reference_kind]
    except KeyError as error:
        raise ValueError(f"unsupported standalone reference type: {reference_kind}") from error
    entity = parse_entity_spec(raw_value, f"--{reference_kind}")
    return [link_capture(entity, tag_name, reference_kind)]


def build_media_references(
    raw_movies: list[str],
    raw_games: list[str],
    raw_tv_shows: list[str],
) -> list[Capture]:
    """Build standalone captures for movie, game, and television titles."""
    capture_groups = [
        [link_capture(parse_entity_spec(raw_value, "--movie"), "movie_title", "movie")]
        for raw_value in raw_movies
    ]
    capture_groups.extend(
        [link_capture(parse_entity_spec(raw_value, "--game"), "game_title", "game")]
        for raw_value in raw_games
    )
    capture_groups.extend(
        [
            link_capture(
                parse_entity_spec(raw_value, "--tv-show"),
                "tv_show_title",
                "TV show",
            )
        ]
        for raw_value in raw_tv_shows
    )
    return deduplicate_captures(capture_groups)


def render_captures(captures: list[Capture]) -> str:
    """Render captures contiguously in paste-ready order."""
    return "\n".join(capture.render() for capture in captures)
