# not-a-script
"""Serialize strings as YAML scalars that parse back to the same string.

Shared by every script that writes YAML front matter as text. CLIs outside
this directory import it after adding it to sys.path, because `uv run` puts
only the script's own directory on the path.
"""

from __future__ import annotations

import json

_YAML_SPECIAL_CHARACTERS = frozenset(":#'\"[]{},&*?|>!%")

# Plain scalars that YAML 1.1 or 1.2 resolves to a non-string type.
_YAML_TYPED_WORDS = frozenset(
    {
        "null",
        "true",
        "false",
        "yes",
        "no",
        "on",
        "off",
        "~",
        ".nan",
        ".inf",
        "+.inf",
        "-.inf",
    }
)


def _needs_yaml_quoting(value: str) -> bool:
    """Return whether a string could be misread as YAML syntax or a type."""
    stripped_value = value.strip()
    if not value or value != stripped_value:
        return True
    if any(char.isspace() and char != " " for char in value):
        return True
    if value[0].isdigit() or value[0] in "-+?:.@`":
        return True
    if any(char in value for char in _YAML_SPECIAL_CHARACTERS):
        return True
    return value.casefold() in _YAML_TYPED_WORDS


def yaml_scalar(value: str) -> str:
    """Serialize a string as a readable YAML scalar."""
    if _needs_yaml_quoting(value):
        # JSON double-quoted strings are valid YAML and escape all string data.
        return json.dumps(value, ensure_ascii=False)
    return value
