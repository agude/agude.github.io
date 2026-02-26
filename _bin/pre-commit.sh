#!/bin/bash
#
# Pre-commit hook: runs formatters inside Docker containers.
#   Stage 1: RuboCop on staged Ruby files
#   Stage 2: Prettier on staged Markdown files
#
# Auto-fixes and re-stages; rejects the commit if uncorrectable issues remain.

# Configuration
RUBY_IMAGE="jekyll-image-agude"
PRETTIER_IMAGE="prettier-image-agude"
MOUNT="/workspace"

OVERALL_EXIT=0

# ===========================================================================
# Stage 1: RuboCop on staged Ruby files
# ===========================================================================

STAGED_RUBY_FILES=$(git diff --cached --name-only --diff-filter=ACM | grep '\.rb$' || true)

if [ -n "$STAGED_RUBY_FILES" ]; then
  echo "---"
  echo "Running RuboCop (Strict Mode) on staged Ruby files..."
  echo "$STAGED_RUBY_FILES" | tr ' ' '\n'
  echo "---"

  echo "$STAGED_RUBY_FILES" | xargs docker run --rm \
    -v "$(pwd):$MOUNT" \
    -w "$MOUNT" \
    "$RUBY_IMAGE" \
    bundle exec rubocop --autocorrect --format simple "$@"

  RUBOCOP_EXIT=$?

  echo "$STAGED_RUBY_FILES" | xargs git add

  if [ $RUBOCOP_EXIT -ne 0 ]; then
    echo "---"
    echo "❌ RuboCop found uncorrectable offenses."
    echo "   Please fix the errors above and try again."
    OVERALL_EXIT=1
  else
    echo "✅ RuboCop passed."
  fi
fi

# ===========================================================================
# Stage 2: Prettier on staged Markdown files
# ===========================================================================

# Get staged .md files, excluding meta files via grep -v.
STAGED_MD_FILES=$(git diff --cached --name-only --diff-filter=ACM \
  | grep '\.md$' \
  | grep -v -E '^(AGENTS|CLAUDE|GEMINI|README|LICENSE)\.md$' \
  | grep -v -E '^\.' \
  || true)

if [ -n "$STAGED_MD_FILES" ]; then
  echo "---"
  echo "Running Prettier on staged Markdown files..."
  echo "$STAGED_MD_FILES" | tr ' ' '\n'
  echo "---"

  echo "$STAGED_MD_FILES" | xargs docker run --rm \
    -v "$(pwd):$MOUNT" \
    -w "$MOUNT" \
    "$PRETTIER_IMAGE" \
    prettier --write

  PRETTIER_EXIT=$?

  echo "$STAGED_MD_FILES" | xargs git add

  if [ $PRETTIER_EXIT -ne 0 ]; then
    echo "---"
    echo "❌ Prettier found errors in Markdown files."
    echo "   Please fix the errors above and try again."
    OVERALL_EXIT=1
  else
    echo "✅ Prettier passed."
  fi
fi

exit $OVERALL_EXIT
