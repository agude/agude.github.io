"""Tests for the browser-free parts of ci/check_color_scheme.py.

The browser readings themselves run in `make check-colors`; these tests
cover which pages are read and how readings become failures.
"""

from check_color_scheme import (
    PAGE_BACKGROUND,
    PROBES,
    STYLESHEET,
    Probe,
    Reading,
    failures,
    site_pages,
)

LINK = Probe("content link", "a", "color", ("main", "p"))
WHITE = "rgb(255, 255, 255)"
DARK = "rgb(26, 30, 35)"
BACKGROUND = {"light": WHITE, "dark": DARK}


def test_selector_joins_ancestors_and_target():
    assert LINK.selector == "main p a"
    assert PAGE_BACKGROUND.selector == "body"


def test_probe_names_are_unique():
    assert len({p.name for p in PROBES}) == len(PROBES)


def test_site_pages_skips_unstyled_pages_and_redirects(tmp_path):
    styled = f'<link rel="stylesheet" href="{STYLESHEET}">'
    pages = {
        "index.html": styled,
        "404.html": styled,
        "books/hergé/index.html": styled,
        "2016/old/index.html": f'{styled}<meta http-equiv="refresh" content="0; url=/new/">',
        "files/export/index.html": "<p>No site stylesheet.</p>",
    }
    for name, text in pages.items():
        file = tmp_path / name
        file.parent.mkdir(parents=True, exist_ok=True)
        file.write_text(text, encoding="utf-8")

    assert site_pages(tmp_path) == ["/404.html", "/books/hergé/", "/"]


def test_switching_probes_pass():
    readings = [
        Reading("/", PAGE_BACKGROUND, WHITE, DARK),
        Reading("/", LINK, "rgb(51, 100, 163)", "rgb(119, 160, 212)"),
    ]
    assert failures(readings, BACKGROUND, (PAGE_BACKGROUND, LINK)) == []


def test_same_value_in_both_schemes_fails():
    readings = [
        Reading("/", PAGE_BACKGROUND, WHITE, DARK),
        Reading("/", LINK, "rgb(51, 100, 163)", "rgb(51, 100, 163)"),
    ]
    (failure,) = failures(readings, BACKGROUND, (PAGE_BACKGROUND, LINK))
    assert "`content link`" in failure
    assert "in both schemes" in failure


def test_wrong_page_background_fails():
    readings = [Reading("/", PAGE_BACKGROUND, WHITE, "rgb(0, 0, 0)")]
    (failure,) = failures(readings, BACKGROUND, (PAGE_BACKGROUND,))
    assert "rgb(0, 0, 0) in dark, expected rgb(26, 30, 35)" in failure


def test_probe_that_matched_no_page_fails():
    readings = [Reading("/", PAGE_BACKGROUND, WHITE, DARK)]
    (failure,) = failures(readings, BACKGROUND, (PAGE_BACKGROUND, LINK))
    assert failure == "`content link` (main p a) matched no page"
