#!/usr/bin/env python3
# /// script
# requires-python = ">=3.10"
# ///
"""Turn a Lychee JSON report into a GitHub issue body and a pass/fail result.

Reads the report written by `lychee --format json`, drops the parse errors
that `at://` link-tag URIs always produce, and writes the remaining broken
links as a Markdown issue body. Prints `has_errors=true|false` for
`$GITHUB_OUTPUT`.

Exit codes: 0 when no links are broken, 1 when at least one is, and 2 when
the report is missing or unreadable (for example, Lychee crashed).

Usage:
    python3 _scripts/ci/lychee_report.py lychee/out.json lychee/issue.md
Example: lychee/out.json lychee/issue.md
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

EXIT_CLEAN = 0
EXIT_BROKEN = 1
EXIT_UNUSABLE = 2

# Lychee cannot build a URL from an at:// URI. It reports the failure with
# the placeholder URL "error:" and names the URI only in the status text.
AT_URI_MARKER = "Cannot parse 'at://"

# Lychee files real failures under these keys: rejected statuses and
# network errors under error_map, timeouts under timeout_map.
FAILURE_MAPS = ("error_map", "timeout_map")


def is_at_uri_error(entry: dict) -> bool:
    """Return True if the entry is Lychee's parse error for an at:// URI."""
    url = entry.get("url", "")
    text = entry.get("status", {}).get("text", "")
    return url.startswith("at://") or AT_URI_MARKER in text


def collect_failures(report: dict) -> list[tuple[str, str, str]]:
    """Return (source file, URL, status text) for every real broken link."""
    failures = []
    for key in FAILURE_MAPS:
        for source, entries in sorted(report.get(key, {}).items()):
            for entry in entries:
                if is_at_uri_error(entry):
                    continue
                status = entry.get("status", {}).get("text", "unknown status")
                failures.append((source, entry.get("url", ""), status))
    return failures


def format_issue(failures: list[tuple[str, str, str]]) -> str:
    """Return a Markdown issue body grouping broken links by source file."""
    lines = [f"Lychee found {len(failures)} broken external link(s)."]
    current_source = None
    for source, url, status in failures:
        if source != current_source:
            lines += ["", f"### {source}", ""]
            current_source = source
        lines.append(f"- <{url}>: {status}")
    return "\n".join(lines) + "\n"


def load_report(path: Path) -> dict | None:
    """Return the parsed report, or None after printing why it is unusable."""
    if not path.is_file():
        print(f"Lychee report is missing: {path}", file=sys.stderr)
        return None
    try:
        report = json.loads(path.read_text())
    except (json.JSONDecodeError, UnicodeDecodeError) as error:
        print(f"Lychee report is invalid JSON: {path}: {error}", file=sys.stderr)
        return None
    if not isinstance(report, dict) or not isinstance(report.get("error_map"), dict):
        print(f"Lychee report is invalid: {path} has no error_map", file=sys.stderr)
        return None
    return report


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    parser.add_argument("report", type=Path, help="Lychee JSON report")
    parser.add_argument("issue_body", type=Path, help="Where to write the issue body")
    args = parser.parse_args(argv)

    report = load_report(args.report)
    if report is None:
        return EXIT_UNUSABLE

    failures = collect_failures(report)
    if not failures:
        print("has_errors=false")
        return EXIT_CLEAN

    args.issue_body.write_text(format_issue(failures))
    print("has_errors=true")
    return EXIT_BROKEN


if __name__ == "__main__":
    sys.exit(main())
