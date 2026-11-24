#!/bin/bash
#
# Pre-commit hook: runs formatters inside Docker containers.
#   Stage 1: RuboCop on staged Ruby files
#   Stage 2: Prettier on staged Markdown files
#   Stage 3: Ruff on staged Python files
#
# Auto-fixes and re-stages; rejects the commit if uncorrectable issues remain.
#
# Staging isolation: unstaged changes (including untracked files) are moved
# into a stash with `git stash push --keep-index`, so the formatters see only
# the index and partially staged files (git add -p) are not expanded. The
# hook records the stash commit it created and restores from that commit on
# exit, never from a stash position, so a pre-existing stash@{0} is never
# touched:
#   1. Untracked files are extracted from the stash's third parent.
#   2. The unstaged diff (stash index -> stash working tree) is applied on
#      top of the formatted files, when it is not empty. `git stash pop` is
#      not used: it merges the unformatted staged lines back in and conflicts
#      with every fix.
#   3. Only when both succeed is the stash dropped. Otherwise the hook fails,
#      leaves the stash in place, and prints recovery commands naming it.
# If `git stash push` fails, the hook aborts before running any formatter.
#
# Operation state: `git stash push` resets the worktree, which deletes the
# state files of a commit that concludes a merge, cherry-pick, or revert
# (MERGE_HEAD and friends). git commit reads them after this hook, so without
# them the commit fails or loses its second parent. The hook copies them
# before stashing and puts back any that went missing on exit.
# Tests: _scripts/tests/test_pre_commit.py.

# Configuration
RUBY_IMAGE="jekyll-image-agude"
PRETTIER_IMAGE="prettier-image-agude"
MOUNT="/workspace"
# Run containers as the host user so autocorrected files stay owned by the
# user instead of root. HOME=/tmp gives that user a writable home.
DOCKER_USER_OPTS=(--user "$(id -u):$(id -g)" -e HOME=/tmp)

OVERALL_EXIT=0

# The stash commit this hook created; empty when it created none.
HOOK_STASH=""

# State files of an in-progress operation that the commit concludes.
GIT_DIR_PATH=$(git rev-parse --git-dir)
OPERATION_STATE_FILES=(MERGE_HEAD MERGE_MSG MERGE_MODE CHERRY_PICK_HEAD REVERT_HEAD)
# Copies of those files taken before stashing; empty when none existed.
SAVED_STATE_DIR=""

save_operation_state() {
  local name
  for name in "${OPERATION_STATE_FILES[@]}"; do
    [ -f "$GIT_DIR_PATH/$name" ] || continue
    [ -n "$SAVED_STATE_DIR" ] || SAVED_STATE_DIR=$(mktemp -d) || return 1
    cp -p "$GIT_DIR_PATH/$name" "$SAVED_STATE_DIR/$name" || return 1
  done
}

restore_operation_state() {
  [ -n "$SAVED_STATE_DIR" ] || return 0
  local saved status=0
  for saved in "$SAVED_STATE_DIR"/*; do
    [ -e "$GIT_DIR_PATH/${saved##*/}" ] || cp -p "$saved" "$GIT_DIR_PATH/" || status=1
  done
  if [ "$status" -ne 0 ]; then
    echo "❌ Could not restore operation state; copies are in $SAVED_STATE_DIR." >&2
    return 1
  fi
  rm -rf "$SAVED_STATE_DIR"
}

# Prints the stash@{N} name of a stash commit.
stash_ref() {
  local line
  line=$(git stash list --format=%H | grep -n -x "$1" | head -n 1 | cut -d: -f1)
  echo "stash@{$((line - 1))}"
}

restore_unstaged() {
  if git rev-parse -q --verify "$HOOK_STASH^3" >/dev/null; then
    git archive "$HOOK_STASH^3" | tar -x || return 1
  fi
  # A stash holding only untracked files has an empty diff, which `git apply`
  # rejects.
  if ! git diff --quiet "$HOOK_STASH^2" "$HOOK_STASH"; then
    git diff --binary "$HOOK_STASH^2" "$HOOK_STASH" | git apply --whitespace=nowarn || return 1
  fi
  git stash drop -q "$(stash_ref "$HOOK_STASH")"
}

print_recovery() {
  local ref
  ref=$(stash_ref "$HOOK_STASH")
  {
    echo "---"
    echo "❌ Could not restore unstaged changes after formatting."
    echo "   They are saved in stash $HOOK_STASH ($ref)."
    echo "   The index holds the formatted staged content. To put the working tree"
    echo "   back as it was before the commit, untracked files included, run:"
    echo "     git restore --source=$HOOK_STASH --worktree -- ."
    echo "     git rev-parse -q --verify $HOOK_STASH^3 && git archive $HOOK_STASH^3 | tar -x"
    echo "   Then drop the stash with: git stash drop $ref"
  } >&2
}

cleanup() {
  local status=$?
  if [ -n "$HOOK_STASH" ] && ! restore_unstaged; then
    print_recovery
    status=1
  fi
  restore_operation_state || status=1
  exit "$status"
}
trap cleanup EXIT

if ! git diff --quiet || [ -n "$(git ls-files --others --exclude-standard)" ]; then
  if ! save_operation_state; then
    echo "❌ Could not save merge/cherry-pick state; not running formatters." >&2
    exit 1
  fi
  stash_before=$(git rev-parse -q --verify refs/stash)
  if ! git stash push --keep-index --include-untracked -m "pre-commit hook stash" -q; then
    echo "❌ git stash push failed; not running formatters." >&2
    exit 1
  fi
  stash_after=$(git rev-parse -q --verify refs/stash)
  if [ -n "$stash_after" ] && [ "$stash_after" != "$stash_before" ]; then
    HOOK_STASH=$stash_after
  fi
fi

# Re-stages formatted files; a failed `git add` fails the hook.
restage() {
  if ! git add -- "$@"; then
    echo "❌ git add failed for: $*" >&2
    OVERALL_EXIT=1
  fi
}

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
    "${DOCKER_USER_OPTS[@]}" \
    -v "$(pwd):$MOUNT" \
    -w "$MOUNT" \
    "$RUBY_IMAGE" \
    bundle exec rubocop --autocorrect --format simple \
    "${STAGED_RUBY_FILES[@]}"

  RUBOCOP_EXIT=$?

  restage "${STAGED_RUBY_FILES[@]}"

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
    "${DOCKER_USER_OPTS[@]}" \
    -v "$(pwd):$MOUNT" \
    -w "$MOUNT" \
    "$PRETTIER_IMAGE" \
    prettier --write \
    "${STAGED_MD_FILES[@]}"

  PRETTIER_EXIT=$?

  restage "${STAGED_MD_FILES[@]}"

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

  # Ruff lives in the _scripts uv project; --project makes it resolvable from
  # the repo root, and its pyproject.toml supplies the config for every path.
  uv run --project _scripts ruff check --fix "${STAGED_PY_FILES[@]}"
  RUFF_CHECK_EXIT=$?

  uv run --project _scripts ruff format "${STAGED_PY_FILES[@]}"
  RUFF_FORMAT_EXIT=$?

  restage "${STAGED_PY_FILES[@]}"

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
