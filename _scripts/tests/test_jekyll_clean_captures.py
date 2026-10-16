"""Tests for content/jekyll_clean_captures.py pure functions."""

import pytest
from jekyll_clean_captures import find_unused_captures, main, process_file


class TestFindUnusedCaptures:
    def test_no_captures(self):
        assert find_unused_captures("Just some text.") == []

    def test_used_capture_in_output(self):
        content = "{% capture greeting %}Hello{% endcapture %}\n{{ greeting }}\n"
        assert find_unused_captures(content) == []

    def test_used_capture_as_param(self):
        content = (
            "{% capture book_slug %}hyperion{% endcapture %}\n{% book_link slug=book_slug %}\n"
        )
        assert find_unused_captures(content) == []

    def test_unused_capture_detected(self):
        content = (
            "{% capture unused_var %}some value{% endcapture %}\nNo reference to it anywhere.\n"
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
            "{% capture big_block %}\nline1\nline2\n{% endcapture %}\nNothing uses big_block.\n"
        )
        unused = find_unused_captures(content)
        assert len(unused) == 1
        assert unused[0][0] == "big_block"


class TestCaptureUsageForms:
    """Every Liquid form that reads a variable counts as a use."""

    @staticmethod
    def assert_used(usage):
        content = "{% capture x %}value{% endcapture %}\n" + usage + "\n"
        assert find_unused_captures(content) == []

    def test_filter_with_spaces(self):
        self.assert_used("{{ x | strip }}")

    def test_filter_without_spaces(self):
        self.assert_used("{{ x|strip }}")

    def test_whitespace_controlled_output(self):
        self.assert_used("{{- x -}}")

    def test_if(self):
        self.assert_used("{% if x %}yes{% endif %}")

    def test_unless(self):
        self.assert_used("{% unless x %}no{% endunless %}")

    def test_elsif(self):
        self.assert_used("{% if y %}a{% elsif x %}b{% endif %}")

    def test_case(self):
        self.assert_used("{% case x %}{% when 'a' %}A{% endcase %}")

    def test_for(self):
        self.assert_used("{% for i in x %}{{ i }}{% endfor %}")

    def test_assign(self):
        self.assert_used("{% assign y = x %}")

    def test_use_inside_another_capture_body(self):
        content = (
            "{% capture inner %}Dune{% endcapture %}\n"
            "{% capture outer %}See {{ inner }}.{% endcapture %}\n"
            "{{ outer }}\n"
        )
        assert find_unused_captures(content) == []

    def test_whitespace_controlled_definition(self):
        content = "{%- capture x -%}value{%- endcapture -%}\n{{ x }}\n"
        assert find_unused_captures(content) == []

    def test_whitespace_controlled_definition_unused(self):
        content = "{%- capture x -%}value{%- endcapture -%}\nprose\n"
        assert [name for name, _ in find_unused_captures(content)] == ["x"]

    def test_prose_mention_is_not_a_use(self):
        content = "{% capture x %}value{% endcapture %}\nThe letter x.\n"
        assert [name for name, _ in find_unused_captures(content)] == ["x"]

    def test_another_capture_definition_is_not_a_use(self):
        content = "{% capture x %}a{% endcapture %}\n{% capture x %}b{% endcapture %}\n"
        assert [name for name, _ in find_unused_captures(content)] == ["x", "x"]

    def test_longer_identifier_is_not_a_use(self):
        content = "{% capture x %}a{% endcapture %}\n{{ x_long }}\n"
        assert [name for name, _ in find_unused_captures(content)] == ["x"]

    def test_hyphenated_identifier_is_not_a_use(self):
        content = "{% capture x %}a{% endcapture %}\n{{ x-y }}\n"
        assert [name for name, _ in find_unused_captures(content)] == ["x"]


class TestWhitespaceControlUsage:
    """A whitespace-control hyphen next to a name is not part of the name."""

    @pytest.mark.parametrize(
        "usage",
        ["{{x-}}", "{{-x-}}", "{{- x -}}", "{% if x-%}y{% endif %}", "{%- if x -%}y{% endif %}"],
    )
    def test_whitespace_control_form_is_a_use(self, usage):
        content = "{% capture x %}value{% endcapture %}\n" + usage + "\n"
        assert find_unused_captures(content) == []


NESTED_OUTER_UNUSED = (
    "{% capture outer %}{% capture inner %}Dune{% endcapture %}{% endcapture %}\n{{ inner }}\n"
)
NESTED_INNER_UNUSED = (
    "{% capture outer %}{% capture inner %}Dune{% endcapture %}{% endcapture %}\n{{ outer }}\n"
)


class TestNestedCaptures:
    """Nested blocks cannot be paired by the block pattern, so they are refused."""

    @pytest.mark.parametrize("content", [NESTED_OUTER_UNUSED, NESTED_INNER_UNUSED])
    def test_nested_capture_is_refused(self, content):
        with pytest.raises(ValueError, match="nested"):
            find_unused_captures(content)

    @pytest.mark.parametrize("content", [NESTED_OUTER_UNUSED, NESTED_INNER_UNUSED])
    def test_write_leaves_nested_file_unchanged(self, tmp_path, capsys, content):
        path = tmp_path / "post.md"
        path.write_text(content)

        process_file(path, dry_run=False)

        assert path.read_text() == content
        assert str(path) in capsys.readouterr().err


class TestProcessFileWrite:
    def test_write_removes_only_unused_block(self, tmp_path):
        head = "---\ntitle: T\n---\n\n{% capture used %}keep{% endcapture %}\n"
        unused = "{% capture orphan %}\nline 1\n\n\nline 2\n{% endcapture %}\n"
        tail = "\n\n\nBody {{ used }}.\n\n\n\nEnd.\n"
        path = tmp_path / "post.md"
        path.write_text(head + unused + tail)

        process_file(path, dry_run=False)

        assert path.read_text() == head + tail

    def test_dry_run_leaves_file_unchanged(self, tmp_path):
        original = "{% capture orphan %}x{% endcapture %}\nBody.\n"
        path = tmp_path / "post.md"
        path.write_text(original)

        process_file(path, dry_run=True)

        assert path.read_text() == original


class TestMain:
    ORIGINAL = "{% capture orphan %}x{% endcapture %}\nBody.\n"

    def test_default_mode_does_not_modify_file(self, tmp_path):
        path = tmp_path / "post.md"
        path.write_text(self.ORIGINAL)

        main([str(path)])

        assert path.read_text() == self.ORIGINAL

    def test_write_flag_applies_changes(self, tmp_path):
        path = tmp_path / "post.md"
        path.write_text(self.ORIGINAL)

        main(["--write", str(path)])

        assert path.read_text() == "Body.\n"

    @pytest.mark.parametrize("args", [["--write"], []])
    def test_nested_file_is_refused_with_nonzero_exit(self, tmp_path, capsys, args):
        path = tmp_path / "post.md"
        path.write_text(NESTED_OUTER_UNUSED)

        with pytest.raises(SystemExit) as exit_info:
            main([*args, str(path)])

        assert exit_info.value.code == 1
        assert path.read_text() == NESTED_OUTER_UNUSED
        err = capsys.readouterr().err
        assert str(path) in err
        assert "nested" in err
