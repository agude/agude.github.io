#!/bin/bash
#
# Pre-commit hook: runs formatters inside Docker containers.
#   Stage 1: RuboCop on staged Ruby files
#   Stage 2: Prettier on staged Markdown files
#   Stage 3: Ruff on staged Python files
#
# Auto-fixes and re-stages; rejects the commit if uncorrectable issues remain.
# Uses git stash --keep-index to isolate staged content so partially staged
# files (git add -p) are not silently expanded.

# Configuration
RUBY_IMAGE="jekyll-image-agude"
PRETTIER_IMAGE="prettier-image-agude"
MOUNT="/workspace"

OVERALL_EXIT=0

# Stash unstaged changes (including untracked) so formatters only see the
# index. The stash is popped in the trap regardless of how the hook exits.
has_stash=false
if ! git diff --quiet || [ -n "$(git ls-files --others --exclude-standard)" ]; then
  git stash push --keep-index --include-untracked -m "pre-commit hook stash" -q
  has_stash=true
fi

cleanup() {
  if [ "$has_stash" = true ]; then
    if ! git stash pop -q 2>/dev/null; then
      echo "WARNING: Could not restore unstaged changes. Run 'git stash list' to recover." >&2
    fi
  fi
}
trap cleanup EXIT

# ===========================================================================
# Stage 1: RuboCop on staged Ruby files
# ===========================================================================

mapfile -t STAGED_RUBY_FILES < <(git diff --cached --name-only --diff-filter=ACM | grep '\.rb$' || true)

if [ ${#STAGED_RUBY_FILES[@]} -gt 0 ]; then
  echo "---"
  echo "Running RuboCop (Strict Mode) on staged Ruby files..."
  printf '%s\n' "${STAGED_RUBY_FILES[@]}"
  echo "---"

  docker run --rm \
    -v "$(pwd):$MOUNT" \
    -w "$MOUNT" \
    "$RUBY_IMAGE" \
    bundle exec rubocop --autocorrect --format simple \
    "${STAGED_RUBY_FILES[@]}"

  RUBOCOP_EXIT=$?

  git add -- "${STAGED_RUBY_FILES[@]}"

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
mapfile -t STAGED_MD_FILES < <(git diff --cached --name-only --diff-filter=ACM \
  | grep '\.md$' \
  | grep -v -E '^(AGENTS|CLAUDE|GEMINI|README|LICENSE)\.md$' \
  | grep -v -E '^\.' \
  || true)

if [ ${#STAGED_MD_FILES[@]} -gt 0 ]; then
  echo "---"
  echo "Running Prettier on staged Markdown files..."
  printf '%s\n' "${STAGED_MD_FILES[@]}"
  echo "---"

  docker run --rm \
    -v "$(pwd):$MOUNT" \
    -w "$MOUNT" \
    "$PRETTIER_IMAGE" \
    prettier --write \
    "${STAGED_MD_FILES[@]}"

  PRETTIER_EXIT=$?

  git add -- "${STAGED_MD_FILES[@]}"

  if [ $PRETTIER_EXIT -ne 0 ]; then
    echo "---"
    echo "❌ Prettier found errors in Markdown files."
    echo "   Please fix the errors above and try again."
    OVERALL_EXIT=1
  else
    echo "✅ Prettier passed."
  fi
fi

# ===========================================================================
# Stage 3: Ruff on staged Python files
# ===========================================================================

mapfile -t STAGED_PY_FILES < <(git diff --cached --name-only --diff-filter=ACM | grep '\.py$' || true)

if [ ${#STAGED_PY_FILES[@]} -gt 0 ]; then
  echo "---"
  echo "Running Ruff on staged Python files..."
  printf '%s\n' "${STAGED_PY_FILES[@]}"
  echo "---"

  ruff check --fix "${STAGED_PY_FILES[@]}"
  RUFF_CHECK_EXIT=$?

  ruff format "${STAGED_PY_FILES[@]}"
  RUFF_FORMAT_EXIT=$?

  git add -- "${STAGED_PY_FILES[@]}"

  if [ $RUFF_CHECK_EXIT -ne 0 ] || [ $RUFF_FORMAT_EXIT -ne 0 ]; then
    echo "---"
    echo "❌ Ruff found uncorrectable issues in Python files."
    echo "   Please fix the errors above and try again."
    OVERALL_EXIT=1
  else
    echo "✅ Ruff passed."
  fi
fi

exit $OVERALL_EXIT
