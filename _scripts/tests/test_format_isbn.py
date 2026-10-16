"""Tests for metadata/format_isbn.py."""

import sys
from pathlib import Path

from format_isbn import extract_isbn, format_isbn, main


class TestFormatIsbn:
    def test_formats_isbn13_without_hyphens(self):
        result = format_isbn("9780316769488")
        assert result == "978-0-316-76948-8"

    def test_formats_isbn13_with_wrong_hyphens(self):
        result = format_isbn("978-031-676-9488")
        assert result == "978-0-316-76948-8"

    def test_converts_isbn10_to_isbn13(self):
        result = format_isbn("0316769487")
        assert result.startswith("978-")
        assert len(result) == 17  # ISBN-13 with hyphens

    def test_invalid_isbn_returns_none(self):
        assert format_isbn("1234567890") is None
        assert format_isbn("notanisbn") is None
        assert format_isbn("") is None

    def test_already_formatted_unchanged(self):
        isbn = "978-0-316-76948-8"
        result = format_isbn(isbn)
        assert result == isbn


class TestExtractIsbn:
    def test_extracts_simple_isbn(self):
        fm = "title: Test\nisbn: 9780316769488\n"
        assert extract_isbn("test.md", fm) == "9780316769488"

    def test_extracts_quoted_isbn(self):
        fm = 'isbn: "978-0-316-76948-8"\n'
        assert extract_isbn("test.md", fm) == "978-0-316-76948-8"

    def test_null_returns_none(self):
        fm = "isbn: null\n"
        assert extract_isbn("test.md", fm) is None

    def test_missing_isbn_returns_none(self):
        fm = "title: Test\nauthor: Someone\n"
        assert extract_isbn("test.md", fm) is None

    def test_handles_malformed_yaml(self):
        # YAML parser fails on tabs; function falls back to regex extraction
        fm = "title: Test\nisbn: 123\nfoo:\tbar\n"
        result = extract_isbn("test.md", fm)
        assert result == "123"


class TestCommandLine:
    # The body repeats the isbn line, and has trailing spaces and non-ASCII
    # text, so a rewrite that strays outside the front matter shows up.
    ORIGINAL = (
        "---\n"
        'title: "The Catcher in the Rye"\n'
        "isbn: 0316769487\n"
        "rating: 4\n"
        "---\n"
        "The body repeats the line:\n"
        "isbn: 0316769487\n"
        "Trailing spaces stay.   \n"
        "Unicode stays: café — “quoted”\n"
    )

    def run(self, monkeypatch, *args: str) -> None:
        monkeypatch.setattr(sys, "argv", ["format_isbn.py", *args])
        main()

    def test_rewrites_only_the_front_matter_isbn(self, tmp_path: Path, monkeypatch, capsys):
        path = tmp_path / "book.md"
        path.write_bytes(self.ORIGINAL.encode())

        self.run(monkeypatch, str(path))

        expected = self.ORIGINAL.replace(
            "isbn: 0316769487\nrating", "isbn: 978-0-316-76948-8\nrating", 1
        )
        assert path.read_bytes() == expected.encode()
        assert "1/1 files changed." in capsys.readouterr().out

    def test_dry_run_leaves_file_unchanged(self, tmp_path: Path, monkeypatch, capsys):
        path = tmp_path / "book.md"
        path.write_bytes(self.ORIGINAL.encode())

        self.run(monkeypatch, "--dry-run", str(path))

        assert path.read_bytes() == self.ORIGINAL.encode()
        out = capsys.readouterr().out
        assert "isbn: 0316769487 -> isbn: 978-0-316-76948-8" in out
        assert "1/1 files would change." in out

    def test_octal_looking_isbn10_is_formatted(self, tmp_path: Path, monkeypatch, capsys):
        # YAML 1.1 reads an unquoted 0306406152 as octal, so the digits must
        # come from the raw front matter text.
        path = tmp_path / "book.md"
        path.write_bytes(b"---\ntitle: T\nisbn: 0306406152\n---\nBody\n")

        self.run(monkeypatch, str(path))

        assert path.read_bytes() == b"---\ntitle: T\nisbn: 978-0-306-40615-7\n---\nBody\n"
        assert "1/1 files changed." in capsys.readouterr().out

    def test_unquoted_integer_isbn13_is_formatted(self, tmp_path: Path, monkeypatch, capsys):
        path = tmp_path / "book.md"
        path.write_bytes(b"---\ntitle: T\nisbn: 9780306406157\n---\nBody\n")

        self.run(monkeypatch, str(path))

        assert path.read_bytes() == b"---\ntitle: T\nisbn: 978-0-306-40615-7\n---\nBody\n"
