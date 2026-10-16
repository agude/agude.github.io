# not-a-script
"""Split a Markdown file into its YAML front matter and body.

Shared by every script that reads or rewrites front matter as text. CLIs
outside this directory import it after adding it to sys.path, because
`uv run` puts only the script's own directory on the path.
"""

from __future__ import annotations

import re

# Only a line that is exactly `---` (trailing spaces allowed) opens or closes
# the block, so `---` inside a value or an indented block scalar does not.
_FRONT_MATTER_RE = re.compile(r"\A---[ \t]*\n(.*?\n)?---[ \t]*(?:\n|\Z)", re.DOTALL)


def split_front_matter(text: str) -> tuple[str, str] | None:
    """Return `(yaml_text, body)`, or None if `text` has no front matter block.

    `yaml_text` is the text between the delimiter lines, including its final
    newline; it is empty for an empty block. `body` is everything after the
    closing delimiter line.
    """
    match = _FRONT_MATTER_RE.match(text)
    if match is None:
        return None
    return match.group(1) or "", text[match.end() :]
