#!/bin/bash
#
# Custom pre-commit hook to run RuboCop inside a Docker container.
# STRICT MODE: Fails the commit if RuboCop finds any uncorrectable issues.

# Configuration
IMAGE="jekyll-image-agude"
MOUNT="/workspace"

# 1. Get list of staged Ruby files
# --diff-filter=ACM: Only check Added, Copied, Modified files
STAGED_RUBY_FILES=$(git diff --cached --name-only --diff-filter=ACM | grep '\.rb$')

if [ -z "$STAGED_RUBY_FILES" ]; then
  exit 0
fi

echo "---"
echo "Running RuboCop (Strict Mode) on staged Ruby files..."
echo "$STAGED_RUBY_FILES" | tr ' ' '\n'
echo "---"

# 2. Run RuboCop inside Docker
# We use --format simple so you can read the errors easily.
echo "$STAGED_RUBY_FILES" | xargs docker run --rm \
  -v "$(pwd):$MOUNT" \
  -w "$MOUNT" \
  "$IMAGE" \
  bundle exec rubocop --autocorrect --format simple "$@"

RUBYCOP_EXIT_CODE=$?

# 3. Re-stage any files that RuboCop auto-corrected
# This ensures the fixes are included in the commit.
echo "$STAGED_RUBY_FILES" | xargs git add

# 4. Check exit code
# 0   = Success
# 1   = Offenses remaining
# 123 = Offenses corrected, but some remaining
if [ $RUBYCOP_EXIT_CODE -ne 0 ]; then
  echo "---"
  echo "❌ Commit rejected: RuboCop found uncorrectable offenses."
  echo "   Please fix the errors above and try again."
  exit 1
fi

echo "✅ RuboCop passed."
exit 0
