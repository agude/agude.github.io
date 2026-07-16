#!/usr/bin/env bash
# Validate built HTML structure in _site/:
#   1. Every .html file starts with <!DOCTYPE (a missing doctype usually
#      means a broken layout chain or corrupted front matter).
#   2. No file starts with a raw front-matter delimiter (--- at the very
#      start means Jekyll shipped unprocessed front matter). --- inside
#      code blocks is legitimate content and is not checked.
set -euo pipefail

echo "Checking for missing DOCTYPE declarations..."
missing_doctype=$(find _site -name '*.html' -exec sh -c 'head -1 "$1" | grep -qv "^<!DOCTYPE" && echo "$1"' _ {} \;)
if [ -n "$missing_doctype" ]; then
  echo "ERROR: The following files are missing <!DOCTYPE html>:"
  echo "$missing_doctype"
  echo "This usually indicates a broken layout chain or corrupted front matter."
  exit 1
fi

echo "Checking for raw front matter in output..."
raw_frontmatter=$(find _site -name '*.html' -exec sh -c 'head -1 "$1" | grep -q "^---$" && echo "$1"' _ {} \;)
if [ -n "$raw_frontmatter" ]; then
  echo "ERROR: Raw front matter delimiters found at start of HTML files:"
  echo "$raw_frontmatter"
  exit 1
fi
echo "All HTML structure checks passed."
