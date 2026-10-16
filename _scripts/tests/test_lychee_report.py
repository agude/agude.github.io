"""Tests for ci/lychee_report.py, run against captured Lychee 0.24.2 reports.

The fixtures in fixtures/lychee/ are real `lychee --format json` output from
pages served by `python -m http.server`: a 200 link, a 404 link, a link to a
closed port, and an `at://` link-tag URI.
"""

from pathlib import Path

import pytest
from lychee_report import main

FIXTURES = Path(__file__).parent / "fixtures" / "lychee"


@pytest.fixture
def report(tmp_path, capsys):
    """Run the script on a report; return (exit code, issue body, output)."""

    def _run(path: Path) -> tuple[int, str, str]:
        body_path = tmp_path / "issue.md"
        code = main([str(path), str(body_path)])
        body = body_path.read_text() if body_path.exists() else ""
        captured = capsys.readouterr()
        return code, body, captured.out + captured.err

    return _run


def test_404_fails_and_lists_url_and_status(report):
    code, body, out = report(FIXTURES / "404_only.json")
    assert code == 1
    assert "has_errors=true" in out
    assert "http://127.0.0.1:8765/missing.html" in body
    assert "404" in body


def test_connection_error_fails_and_lists_url(report):
    code, body, out = report(FIXTURES / "timeout.json")
    assert code == 1
    assert "has_errors=true" in out
    assert "http://127.0.0.1:9/closed" in body


def test_at_uri_parse_error_only_passes(report):
    code, body, out = report(FIXTURES / "at_only.json")
    assert code == 0
    assert "has_errors=false" in out
    assert "at://" not in body


def test_mixed_report_lists_404_and_omits_at_uri(report):
    code, body, out = report(FIXTURES / "mixed.json")
    assert code == 1
    assert "has_errors=true" in out
    assert "http://127.0.0.1:8765/missing.html" in body
    assert "http://127.0.0.1:9/closed" in body
    assert "at://" not in body
    assert "http://127.0.0.1:8765/ok.html" not in body


def test_clean_report_passes(report):
    code, body, out = report(FIXTURES / "clean.json")
    assert code == 0
    assert "has_errors=false" in out
    assert "127.0.0.1" not in body


def test_missing_report_is_unusable(report, tmp_path):
    code, _, out = report(tmp_path / "does-not-exist.json")
    assert code == 2
    assert "missing" in out
    assert "has_errors" not in out


def test_malformed_report_is_unusable(report, tmp_path):
    bad = tmp_path / "out.json"
    bad.write_text("# Summary\n\n| Status | Count |\n")
    code, _, out = report(bad)
    assert code == 2
    assert "invalid" in out
    assert "has_errors" not in out


def test_report_without_error_map_is_unusable(report, tmp_path):
    bad = tmp_path / "out.json"
    bad.write_text('{"total": 3}')
    code, _, out = report(bad)
    assert code == 2
    assert "invalid" in out


def test_timeout_map_entries_count_as_errors(report, tmp_path):
    path = tmp_path / "out.json"
    path.write_text(
        '{"error_map": {}, "timeout_map": {"_site/a/index.html": '
        '[{"url": "https://slow.example/", "status": {"text": "Timeout"}}]}}'
    )
    code, body, _ = report(path)
    assert code == 1
    assert "https://slow.example/" in body
