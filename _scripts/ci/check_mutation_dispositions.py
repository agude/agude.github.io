#!/usr/bin/env python3
"""Fail a mutmut run on surviving mutants that have no recorded disposition.

Reads `mutmut results --all true` output, the hashes in mutmut's meta file,
and tests/mutation_dispositions.yml. Only the functions listed under
`functions` in the dispositions file are gated. For each one, the check fails
when:

- a mutant survives but is not listed (unlisted);
- a listed mutant no longer survives (stale);
- the function's source hash differs from the recorded one, because mutmut
  numbers mutants by position and a source change can renumber them;
- only some of the function's mutants were run.

A gated function with no mutants run is reported and skipped, so a run
narrowed with MUTANTS= still passes. Survivors in other functions are counted
as untriaged and do not fail the check. Timeouts are printed, not gated.

Exit codes: 0 when the gate passes, 1 when it fails, 2 when an input is
missing or malformed.

Usage:
    mutmut results --all true | python3 ci/check_mutation_dispositions.py \
        --meta mutants/atproto/publish.py.meta \
        --dispositions tests/mutation_dispositions.yml
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from collections import Counter, defaultdict
from dataclasses import dataclass, field
from pathlib import Path

import yaml

EXIT_PASS = 0
EXIT_FAIL = 1
EXIT_UNUSABLE = 2

SURVIVED = "survived"
NOT_CHECKED = "not checked"
TIMEOUT = "timeout"
DISPOSITIONS = ("equivalent", "out_of_scope")

# `    atproto.publish.x_sync_documents__mutmut_4: survived`
RESULT_LINE = re.compile(r"^\s*(?P<name>\S+__mutmut_\d+): (?P<status>.+?)\s*$")
# `atproto.publish.x_sync_documents__mutmut_4` -> `x_sync_documents`
FUNCTION_OF = re.compile(r"^(?:.*\.)?(?P<function>[^.]+)__mutmut_\d+$")


class UnusableInput(Exception):
    """An input file is missing or does not have the expected shape."""


@dataclass
class Report:
    errors: list[str] = field(default_factory=list)
    notes: list[str] = field(default_factory=list)


def parse_results(text: str) -> dict[str, str]:
    """Map each mutant name to its mutmut status."""
    statuses = {}
    for line in text.splitlines():
        match = RESULT_LINE.match(line)
        if match:
            statuses[match["name"]] = match["status"]
    if not statuses:
        raise UnusableInput("no mutant results found; run `mutmut results --all true`")
    return statuses


def function_of(mutant: str) -> str:
    match = FUNCTION_OF.match(mutant)
    if not match:
        raise UnusableInput(f"not a mutmut mutant name: {mutant}")
    return match["function"]


def load_dispositions(path: Path) -> tuple[dict[str, str], dict[str, dict]]:
    """Return (gated function -> recorded hash, mutant -> entry)."""
    try:
        data = yaml.safe_load(path.read_text())
    except (OSError, yaml.YAMLError) as error:
        raise UnusableInput(f"cannot read {path}: {error}") from error
    if not isinstance(data, dict):
        raise UnusableInput(f"{path}: expected a mapping with `functions` and `survivors`")

    functions = data.get("functions") or {}
    if not isinstance(functions, dict):
        raise UnusableInput(f"{path}: `functions` must map function names to hashes")
    entries: dict[str, dict] = {}
    for entry in data.get("survivors") or []:
        mutant = entry.get("mutant") if isinstance(entry, dict) else None
        if not mutant:
            raise UnusableInput(f"{path}: survivor entry without `mutant`: {entry!r}")
        if mutant in entries:
            raise UnusableInput(f"{path}: {mutant} is listed twice")
        if entry.get("disposition") not in DISPOSITIONS:
            raise UnusableInput(f"{path}: {mutant} has disposition {entry.get('disposition')!r}")
        if not str(entry.get("reason") or "").strip():
            raise UnusableInput(f"{path}: {mutant} has no reason")
        if function_of(mutant) not in functions:
            raise UnusableInput(f"{path}: {mutant} belongs to a function not under `functions`")
        entries[mutant] = entry
    return {str(k): str(v) for k, v in functions.items()}, entries


def load_hashes(path: Path) -> dict[str, str]:
    try:
        meta = json.loads(path.read_text())
        return dict(meta["hash_by_function_name"])
    except (OSError, ValueError, KeyError, TypeError) as error:
        raise UnusableInput(f"cannot read function hashes from {path}: {error}") from error


def check(
    statuses: dict[str, str],
    hashes: dict[str, str],
    functions: dict[str, str],
    entries: dict[str, dict],
) -> Report:
    report = Report()
    by_function: dict[str, dict[str, str]] = defaultdict(dict)
    for mutant, status in statuses.items():
        by_function[function_of(mutant)][mutant] = status

    for function, recorded_hash in sorted(functions.items()):
        mutants = by_function.get(function, {})
        if not mutants:
            report.errors.append(f"GATED FUNCTION HAS NO MUTANTS {function}")
            continue
        run = {m: s for m, s in mutants.items() if s != NOT_CHECKED}
        if not run:
            report.notes.append(f"not run, skipped: {function}")
            continue
        if len(run) < len(mutants):
            report.errors.append(
                f"PARTIAL RUN {function}: {len(mutants) - len(run)} of {len(mutants)} "
                "mutants not checked"
            )
        if hashes.get(function) != recorded_hash:
            report.errors.append(
                f"SOURCE CHANGED {function}: hash {hashes.get(function)} != recorded "
                f"{recorded_hash}; re-triage its survivors and update the hash"
            )
        for mutant, status in sorted(run.items(), key=lambda item: _number(item[0])):
            if status == SURVIVED and mutant not in entries:
                report.errors.append(f"UNLISTED SURVIVOR {mutant}")
            elif status == TIMEOUT:
                report.notes.append(f"timed out (not gated): {mutant}")
        for mutant in sorted(entries, key=_number):
            if function_of(mutant) != function:
                continue
            status = mutants.get(mutant)
            if status not in (SURVIVED, NOT_CHECKED):
                report.errors.append(f"STALE DISPOSITION {mutant}: status is {status or 'absent'}")

    untriaged = Counter(
        function_of(m)
        for m, s in statuses.items()
        if s == SURVIVED and function_of(m) not in functions
    )
    if untriaged:
        report.notes.append(
            f"untriaged (not gated): {sum(untriaged.values())} survivors in "
            f"{len(untriaged)} functions; largest: "
            + ", ".join(f"{name} ({count})" for name, count in untriaged.most_common(5))
        )
    return report


def _number(mutant: str) -> int:
    return int(mutant.rsplit("_", 1)[1])


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    parser.add_argument("--results", type=Path, help="mutmut results output (default: stdin)")
    parser.add_argument("--meta", type=Path, required=True, help="mutmut .meta file")
    parser.add_argument("--dispositions", type=Path, required=True, help="dispositions YAML")
    args = parser.parse_args(argv)

    try:
        text = args.results.read_text() if args.results else sys.stdin.read()
        statuses = parse_results(text)
        functions, entries = load_dispositions(args.dispositions)
        hashes = load_hashes(args.meta)
        report = check(statuses, hashes, functions, entries)
    except (OSError, UnusableInput) as error:
        print(f"mutation dispositions: {error}", file=sys.stderr)
        return EXIT_UNUSABLE

    for note in report.notes:
        print(note)
    for error in report.errors:
        print(error)
    gated_survivors = sum(
        1 for m, s in statuses.items() if s == SURVIVED and function_of(m) in functions
    )
    print(
        f"Mutation dispositions: {gated_survivors} gated survivors, {len(entries)} listed, "
        f"{len(report.errors)} errors."
    )
    print("Mutation dispositions: FAILED" if report.errors else "Mutation dispositions: PASSED")
    return EXIT_FAIL if report.errors else EXIT_PASS


if __name__ == "__main__":
    sys.exit(main())
