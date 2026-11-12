#!/usr/bin/env python3
# /// script
# requires-python = ">=3.12"
# dependencies = ["fonttools[woff]>=4.50"]
# ///
"""Subset Latin Modern Math into the site's self-hosted math font.

TexToMathml (_plugins/src/infrastructure/tex_to_mathml.rb) renders post math
as MathML, which browsers draw in a math font. This builds the one the site
ships, so math looks the same on every platform, from the Latin Modern Math
OTF on CTAN (https://ctan.org/pkg/lm-math).

The subset keeps the MATH table, which carries the stretched radicals and
brackets. It covers printable ASCII, every non-ASCII character in
tex_to_mathml.rb (the converter's symbol tables), the radical sign <msqrt>
draws, and the math-italic letters browsers substitute for a one-letter
<mi>. Rerun it after adding a symbol to the converter;
test_subset_math_font.py fails until you do.

It drops the OpenType layout features. The only one that matters for math,
`ssty` (script-size glyph variants), doubles the file and made no visible
difference in Chromium, Firefox, or WebKit.

Latin Modern Math is under the GUST Font License, an instance of LPPL 1.3c,
whose clause 6 governs modified versions. The font is served to every
visitor, so the notices travel inside it: the original copyright and license
(name ID 0), a new name ("Gude Math", in the name table and the file name),
and a description (name ID 10) of the changes, of the original authors'
non-support, and of where to get the unmodified font. LICENSE.md repeats this
for the repository.

Example: ~/Downloads/latinmodern-math.otf
"""

import argparse
import sys
from pathlib import Path

from fontTools import subset
from fontTools.ttLib import TTFont

REPO_ROOT = Path(__file__).resolve().parents[2]
OUTPUT = REPO_ROOT / "assets" / "fonts" / "gude-math-latin-modern-subset.woff2"

FAMILY = "Gude Math"
POSTSCRIPT_NAME = "GudeMath-Regular"
SOURCE_NAME = "Latin Modern Math"
SOURCE_URL = "https://ctan.org/pkg/lm-math"
REPO_URL = "https://github.com/agude/agude.github.io"
LICENSE_DESCRIPTION = (
    "GUST Font License, an instance of the LaTeX Project Public License 1.3c. "
    "Modified versions must follow its clause 6."
)
LICENSE_URL = "https://tug.org/fonts/licenses/GUST-FONT-LICENSE.txt"

CONVERTER = REPO_ROOT / "_plugins" / "src" / "infrastructure" / "tex_to_mathml.rb"

PRINTABLE_ASCII = range(0x20, 0x7F)
# Drawn by <msqrt>, though no TeX source names it.
RADICAL = 0x221A
# Browsers render a one-letter <mi> in these math-italic code points.
MATH_ITALIC = [
    0x210E,  # Planck constant: the italic h; U+1D455 is unassigned
    *range(0x1D434, 0x1D455),  # italic Latin A-Z, a-g
    *range(0x1D456, 0x1D468),  # italic Latin i-z
    *range(0x1D6A4, 0x1D6A6),  # italic dotless i and j
    *range(0x1D6E2, 0x1D71C),  # italic Greek
]


def converter_characters(converter: Path = CONVERTER) -> set[int]:
    """Return the non-ASCII code points in the converter's source."""
    return {ord(char) for char in converter.read_text(encoding="utf-8") if ord(char) > 0x7F}


def unicodes() -> list[int]:
    """Return every code point the subset keeps."""
    return sorted({*PRINTABLE_ASCII, RADICAL, *MATH_ITALIC, *converter_characters()})


def description(source_version: str) -> str:
    """Return the modification notice LPPL 1.3c clause 6 asks a derived work to carry.

    It states the nature of the changes (6b), that the original authors do
    not support this version (6c), and where to get the unmodified font (6d).
    """
    return (
        f"Modified version of {SOURCE_NAME} {source_version}: reduced to the characters "
        "the alexgude.com math converter emits, OpenType layout features removed, and "
        f"renamed. Built by _scripts/fonts/subset_math_font.py in {REPO_URL}. "
        "The authors of Latin Modern Math do not support this version. "
        f"The unmodified font is at {SOURCE_URL}."
    )


def rename(font: TTFont, source_version: str) -> None:
    """Rename the subset and state its changes and license, as the GUST Font License asks."""
    names = {
        1: FAMILY,
        3: f"{source_version};{POSTSCRIPT_NAME}",
        4: FAMILY,
        5: f"Version {source_version}; subset of {SOURCE_NAME}",
        6: POSTSCRIPT_NAME,
        10: description(source_version),
        13: LICENSE_DESCRIPTION,
        14: LICENSE_URL,
        16: FAMILY,
    }
    name_table = font["name"]
    for name_id, text in names.items():
        name_table.setName(text, name_id, 3, 1, 0x409)  # Windows, Unicode BMP, English
        name_table.setName(text, name_id, 1, 0, 0)  # Macintosh, Roman, English
    cff = font["CFF "].cff
    cff.fontNames = [POSTSCRIPT_NAME]
    top = cff.topDictIndex[0]
    top.FullName = FAMILY
    top.FamilyName = FAMILY


def build(source: Path, output: Path) -> None:
    """Subset, rename, and write the font as WOFF2."""
    font = TTFont(source)
    family = font["name"].getDebugName(1)
    if family != SOURCE_NAME:
        sys.exit(f"Expected {SOURCE_NAME}, got {family!r}: {source}")
    source_version = font["head"].fontRevision

    options = subset.Options()
    options.layout_features = []
    options.name_IDs = ["*"]
    options.name_languages = ["*"]
    options.notdef_outline = True
    options.flavor = "woff2"
    subsetter = subset.Subsetter(options)
    subsetter.populate(unicodes=unicodes())
    subsetter.subset(font)
    if "MATH" not in font:
        sys.exit("The subset lost its MATH table; radicals and brackets would not stretch.")

    rename(font, f"{source_version:.3f}")
    font.flavor = "woff2"
    output.parent.mkdir(parents=True, exist_ok=True)
    font.save(output)
    print(f"Wrote {output.relative_to(REPO_ROOT)} ({output.stat().st_size:,} bytes)")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("source", type=Path, help="latinmodern-math.otf from CTAN")
    parser.add_argument("--output", type=Path, default=OUTPUT)
    args = parser.parse_args()
    build(args.source, args.output)


if __name__ == "__main__":
    main()
