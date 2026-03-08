"""Tests for content/jekyll_clean_captures.py pure functions."""

from jekyll_clean_captures import find_unused_captures


class TestFindUnusedCaptures:
    def test_no_captures(self):
        assert find_unused_captures("Just some text.") == []

    def test_used_capture_in_output(self):
        content = "{% capture greeting %}Hello{% endcapture %}\n{{ greeting }}\n"
        assert find_unused_captures(content) == []

    def test_used_capture_as_param(self):
        content = (
            "{% capture book_slug %}hyperion{% endcapture %}\n"
            "{% book_link slug=book_slug %}\n"
        )
        assert find_unused_captures(content) == []

    def test_unused_capture_detected(self):
        content = (
            "{% capture unused_var %}some value{% endcapture %}\n"
            "No reference to it anywhere.\n"
        )
        unused = find_unused_captures(content)
        assert len(unused) == 1
        assert unused[0][0] == "unused_var"

    def test_mixed_used_and_unused(self):
        content = (
            "{% capture used %}yes{% endcapture %}\n"
            "{% capture orphan %}no{% endcapture %}\n"
            "{{ used }}\n"
        )
        unused = find_unused_captures(content)
        assert len(unused) == 1
        assert unused[0][0] == "orphan"

    def test_multiline_capture(self):
        content = (
            "{% capture big_block %}\nline1\nline2\n{% endcapture %}\n"
            "Nothing uses big_block.\n"
        )
        unused = find_unused_captures(content)
        assert len(unused) == 1
        assert unused[0][0] == "big_block"
