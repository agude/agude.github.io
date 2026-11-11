"""Tests for the browser-free parts of ci/check_image_sizes.py.

The browser measurement itself runs in `make check-images`; these tests
cover the checks applied to its measurements, the viewport widths derived
from the stylesheet, and how pages are sampled per slot.
"""

from pathlib import Path

import pytest
from check_image_sizes import (
    VARIABLES_SCSS,
    Measurement,
    problems,
    report,
    sample_pages,
    slot_key,
    viewport_widths,
)


def measure(**overrides) -> Measurement:
    """A passing srcset measurement: a 300px slot at 1x given a 300w file."""
    values = {
        "page": "/books/dune/",
        "viewport": 1280,
        "dpr": 1,
        "slot": "img.book-cover-lead",
        "src": "/books/covers/dune.jpg",
        "slot_width": 300.0,
        "declared": 300.0,
        "has_srcset": True,
        "vector": False,
        "delivered": 300,
        "widest_available": 1000,
    }
    values.update(overrides)
    return Measurement(**values)


# --- problems ---


def test_matching_measurement_passes():
    assert problems(measure()) == []


@pytest.mark.parametrize("declared", [250.0, 340.0])
def test_sizes_outside_tolerance_fails(declared):
    [problem] = problems(measure(declared=declared, delivered=600))
    assert "sizes declares" in problem


def test_auto_sizes_is_not_compared():
    assert problems(measure(declared=None)) == []


def test_too_narrow_file_fails_when_source_is_wider():
    [problem] = problems(measure(dpr=2, delivered=300))
    assert "for a 600px need" in problem


def test_too_narrow_file_passes_when_source_is_the_limit():
    assert problems(measure(dpr=2, delivered=300, widest_available=300)) == []


def test_three_x_needs_only_two_x():
    assert problems(measure(dpr=3, delivered=600)) == []


def test_oversized_file_fails():
    [problem] = problems(measure(slot_width=140.0, declared=None, delivered=300))
    assert "over 2x" in problem


@pytest.mark.parametrize(
    "overrides",
    [{"has_srcset": False}, {"vector": True}, {"slot_width": 0.0}],
)
def test_unchecked_images_pass(overrides):
    assert problems(measure(delivered=4000, declared=10.0, **overrides)) == []


def test_wrong_descriptor_fails():
    mismatch = "/d/one.png is 1w, srcset says 600w"
    [problem] = problems(measure(mismatches=(mismatch,)))
    assert mismatch in problem


# --- report ---


def test_report_fails_slot_never_measured():
    table, failures = report([measure()], {"img.book-cover-lead": ["/a/"], ".hidden img": ["/b/"]})
    assert "`img.book-cover-lead`" in table
    assert failures == ["`.hidden img` on /b/ was never visible, so it was not measured"]


# --- viewport_widths ---


def test_widths_bracket_each_breakpoint():
    scss = "$large-breakpoint: 38em;\n$other: 2em;\n$wide-breakpoint: 64em;\n"
    widths = viewport_widths(scss)
    assert {607, 608, 1023, 1024} <= set(widths)
    assert 32 not in widths
    assert widths == sorted(widths)


def test_real_stylesheet_has_breakpoints():
    widths = viewport_widths(VARIABLES_SCSS.read_text())
    assert {607, 608} <= set(widths)


# --- slot_key and sample_pages ---


def test_slot_key_prefers_id_then_class_then_ancestor():
    assert slot_key("lead-image", ["x"], [["post"]]) == "#lead-image"
    assert slot_key(None, ["book-cover-lead"], [["post"]]) == "img.book-cover-lead"
    assert slot_key(None, [], [[], ["card-element", "card-image"]]) == (
        ".card-element.card-image img"
    )
    assert slot_key(None, [], [[]] * 4 + [["far"]]) == "img"


def write_page(site: Path, path: str, body: str) -> None:
    page = site / path / "index.html"
    page.parent.mkdir(parents=True, exist_ok=True)
    page.write_text(f"<!doctype html><html><body>{body}</body></html>")


def test_sample_pages_takes_a_few_pages_per_slot(tmp_path):
    card = '<div class="card"><img src="/a.png"><br></div>'
    for name in ("a", "b", "c"):
        write_page(tmp_path, name, card)
    write_page(tmp_path, ".", '<img id="lead-image" src="/b.png">')
    write_page(tmp_path, "empty", "<p>No images.</p>")

    assert sample_pages(tmp_path, per_slot=2) == {
        ".card img": ["/a/", "/b/"],
        "#lead-image": ["/"],
    }
