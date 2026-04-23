"""Tests for metadata/fetch_author_same_as.py pure functions."""

from fetch_author_same_as import AUTHOR_PROPERTY_MAP, format_yaml


class TestFormatYaml:
    def test_full_metadata(self):
        result = format_yaml(
            urls=["https://www.wikidata.org/wiki/Q312579"],
            pseudonyms=["Iain Banks"],
            title="Iain M. Banks",
        )
        assert "title: Iain M. Banks" in result
        assert "pen_names:" in result
        assert "  - Iain Banks" in result
        assert "same_as_urls:" in result
        assert "https://www.wikidata.org/wiki/Q312579" in result

    def test_no_pseudonyms(self):
        result = format_yaml(
            urls=["https://example.com"],
            pseudonyms=[],
            title="Single Name Author",
        )
        assert "pen_names" not in result
        assert "same_as_urls:" in result

    def test_multiple_pseudonyms(self):
        result = format_yaml(
            urls=["https://example.com"],
            pseudonyms=["Pen Name One", "Pen Name Two"],
            title="Real Name",
        )
        assert "pen_names:" in result
        assert "  - Pen Name One" in result
        assert "  - Pen Name Two" in result

    def test_multiple_urls(self):
        result = format_yaml(
            urls=["https://one.com", "https://two.com"],
            pseudonyms=[],
            title="Author",
        )
        assert "same_as_urls:" in result
        assert "https://one.com" in result
        assert "https://two.com" in result

    def test_title_needs_quoting(self):
        result = format_yaml(
            urls=["https://example.com"],
            pseudonyms=[],
            title="Name: With Colon",
        )
        assert 'title: "Name: With Colon"' in result


class TestAuthorPropertyMap:
    def test_all_entries_have_three_elements(self):
        for entry in AUTHOR_PROPERTY_MAP:
            assert len(entry) == 3

    def test_property_ids_start_with_p(self):
        for prop_id, _, _ in AUTHOR_PROPERTY_MAP:
            assert prop_id.startswith("P")

    def test_templates_contain_value_placeholder(self):
        for _, _, template in AUTHOR_PROPERTY_MAP:
            if template is not None:
                assert "{value}" in template
