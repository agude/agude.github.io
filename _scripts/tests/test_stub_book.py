"""Tests for .claude/skills/stub-book/scripts/stub_book.py pure functions."""

import subprocess
from unittest.mock import patch

from stub_book import fetch_metadata


class TestFetchMetadata:
    def test_success(self):
        fake_stdout = (
            "# Hyperion\n"
            "isbn: 978-0-553-28368-3\n"
            "date_published: 1989-05\n"
            "same_as_urls:\n"
            '  - "https://www.wikidata.org/wiki/Q302026"\n'
        )
        with patch("stub_book.subprocess.run") as mock_run:
            mock_run.return_value = subprocess.CompletedProcess(
                args=[], returncode=0, stdout=fake_stdout, stderr=""
            )
            result = fetch_metadata("Q302026")

        assert result["isbn"] == "978-0-553-28368-3"
        assert result["date_published"] == "1989-05"
        assert result["same_as_urls"] == ["https://www.wikidata.org/wiki/Q302026"]

    def test_failure_returns_empty(self):
        with patch("stub_book.subprocess.run") as mock_run:
            mock_run.return_value = subprocess.CompletedProcess(
                args=[], returncode=1, stdout="", stderr="error"
            )
            result = fetch_metadata("Q999999")

        assert result == {}

    def test_malformed_yaml_returns_empty(self):
        with patch("stub_book.subprocess.run") as mock_run:
            mock_run.return_value = subprocess.CompletedProcess(
                args=[], returncode=0, stdout="{{bad yaml", stderr=""
            )
            result = fetch_metadata("Q123")

        assert result == {}
