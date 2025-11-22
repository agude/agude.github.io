#!/bin/bash
#
# Custom pre-commit hook to run RuboCop inside a Docker container.
# This allows running Ruby tools without installing Ruby on the host machine.
#
# This version is configured for "auto-format only" and ignores linting failures.

# Configuration
IMAGE="jekyll-image-agude"
MOUNT="/workspace"

# 1. Get list of staged Ruby files
# --diff-filter=ACM: Only check Added, Copied, Modified files
STAGED_RUBY_FILES=$(git diff --cached --name-only --diff-filter=ACM | grep '\.rb$')

if [ -z "$STAGED_RUBY_FILES" ]; then
  # No staged Ruby files, exit successfully
  exit 0
fi

echo "---"
echo "Running RuboCop --autocorrect on staged Ruby files inside Docker (Safe Auto-format only)..."
echo "$STAGED_RUBY_FILES" | tr ' ' '\n'
echo "---"

# 2. Run RuboCop inside Docker
# The output is redirected to /dev/null to suppress linting reports.
echo "$STAGED_RUBY_FILES" | xargs docker run --rm \
  -v "$(pwd):$MOUNT" \
  -w "$MOUNT" \
  "$IMAGE" \
  bundle exec rubocop --autocorrect --format quiet "$@" > /dev/null 2>&1

# Capture the exit code of the docker run command (which is the exit code of rubocop)
RUBYCOP_EXIT_CODE=$?

# 3. Check for critical failure (e.g., Docker/Shell error)
# RuboCop returns 0 (success), 1 (uncorrectable offenses remain), or 123 (corrections made + uncorrectable offenses remain).
# We treat 0, 1, and 123 as non-critical style/linting issues and allow the commit to proceed.
if [ $RUBYCOP_EXIT_CODE -ne 0 ] && [ $RUBYCOP_EXIT_CODE -ne 1 ] && [ $RUBYCOP_EXIT_CODE -ne 123 ]; then
  echo "Error: Critical execution failure (Exit Code: $RUBYCOP_EXIT_CODE)."
  echo "Check if 'docker' is installed, the Docker daemon is running, and the image '$IMAGE' exists."
  exit $RUBYCOP_EXIT_CODE
fi

# 4. Re-stage any files that RuboCop auto-corrected
# We need to re-add the modified files to the staging area.
echo "Re-staging auto-corrected files..."
echo "$STAGED_RUBY_FILES" | xargs git add

echo "RuboCop finished. Auto-corrected changes have been re-staged. Commit proceeding."
exit 0
