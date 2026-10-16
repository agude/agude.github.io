"""Tests for common/front_matter.py."""

import yaml
from front_matter import split_front_matter


class TestSplitFrontMatter:
    def test_splits_yaml_and_body(self):
        text = "---\ntitle: Hyperion\nrating: 5\n---\n\nBody.\n"
        assert split_front_matter(text) == ("title: Hyperion\nrating: 5\n", "\nBody.\n")

    def test_triple_dash_inside_value(self):
        text = "---\ntitle: A---B\nrating: 5\n---\nBody.\n"
        yaml_text, body = split_front_matter(text)
        assert yaml.safe_load(yaml_text) == {"title": "A---B", "rating": 5}
        assert body == "Body.\n"

    def test_triple_dash_line_inside_block_scalar(self):
        text = "---\ndescription: |\n  Before\n  ---\n  After\nrating: 5\n---\nBody.\n"
        yaml_text, body = split_front_matter(text)
        assert yaml.safe_load(yaml_text) == {"description": "Before\n---\nAfter\n", "rating": 5}
        assert body == "Body.\n"

    def test_empty_block(self):
        assert split_front_matter("---\n---\nBody.\n") == ("", "Body.\n")

    def test_missing_closing_line(self):
        assert split_front_matter("---\ntitle: Hyperion\n\nBody.\n") is None

    def test_closing_line_with_trailing_text_does_not_close(self):
        assert split_front_matter("---\ntitle: Hyperion\n---B\n") is None

    def test_closing_line_at_end_of_file(self):
        assert split_front_matter("---\ntitle: Hyperion\n---") == ("title: Hyperion\n", "")

    def test_delimiters_with_trailing_spaces(self):
        assert split_front_matter("---  \ntitle: X\n--- \nBody.\n") == ("title: X\n", "Body.\n")

    def test_no_front_matter(self):
        assert split_front_matter("No front matter.\n---\n") is None

    def test_first_line_must_be_a_delimiter(self):
        assert split_front_matter("\n---\ntitle: X\n---\n") is None
