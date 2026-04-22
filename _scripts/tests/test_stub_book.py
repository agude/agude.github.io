"""Tests for skills/stub_book.py pure functions."""

from stub_book import build_front_matter, build_opening, number_word, ordinal, slugify


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
