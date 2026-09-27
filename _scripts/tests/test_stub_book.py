"""Tests for skills/stub_book.py pure functions."""

import sys

import pytest
import yaml
from stub_book import (
    build_front_matter,
    build_opening,
    build_template,
    main,
    number_word,
    ordinal,
    slugify,
)


class TestSlugify:
    def test_simple_title(self):
        assert slugify("Hyperion") == "hyperion"

    def test_multi_word(self):
        assert slugify("The Honor of the Queen") == "the_honor_of_the_queen"

    def test_apostrophe_stripped(self):
        assert slugify("Ender's Game") == "enders_game"

    def test_colon_stripped(self):
        assert slugify("Star Wars: A New Hope") == "star_wars_a_new_hope"

    def test_leading_trailing_whitespace(self):
        assert slugify("  Dune  ") == "dune"

    def test_multiple_spaces_collapsed(self):
        assert slugify("The   Long    Way") == "the_long_way"

    def test_unicode_preserved(self):
        assert slugify("Tête-à-Tête") == "tête_à_tête"
        assert slugify("José García") == "josé_garcía"


class TestOrdinal:
    def test_first_three(self):
        assert ordinal(1) == "1st"
        assert ordinal(2) == "2nd"
        assert ordinal(3) == "3rd"

    def test_fourth_through_tenth(self):
        assert ordinal(4) == "4th"
        assert ordinal(10) == "10th"

    def test_teens_use_th(self):
        assert ordinal(11) == "11th"
        assert ordinal(12) == "12th"
        assert ordinal(13) == "13th"

    def test_twenty_first(self):
        assert ordinal(21) == "21st"
        assert ordinal(22) == "22nd"
        assert ordinal(23) == "23rd"
        assert ordinal(24) == "24th"

    def test_hundred_eleven_through_thirteen(self):
        assert ordinal(111) == "111th"
        assert ordinal(112) == "112th"
        assert ordinal(113) == "113th"

    def test_hundred_twenty_one(self):
        assert ordinal(121) == "121st"


class TestNumberWord:
    def test_first_ten_spelled_out(self):
        assert number_word(1) == "first"
        assert number_word(2) == "second"
        assert number_word(3) == "third"
        assert number_word(10) == "tenth"

    def test_above_ten_uses_ordinal(self):
        assert number_word(11) == "11th"
        assert number_word(21) == "21st"


class TestBuildFrontMatter:
    def test_standalone_book(self):
        result = build_front_matter(
            title="Ubik",
            author="Philip K. Dick",
            series=None,
            book_number=1,
            qid=None,
        )
        assert "title: Ubik" in result
        assert "book_authors: Philip K. Dick" in result
        assert "series: null" in result
        assert "image: /books/covers/ubik.jpg" in result
        assert "wikidata_qid" not in result

    def test_series_book_with_qid(self):
        result = build_front_matter(
            title="The Honor of the Queen",
            author="David Weber",
            series="Honor Harrington",
            book_number=2,
            qid="Q123456",
        )
        assert "title: The Honor of the Queen" in result
        assert "series: Honor Harrington" in result
        assert "book_number: 2" in result
        assert "wikidata_qid: Q123456" in result

    def test_image_path_uses_slug(self):
        result = build_front_matter(
            title="A Fire Upon the Deep",
            author="Vernor Vinge",
            series=None,
            book_number=1,
            qid=None,
        )
        assert "image: /books/covers/a_fire_upon_the_deep.jpg" in result

    @pytest.mark.parametrize(
        "value",
        [
            "Title: Subtitle",
            "Title #1",
            'Title\'s "Edition"',
            "Title [Special]",
            "Title {Special}",
            "Title & Co.",
            "What? Title",
            "Title\tTabbed",
            "1_000",
            "0x10",
        ],
    )
    def test_yaml_significant_values_round_trip(self, value):
        result = build_front_matter(
            title=value,
            author=value,
            series=value,
            book_number=2,
            qid=None,
        )

        parsed = yaml.safe_load(result)

        assert parsed["title"] == value
        assert parsed["book_authors"] == value
        assert parsed["series"] == value


class TestBuildOpening:
    def test_standalone(self):
        result = build_opening(series=None, book_number=1)
        assert "standalone novel" in result
        assert "series_text" not in result

    def test_first_in_series(self):
        result = build_opening(series="Honor Harrington", book_number=1)
        assert "first book" in result
        assert "series_text" in result

    def test_second_in_series(self):
        result = build_opening(series="Honor Harrington", book_number=2)
        assert "second book" in result
        assert "series_text" in result

    def test_large_book_number(self):
        result = build_opening(series="Discworld", book_number=41)
        assert "41st book" in result


class TestBuildTemplate:
    def test_replaces_front_matter_sentinel(self):
        result = build_template(
            front_matter="title: Test\nrating: null",
            opening="This is the opening.",
            is_series=False,
        )
        assert "title: Test" in result
        assert "<!-- FRONT_MATTER -->" not in result

    def test_replaces_opening_sentinel(self):
        result = build_template(
            front_matter="title: Test",
            opening="Opening paragraph here.",
            is_series=False,
        )
        assert "Opening paragraph here." in result
        assert "<!-- OPENING -->" not in result

    def test_includes_series_capture_when_is_series(self):
        result = build_template(
            front_matter="title: Test",
            opening="Opening.",
            is_series=True,
        )
        assert "this_series" in result
        assert "<!-- IF_SERIES -->" not in result

    def test_excludes_series_capture_when_standalone(self):
        result = build_template(
            front_matter="title: Test",
            opening="Opening.",
            is_series=False,
        )
        assert "this_series" not in result

    def test_preserves_liquid_captures(self):
        result = build_template(
            front_matter="title: Test",
            opening="Opening.",
            is_series=False,
        )
        assert "{% capture this_book %}" in result
        assert "{% capture the_author %}" in result


class TestMain:
    def test_existing_output_path_is_not_overwritten(self, tmp_path, monkeypatch, capsys):
        output_path = tmp_path / "existing.md"
        original_content = "existing content\n"
        output_path.write_text(original_content)
        monkeypatch.setattr(
            sys,
            "argv",
            [
                "stub_book.py",
                "--title",
                "New Book",
                "--author",
                "New Author",
                "--output",
                str(output_path),
            ],
        )

        with pytest.raises(SystemExit) as error:
            main()

        assert error.value.code != 0
        assert output_path.read_text() == original_content
        assert "output path already exists" in capsys.readouterr().err

    def test_new_output_path_is_written(self, tmp_path, monkeypatch):
        output_path = tmp_path / "new_book.md"
        monkeypatch.setattr(
            sys,
            "argv",
            [
                "stub_book.py",
                "--title",
                "New Book",
                "--author",
                "New Author",
                "--output",
                str(output_path),
            ],
        )

        main()

        assert output_path.exists()
        assert "title: New Book" in output_path.read_text()
