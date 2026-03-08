"""Tests for ranking/extract_book_data.py pure functions."""

from extract_book_data import clean_liquid, extract_paragraphs, parse_front_matter


class TestParseFrontMatter:
    def test_basic_fields(self):
        content = "---\ntitle: Hyperion\nrating: 5\n---\nBody text."
        fm, body = parse_front_matter(content)
        assert fm["title"] == "Hyperion"
        assert fm["rating"] == 5
        assert "Body text." in body

    def test_list_field(self):
        content = "---\nbook_authors:\n- Dan Simmons\n- Another Author\n---\n"
        fm, _ = parse_front_matter(content)
        assert fm["book_authors"] == ["Dan Simmons", "Another Author"]

    def test_boolean_and_null(self):
        content = "---\npublished: true\ndraft: false\ncanonical_url: null\n---\n"
        fm, _ = parse_front_matter(content)
        assert fm["published"] is True
        assert fm["draft"] is False
        assert fm["canonical_url"] is None

    def test_quoted_values(self):
        content = '---\ntitle: "A Book: With Colon"\n---\n'
        fm, _ = parse_front_matter(content)
        assert fm["title"] == "A Book: With Colon"

    def test_missing_delimiters(self):
        fm, body = parse_front_matter("No front matter here.")
        assert fm == {}
        assert body == ""

    def test_empty_value_is_none(self):
        content = "---\nseries:\n---\n"
        fm, _ = parse_front_matter(content)
        assert fm["series"] is None

    def test_duplicate_key_uses_last_value(self):
        content = "---\ntitle: First\ntitle: Second\n---\n"
        fm, _ = parse_front_matter(content)
        assert fm["title"] == "Second"


class TestExtractParagraphs:
    def test_two_paragraphs(self):
        body = "\nFirst paragraph text.\n\nSecond paragraph here.\n"
        first, second = extract_paragraphs(body)
        assert "First paragraph" in first
        assert "Second paragraph" in second

    def test_skips_capture_blocks(self):
        body = "\n{% capture my_var %}stuff{% endcapture %}\n\nActual paragraph.\n"
        first, _ = extract_paragraphs(body)
        assert "Actual paragraph" in first

    def test_empty_body(self):
        first, second = extract_paragraphs("")
        assert first == ""
        assert second == ""


class TestCleanLiquid:
    def test_strips_liquid_tags(self):
        result = clean_liquid("Hello {% book_link 'Hyperion' %} world")
        assert "{%" not in result
        assert "Hello" in result
        assert "world" in result

    def test_strips_output_tags(self):
        result = clean_liquid("By {{ author_name }}, this is great")
        assert "{{" not in result

    def test_strips_html(self):
        result = clean_liquid("The <cite>book</cite> is good")
        assert "<cite>" not in result
        assert "good" in result

    def test_capitalizes_first_letter(self):
        result = clean_liquid("simple text here")
        assert result[0] == "S"

    def test_already_capitalized_unchanged(self):
        result = clean_liquid("Already capitalized")
        assert result == "Already capitalized"

    def test_empty_string(self):
        result = clean_liquid("")
        assert result == ""
