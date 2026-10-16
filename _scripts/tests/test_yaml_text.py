"""Tests for common/yaml_text.py."""

import pytest
import yaml
from yaml_text import _needs_yaml_quoting, yaml_scalar


class TestYamlScalar:
    def test_simple_string_unchanged(self):
        assert yaml_scalar("hello") == "hello"

    def test_string_with_colon_quoted(self):
        assert yaml_scalar("foo: bar") == '"foo: bar"'

    def test_string_with_quotes_escaped(self):
        assert yaml_scalar('say "hello"') == '"say \\"hello\\""'

    def test_backslash_alone_is_not_quoted(self):
        assert yaml_scalar("path\\to\\file") == "path\\to\\file"

    @pytest.mark.parametrize(
        "value",
        [
            "no",
            "No",
            "null",
            "true",
            "123",
            "1989-05-01",
            "Book #1",
            "A: B",
            'He said "hi"',
            "'Quoted'",
            "https://example.com/path?query=1",
            "path\\to\\file",
            "- dash",
            " padded ",
            "",
        ],
    )
    def test_round_trips_as_the_same_string(self, value):
        assert yaml.safe_load(f"key: {yaml_scalar(value)}") == {"key": value}


class TestNeedsYamlQuoting:
    def test_plain_string_no_quoting(self):
        assert _needs_yaml_quoting("hello") is False

    @pytest.mark.parametrize("value", ["key: value", "[item]", "foo & bar", "yes", "7"])
    def test_yaml_significant_strings_need_quoting(self, value):
        assert _needs_yaml_quoting(value) is True
