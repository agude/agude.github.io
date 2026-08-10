#!/usr/bin/env bash
# Validate built HTML structure in _site/:
#   1. _site/ actually contains HTML (an empty build must not pass silently).
#   2. Every .html file starts with <!DOCTYPE (a missing doctype usually
#      means a broken layout chain, an empty file, or corrupted front
#      matter).
#   3. No file starts with a raw front-matter delimiter (--- at the very
#      start means Jekyll shipped unprocessed front matter). --- inside
#      code blocks is legitimate content and is not checked.
#
# The first line is compared explicitly rather than piped through `grep -v`:
# grep reports "no match" for an empty file, which let zero-byte pages pass.
set -euo pipefail

mapfile -d '' -t html_files < <(find _site -name '*.html' -print0)

if [ ${#html_files[@]} -eq 0 ]; then
  echo "ERROR: no HTML files found under _site/ — did the build run?"
  exit 1
fi

echo "Checking ${#html_files[@]} HTML files for structure problems..."

missing_doctype=()
raw_frontmatter=()

for file in "${html_files[@]}"; do
  first_line=$(head -1 "$file")
  if [ "$first_line" = "---" ]; then
    raw_frontmatter+=("$file")
  elif [[ "$first_line" != '<!DOCTYPE'* ]]; then
    missing_doctype+=("$file")
  fi
done

failed=0

if [ ${#missing_doctype[@]} -gt 0 ]; then
  echo "ERROR: The following files are missing <!DOCTYPE html>:"
  printf '%s\n' "${missing_doctype[@]}"
  echo "This usually indicates a broken layout chain or corrupted front matter."
  failed=1
fi

if [ ${#raw_frontmatter[@]} -gt 0 ]; then
  echo "ERROR: Raw front matter delimiters found at start of HTML files:"
  printf '%s\n' "${raw_frontmatter[@]}"
  failed=1
fi

[ "$failed" -eq 0 ] || exit 1

echo "All HTML structure checks passed."
