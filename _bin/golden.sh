#!/usr/bin/env bash
set -euo pipefail

make_command=$1
: "${BASE:?Use make golden BASE=<ref>}"
case ${STANDARD_SITE:-0} in
    0|1) ;;
    *) echo 'Use STANDARD_SITE=0 or STANDARD_SITE=1.' >&2; exit 2 ;;
esac

root=$(pwd -P)
mkdir -p .jekyll-cache
scratch=$(mktemp -d "$root/.jekyll-cache/golden.XXXXXXXX")
trap 'rm -rf -- "$scratch"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

base="$scratch/base"
mkdir "$base"
git archive --format=tar -- "$BASE" | tar -x -C "$base"
# Git archives give every file the commit time. jekyll-sitemap reads PDF mtimes.
find "$base" -type f -name '*.pdf' -print0 | while IFS= read -r -d '' pdf; do
    working_pdf="$root/${pdf#"$base/"}"
    if [[ -f "$working_pdf" ]]; then touch -r "$working_pdf" "$pdf"; fi
done
build_time=$(date -u '+%Y-%m-%dT%H:%M:%SZ')

render() (
    cd "$1"
    cache=$2
    mkdir -p .jekyll-cache "$cache"
    printf 'time: "%s"\n' "$build_time" > "$cache/golden.yml"
    if [[ ${STANDARD_SITE:-0} == 1 ]]; then
        # Docker needs a mount point in the read-only source. Stage the data so
        # a local publish map survives and Jekyll still reads its configured path.
        if [[ ! -d _data ]]; then
            mkdir _data
            trap 'rmdir _data' EXIT
        fi
        mkdir "$cache/_data"
        cp -R _data/. "$cache/_data/"
        rm -f "$cache/_data/standard_site.json"
        cp "$root/_bin/golden_standard_site.json" "$cache/_data/standard_site.json"
    fi
    "$make_command" --no-print-directory -f Makefile -f "$root/_bin/golden.mk" \
        golden-render "PWD=$PWD" "GOLDEN_CACHE=$cache"
)

render "$base" "$scratch/before"
render "$root" "$scratch/after"
python3 "$root/_bin/golden_diff.py" "$scratch/before/site" "$scratch/after/site"
