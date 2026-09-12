"""Tests for the parse-book-notes capture generators."""

from __future__ import annotations

import importlib.util
import sys
from pathlib import Path
from types import ModuleType

import pytest

SCRIPTS_DIR = Path(__file__).parents[1] / "scripts"


def load_module(module_name: str, filename: str) -> ModuleType:
    """Load a skill script under the name its local imports expect."""
    module_path = SCRIPTS_DIR / filename
    module_spec = importlib.util.spec_from_file_location(module_name, module_path)
    if module_spec is None or module_spec.loader is None:
        raise RuntimeError(f"Cannot load {module_name} from {module_path}")
    module = importlib.util.module_from_spec(module_spec)
    sys.modules[module_name] = module
    module_spec.loader.exec_module(module)
    return module


capture_generation = load_module("capture_generation", "capture_generation.py")
reference_group_generator = load_module(
    "generate_reference_group",
    "generate_reference_group.py",
)
standalone_reference_generator = load_module(
    "generate_standalone_reference",
    "generate_standalone_reference.py",
)
media_reference_generator = load_module(
    "generate_media_reference",
    "generate_media_reference.py",
)


class TestCaptureGeneration:
    def test_builds_contiguous_author_series_and_book_group(self):
        captures = capture_generation.build_reference_group(
            raw_authors=["Iain M. Banks"],
            raw_author_pairs=[],
            raw_books=["Surface Detail", "The Player of Games"],
            raw_series=["Culture"],
        )

        assert capture_generation.render_captures(captures) == (
            '{% capture banks %}{% author_link "Iain M. Banks" %}{% endcapture %}\n'
            '{% capture bankss %}{% author_link "Iain M. Banks" possessive %}{% endcapture %}\n'
            '{% capture banks_lastname %}{% author_link "Iain M. Banks" link_text="Banks" %}{% endcapture %}\n'
            '{% capture bankss_lastname %}{% author_link "Iain M. Banks" link_text="Banks" possessive %}{% endcapture %}\n'
            '{% capture culture %}{% series_link "Culture" %}{% endcapture %}\n'
            '{% capture surface_detail %}{% book_link "Surface Detail" %}{% endcapture %}\n'
            '{% capture the_player_of_games %}{% book_link "The Player of Games" %}{% endcapture %}'
        )

    def test_deduplicates_repeated_books(self):
        captures = capture_generation.build_reference_group(
            raw_authors=["Iain M. Banks"],
            raw_author_pairs=[],
            raw_books=["Matter", "Matter"],
            raw_series=[],
        )

        assert [capture.name for capture in captures].count("matter") == 1

    def test_generates_custom_author_pair(self):
        captures = capture_generation.build_reference_group(
            raw_authors=[
                "Arkady Strugatsky=arkady_strugatsky",
                "Boris Strugatsky=boris_strugatsky",
            ],
            raw_author_pairs=["Arkady Strugatsky|Boris Strugatsky=arkady_and_boris"],
            raw_books=["Roadside Picnic"],
            raw_series=[],
        )

        rendered = capture_generation.render_captures(captures)
        assert (
            '{% capture arkady_and_boris %}{% author_link "Arkady Strugatsky" %} and '
            '{% author_link "Boris Strugatsky" %}{% endcapture %}' in rendered
        )
        assert (
            '{% capture arkady_and_boriss %}{% author_link "Arkady Strugatsky" %} and '
            '{% author_link "Boris Strugatsky" possessive %}{% endcapture %}'
            in rendered
        )

    def test_rejects_capture_name_collisions(self):
        with pytest.raises(ValueError, match="capture name 'banks' conflicts"):
            capture_generation.build_reference_group(
                raw_authors=["Iain M. Banks"],
                raw_author_pairs=[],
                raw_books=["Banks"],
                raw_series=[],
            )


class TestReferenceGroupCommand:
    def test_prints_one_complete_group_without_warnings(self, capsys):
        reference_group_generator.main(
            [
                "--author",
                "Vernor Vinge",
                "--book",
                "A Fire Upon The Deep=fire_deep",
            ]
        )

        captured = capsys.readouterr()
        assert captured.err == ""
        assert (
            '{% capture vinges_lastname %}{% author_link "Vernor Vinge" '
            'link_text="Vinge" possessive %}{% endcapture %}\n'
            '{% capture fire_deep %}{% book_link "A Fire Upon The Deep" %}{% endcapture %}\n'
            in captured.out
        )

    def test_rejects_book_without_author(self, capsys):
        with pytest.raises(SystemExit, match="2"):
            reference_group_generator.main(["--book", "Matter"])

        assert "requires at least one --author" in capsys.readouterr().err

    def test_rejects_author_without_work(self, capsys):
        with pytest.raises(SystemExit, match="2"):
            reference_group_generator.main(["--author", "Iain M. Banks"])

        assert "requires at least one --book or --series" in capsys.readouterr().err

    def test_rejects_two_authors_without_pair(self, capsys):
        with pytest.raises(SystemExit, match="2"):
            reference_group_generator.main(
                [
                    "--author",
                    "Arkady Strugatsky=arkady_strugatsky",
                    "--author",
                    "Boris Strugatsky=boris_strugatsky",
                    "--book",
                    "Roadside Picnic",
                ]
            )

        assert "requires exactly one --author-pair" in capsys.readouterr().err

    def test_rejects_pair_without_individual_bundle(self, capsys):
        with pytest.raises(SystemExit, match="2"):
            reference_group_generator.main(
                [
                    "--author",
                    "Arkady Strugatsky=arkady_strugatsky",
                    "--author-pair",
                    "Arkady Strugatsky|Boris Strugatsky=arkady_and_boris",
                    "--book",
                    "Roadside Picnic",
                ]
            )

        assert (
            "individual --author bundles for Boris Strugatsky"
            in capsys.readouterr().err
        )

    def test_accepts_three_authors_without_pair(self, capsys):
        reference_group_generator.main(
            [
                "--author",
                "Linda Evans=author_evans",
                "--author",
                "Robert R. Chase=author_chase",
                "--author",
                "David Weber=author_weber",
                "--book",
                "The Triumphant",
            ]
        )

        assert capsys.readouterr().err == ""

    def test_rejects_removed_group_flag(self, capsys):
        with pytest.raises(SystemExit, match="2"):
            reference_group_generator.main(
                ["--group", "--author", "Iain M. Banks", "--book", "Matter"]
            )

        assert "unrecognized arguments: --group" in capsys.readouterr().err


class TestStandaloneReferenceCommand:
    def test_book_mode_warns_and_prints_one_capture(self, capsys):
        standalone_reference_generator.main(["--book", "Network Effect=mb5"])

        captured = capsys.readouterr()
        assert (
            captured.out
            == '{% capture mb5 %}{% book_link "Network Effect" %}{% endcapture %}\n'
        )
        assert "standalone reference mode is exceptional" in captured.err
        assert "You are probably doing this wrong" in captured.err
        assert "cannot preserve an author/work relationship" in captured.err
        assert "generate_reference_group.py" in captured.err
        assert "verify this exception against the planned sentence" in captured.err

    def test_author_mode_prints_complete_bundle(self, capsys):
        standalone_reference_generator.main(["--author", "Vernor Vinge"])

        captured = capsys.readouterr()
        assert captured.out.count("{% capture") == 4
        assert "prose intentionally names only this author" in captured.err

    def test_rejects_multiple_reference_types(self, capsys):
        with pytest.raises(SystemExit, match="2"):
            standalone_reference_generator.main(
                ["--author", "Vernor Vinge", "--book", "A Fire Upon The Deep"]
            )

        assert "not allowed with argument" in capsys.readouterr().err


class TestMediaReferenceCommand:
    def test_prints_mixed_media_without_warnings(self, capsys):
        media_reference_generator.main(
            [
                "--movie",
                "Alien",
                "--game",
                "Control",
                "--tv-show",
                "The Expanse=expanse",
            ]
        )

        captured = capsys.readouterr()
        assert captured.err == ""
        assert captured.out == (
            '{% capture alien %}{% movie_title "Alien" %}{% endcapture %}\n'
            '{% capture control %}{% game_title "Control" %}{% endcapture %}\n'
            '{% capture expanse %}{% tv_show_title "The Expanse" %}{% endcapture %}\n'
        )

    def test_requires_at_least_one_media_reference(self, capsys):
        with pytest.raises(SystemExit, match="2"):
            media_reference_generator.main([])

        assert (
            "provide at least one --movie, --game, or --tv-show"
            in capsys.readouterr().err
        )
