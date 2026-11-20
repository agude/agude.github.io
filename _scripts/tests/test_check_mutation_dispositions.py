"""Tests for ci/check_mutation_dispositions.py."""

import json
from pathlib import Path

import pytest
import yaml
from check_mutation_dispositions import (
    EXIT_FAIL,
    EXIT_PASS,
    EXIT_UNUSABLE,
    UnusableInput,
    check,
    load_dispositions,
    main,
    parse_results,
)

SCRIPTS = Path(__file__).resolve().parents[1]
F = "atproto.publish.x_sync"
G = "atproto.publish.x_other"


def entry(mutant: str, disposition: str = "equivalent") -> dict:
    return {"mutant": mutant, "mutation": "m", "disposition": disposition, "reason": "r"}


def run_check(statuses, *, hashes=None, functions=None, listed=()):
    hashes = {"x_sync": "h1", "x_other": "h2"} if hashes is None else hashes
    functions = {"x_sync": "h1"} if functions is None else functions
    return check(statuses, hashes, functions, {m: entry(m) for m in listed})


class TestParseResults:
    def test_reads_indented_name_status_lines(self) -> None:
        text = f"    {F}__mutmut_1: killed\n    {F}__mutmut_2: not checked\nnoise\n"

        assert parse_results(text) == {f"{F}__mutmut_1": "killed", f"{F}__mutmut_2": "not checked"}

    def test_empty_output_is_unusable(self) -> None:
        with pytest.raises(UnusableInput):
            parse_results("")


class TestCheck:
    def test_listed_survivors_pass(self) -> None:
        report = run_check(
            {f"{F}__mutmut_1": "killed", f"{F}__mutmut_2": "survived"}, listed=[f"{F}__mutmut_2"]
        )

        assert report.errors == []

    def test_unlisted_survivor_fails(self) -> None:
        report = run_check({f"{F}__mutmut_1": "survived"})

        assert report.errors == [f"UNLISTED SURVIVOR {F}__mutmut_1"]

    def test_listed_mutant_that_is_now_killed_is_stale(self) -> None:
        report = run_check({f"{F}__mutmut_1": "killed"}, listed=[f"{F}__mutmut_1"])

        assert report.errors == [f"STALE DISPOSITION {F}__mutmut_1: status is killed"]

    def test_listed_mutant_that_no_longer_exists_is_stale(self) -> None:
        report = run_check({f"{F}__mutmut_1": "killed"}, listed=[f"{F}__mutmut_9"])

        assert report.errors == [f"STALE DISPOSITION {F}__mutmut_9: status is absent"]

    def test_changed_source_hash_fails(self) -> None:
        report = run_check({f"{F}__mutmut_1": "killed"}, hashes={"x_sync": "new"})

        assert len(report.errors) == 1
        assert report.errors[0].startswith("SOURCE CHANGED x_sync")

    def test_partly_run_function_fails(self) -> None:
        report = run_check({f"{F}__mutmut_1": "killed", f"{F}__mutmut_2": "not checked"})

        assert report.errors == ["PARTIAL RUN x_sync: 1 of 2 mutants not checked"]

    def test_function_not_run_is_skipped(self) -> None:
        report = run_check({f"{F}__mutmut_1": "not checked", f"{G}__mutmut_1": "killed"})

        assert report.errors == []
        assert "not run, skipped: x_sync" in report.notes

    def test_gated_function_without_mutants_fails(self) -> None:
        report = run_check({f"{G}__mutmut_1": "killed"})

        assert report.errors == ["GATED FUNCTION HAS NO MUTANTS x_sync"]

    def test_survivor_in_an_ungated_function_fails(self) -> None:
        report = run_check({f"{F}__mutmut_1": "killed", f"{G}__mutmut_1": "survived"})

        assert report.errors == [f"UNTRIAGED SURVIVOR {G}__mutmut_1: its function is not gated"]

    def test_killed_mutants_in_an_ungated_function_pass(self) -> None:
        report = run_check({f"{F}__mutmut_1": "killed", f"{G}__mutmut_1": "killed"})

        assert report.errors == []

    def test_timeout_is_noted_not_failed(self) -> None:
        report = run_check({f"{F}__mutmut_1": "timeout"})

        assert report.errors == []
        assert f"timed out (not gated): {F}__mutmut_1" in report.notes


class TestLoadDispositions:
    def write(self, tmp_path: Path, data) -> Path:
        path = tmp_path / "d.yml"
        path.write_text(yaml.safe_dump(data))
        return path

    def test_rejects_unknown_disposition(self, tmp_path: Path) -> None:
        data = {"functions": {"x_sync": "h"}, "survivors": [entry(f"{F}__mutmut_1", "maybe")]}

        with pytest.raises(UnusableInput, match="disposition"):
            load_dispositions(self.write(tmp_path, data))

    def test_rejects_duplicate_entries(self, tmp_path: Path) -> None:
        data = {"functions": {"x_sync": "h"}, "survivors": [entry(f"{F}__mutmut_1")] * 2}

        with pytest.raises(UnusableInput, match="twice"):
            load_dispositions(self.write(tmp_path, data))

    def test_rejects_entry_for_ungated_function(self, tmp_path: Path) -> None:
        data = {"functions": {"x_sync": "h"}, "survivors": [entry(f"{G}__mutmut_1")]}

        with pytest.raises(UnusableInput, match="not under `functions`"):
            load_dispositions(self.write(tmp_path, data))

    def test_rejects_missing_reason(self, tmp_path: Path) -> None:
        bad = entry(f"{F}__mutmut_1") | {"reason": " "}
        data = {"functions": {"x_sync": "h"}, "survivors": [bad]}

        with pytest.raises(UnusableInput, match="no reason"):
            load_dispositions(self.write(tmp_path, data))

    def test_repository_file_loads(self) -> None:
        functions, entries = load_dispositions(SCRIPTS / "tests" / "mutation_dispositions.yml")

        assert "x_sync_documents" in functions
        assert entries


class TestMain:
    def files(self, tmp_path: Path, status: str) -> list[str]:
        results = tmp_path / "results.txt"
        results.write_text(f"    {F}__mutmut_1: {status}\n")
        meta = tmp_path / "publish.py.meta"
        meta.write_text(json.dumps({"hash_by_function_name": {"x_sync": "h"}}))
        dispositions = tmp_path / "d.yml"
        dispositions.write_text(yaml.safe_dump({"functions": {"x_sync": "h"}, "survivors": []}))
        return ["--results", str(results), "--meta", str(meta), "--dispositions", str(dispositions)]

    def test_passes(self, tmp_path: Path, capsys) -> None:
        assert main(self.files(tmp_path, "killed")) == EXIT_PASS
        assert "PASSED" in capsys.readouterr().out

    def test_fails_on_unlisted_survivor(self, tmp_path: Path, capsys) -> None:
        assert main(self.files(tmp_path, "survived")) == EXIT_FAIL
        assert f"UNLISTED SURVIVOR {F}__mutmut_1" in capsys.readouterr().out

    def test_missing_meta_is_unusable(self, tmp_path: Path) -> None:
        args = self.files(tmp_path, "killed")
        args[args.index("--meta") + 1] = str(tmp_path / "absent.meta")

        assert main(args) == EXIT_UNUSABLE
