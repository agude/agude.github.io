"""Tests for fonts/subset_math_font.py and the math font it built.

The committed font must cover every character the TeX-to-MathML converter
can emit; a symbol added to the converter without rebuilding the font would
otherwise render in a fallback font, or not at all.
"""

from pathlib import Path

import pytest
from fontTools.ttLib import TTFont
from subset_math_font import (
    FAMILY,
    LICENSE_DESCRIPTION,
    LICENSE_URL,
    OUTPUT,
    POSTSCRIPT_NAME,
    RADICAL,
    SOURCE_URL,
    converter_characters,
    description,
    unicodes,
)


@pytest.fixture(scope="module")
def font() -> TTFont:
    return TTFont(OUTPUT)


def test_font_covers_every_code_point_the_subset_keeps(font):
    missing = [f"U+{code:04X}" for code in unicodes() if code not in font.getBestCmap()]

    assert not missing, (
        f"{OUTPUT.name} lacks {', '.join(missing)}; "
        "rerun _scripts/fonts/subset_math_font.py on latinmodern-math.otf"
    )


def test_subset_includes_converter_symbols_and_radical():
    codes = unicodes()

    assert ord("±") in codes
    assert ord("→") in codes
    assert RADICAL in codes
    assert 0x1D465 in codes  # math italic x: browsers draw <mi>x</mi> with it


def test_converter_characters_reads_non_ascii_only(tmp_path: Path):
    source = tmp_path / "converter.rb"
    source.write_text("'pm' => %w[mo ±], 'to' => %w[mo →] # plain ascii\n", encoding="utf-8")

    assert converter_characters(source) == {ord("±"), ord("→")}


def test_font_keeps_math_table(font):
    # The MATH table holds the stretched radical and bracket variants.
    assert "MATH" in font


def test_font_is_renamed(font):
    # LPPL 1.3c clause 6a: a modified version identifies itself as modified.
    names = font["name"]

    assert names.getDebugName(1) == FAMILY
    assert names.getDebugName(6) == POSTSCRIPT_NAME
    assert "Latin Modern Math" in names.getDebugName(5)


def test_font_carries_license_and_modification_notices(font):
    names = font["name"]

    assert "GUST Font License" in names.getDebugName(0)  # original notice kept
    assert names.getDebugName(10) == description(f"{font['head'].fontRevision:.3f}")
    assert SOURCE_URL in names.getDebugName(10)  # clause 6d: where the original is
    assert names.getDebugName(13) == LICENSE_DESCRIPTION
    assert names.getDebugName(14) == LICENSE_URL
