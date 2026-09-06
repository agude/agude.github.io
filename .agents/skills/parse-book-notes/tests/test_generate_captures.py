"""Tests for the parse-book-notes capture generator."""

from __future__ import annotations

import importlib.util
import sys
from argparse import Namespace
from pathlib import Path

import pytest

SCRIPT_PATH = Path(__file__).parents[1] / "scripts" / "generate_captures.py"
MODULE_SPEC = importlib.util.spec_from_file_location("generate_captures", SCRIPT_PATH)
if MODULE_SPEC is None or MODULE_SPEC.loader is None:
    message = f"Cannot load capture generator from {SCRIPT_PATH}"
    raise RuntimeError(message)

capture_generator = importlib.util.module_from_spec(MODULE_SPEC)
sys.modules[MODULE_SPEC.name] = capture_generator
MODULE_SPEC.loader.exec_module(capture_generator)
build_capture_groups = capture_generator.build_capture_groups
main = capture_generator.main


def capture_arguments(**overrides: list[str]) -> Namespace:
    """Build command-line arguments for capture generation tests."""
    defaults = {
        "author": [],
        "author_pair": [],
        "book": [],
        "series": [],
        "movie": [],
        "game": [],
        "tv_show": [],
    }
    return Namespace(**(defaults | overrides))


def render_capture_groups(arguments: Namespace) -> str:
    """Render generated groups in the same form printed by the command."""
    groups = build_capture_groups(arguments)
    return "\n\n".join(
        "\n".join(capture.render() for capture in group) for group in groups
    )


class TestCaptureGeneration:
    def test_generates_standard_author_bundle_and_multiple_books(self):
        output = render_capture_groups(
            capture_arguments(
                author=["Iain M. Banks"],
                series=["Culture"],
                book=["Surface Detail", "The Player of Games"],
            )
        )

        assert output == (
            '{% capture banks %}{% author_link "Iain M. Banks" %}{% endcapture %}\n'
            '{% capture bankss %}{% author_link "Iain M. Banks" possessive %}{% endcapture %}\n'
            '{% capture banks_lastname %}{% author_link "Iain M. Banks" link_text="Banks" %}{% endcapture %}\n'
            '{% capture bankss_lastname %}{% author_link "Iain M. Banks" link_text="Banks" possessive %}{% endcapture %}\n\n'
            '{% capture culture %}{% series_link "Culture" %}{% endcapture %}\n\n'
            '{% capture surface_detail %}{% book_link "Surface Detail" %}{% endcapture %}\n\n'
            '{% capture the_player_of_games %}{% book_link "The Player of Games" %}{% endcapture %}'
        )

    def test_deduplicates_repeated_books(self):
        output = render_capture_groups(
            capture_arguments(book=["Surface Detail", "Surface Detail"])
        )

        assert (
            output
            == '{% capture surface_detail %}{% book_link "Surface Detail" %}{% endcapture %}'
        )

    def test_generates_custom_pair_capture(self):
        output = render_capture_groups(
            capture_arguments(
                author_pair=["Arkady Strugatsky|Boris Strugatsky=arkady_and_boris"]
            )
        )

        assert output == (
            '{% capture arkady_and_boris %}{% author_link "Arkady Strugatsky" %} and {% author_link "Boris Strugatsky" %}{% endcapture %}\n'
            '{% capture arkady_and_boriss %}{% author_link "Arkady Strugatsky" %} and {% author_link "Boris Strugatsky" possessive %}{% endcapture %}'
        )

    def test_rejects_capture_name_collisions(self):
        arguments = capture_arguments(author=["Iain M. Banks"], book=["Banks"])

        with pytest.raises(ValueError, match="capture name 'banks' conflicts"):
            build_capture_groups(arguments)


class TestCommandLineInterface:
    def test_accepts_repeated_book_flags(self, monkeypatch, capsys):
        monkeypatch.setattr(
            sys,
            "argv",
            [
                "generate_captures.py",
                "--book",
                "Surface Detail",
                "--book",
                "The Player of Games",
            ],
        )

        main()

        assert capsys.readouterr().out == (
            '{% capture surface_detail %}{% book_link "Surface Detail" %}{% endcapture %}\n\n'
            '{% capture the_player_of_games %}{% book_link "The Player of Games" %}{% endcapture %}\n'
        )
