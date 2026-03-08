#!/bin/bash

# 1. Navigate to the repository root
# This ensures the script works no matter where you call it from
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT" || exit 1

echo "📂 Working in: $REPO_ROOT"

# Configuration matches your Makefile
IMAGE="jekyll-image-agude"
MOUNT="/workspace"

# Ensure the image is built and up to date
echo "Building/Verifying Docker image..."
make image > /dev/null

# 2. Check for clean git state (Ignoring untracked files)
# -uno tells git status to ignore untracked files (like this script)
if [[ -n $(git status -s -uno) ]]; then
  echo "❌ Error: Your git working directory has modified tracked files."
  echo "Please commit or stash your changes before running this script."
  git status -s -uno
  exit 1
fi

echo "🔍 Analyzing RuboCop offenses (this may take a moment)..."

# 3. Get a list of all unique cop names currently failing.
COPS=$(docker run --rm -v "$PWD":$MOUNT -w $MOUNT $IMAGE \
  bundle exec rubocop --format json | \
  docker run --rm -i -v "$PWD":$MOUNT -w $MOUNT $IMAGE \
  ruby -rjson -e 'input = $stdin.read; begin; puts JSON.parse(input)["files"].flat_map { |f| f["offenses"] }.map { |o| o["cop_name"] }.uniq.sort; rescue; exit 0; end')

if [ -z "$COPS" ]; then
  echo "🎉 No offenses found! You are already green."
  exit 0
fi

echo "Found offending cops:"
echo "$COPS"
echo "--------------------------------------------------"

for cop in $COPS; do
  echo "🤖 Processing: $cop"

  # Apply unsafe auto-correct ONLY for this specific cop
  docker run --rm -v "$PWD":$MOUNT -w $MOUNT $IMAGE \
    bundle exec rubocop -A --only "$cop" > /dev/null 2>&1

  # Check if git detected a change
  if git diff --quiet; then
    echo "   ⏭️  No auto-correctable offenses found for $cop."
    continue
  fi

  echo "   🧪 Running tests (make test)..."

  if make test > test_output.log 2>&1; then
    echo "   ✅ Tests PASSED. Committing fix."

    # 4. Only add updated files (git add -u)
    # This prevents accidentally committing untracked files (like this script)
    git add -u
    git commit -m "Auto-fix $cop"
    rm test_output.log
  else
    echo "   ❌ Tests FAILED. Reverting changes."
    # Optional: Print the last few lines of the failure
    # tail -n 5 test_output.log
    git checkout .
    rm test_output.log
  fi
done

echo "--------------------------------------------------"
echo "🏁 Process complete."
