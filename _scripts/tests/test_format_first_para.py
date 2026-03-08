"""Tests for content/format_first_para.py pure functions."""

from format_first_para import wrap_paragraph


class TestWrapParagraph:
    def test_short_line_unchanged(self):
        result = wrap_paragraph(["Short line."])
        assert result == "Short line."

    def test_joins_multiple_lines(self):
        result = wrap_paragraph(["First part", "second part."])
        assert "First part second part." in result

    def test_wraps_long_text(self):
        words = ["word"] * 30
        result = wrap_paragraph(words)
        lines = result.split("\n")
        assert all(len(line) <= 78 for line in lines)

    def test_does_not_break_long_words(self):
        long_word = "a" * 100
        result = wrap_paragraph([long_word])
        assert long_word in result
