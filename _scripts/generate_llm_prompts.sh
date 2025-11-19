#!/bin/bash

# 1. Setup
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT" || exit 1

IMAGE="jekyll-image-agude"
MOUNT="/workspace"
PROMPT_DIR="_prompts"

# Create a clean directory for the prompts
rm -rf "$PROMPT_DIR"
mkdir -p "$PROMPT_DIR"

echo "📂 Generating LLM prompts in $PROMPT_DIR/..."

# 2. Get the JSON report of all offenses
# We use a ruby one-liner to parse the JSON and output: "FILE_PATH|ERROR_SUMMARY"
# This avoids complex bash JSON parsing.
docker run --rm -v "$PWD":$MOUNT -w $MOUNT $IMAGE \
  bundle exec rubocop --format json | \
  docker run --rm -i -v "$PWD":$MOUNT -w $MOUNT $IMAGE \
  ruby -rjson -e '
    input = $stdin.read
    data = JSON.parse(input)
    data["files"].each do |f|
      next if f["offenses"].empty?

      # Group offenses by line number for readability
      errors = f["offenses"].map { |o| "- Line #{o["location"]["line"]}: [#{o["cop_name"]}] #{o["message"]}" }.join("\n")

      # Output a delimiter we can split on in bash
      puts "START_FILE|#{f["path"]}"
      puts errors
      puts "END_ERRORS"
    end
  ' > "$PROMPT_DIR/all_errors.txt"

# 3. Process the output and create individual text files
current_file=""
collecting_errors=0
error_buffer=""

while IFS= read -r line; do
  if [[ "$line" == "START_FILE|"* ]]; then
    # Extract filename
    current_file="${line#START_FILE|}"
    collecting_errors=1
    error_buffer=""
  elif [[ "$line" == "END_ERRORS" ]]; then
    # We have the file and the errors, now generate the prompt
    collecting_errors=0

    # Create a safe filename for the prompt (replace / with _)
    safe_name=$(echo "$current_file" | tr '/' '_')
    prompt_file="$PROMPT_DIR/${safe_name}.txt"

    # Read the actual source code
    source_code=$(cat "$current_file")

    # WRITE THE PROMPT
    cat <<EOF > "$prompt_file"
I need you to refactor the following Ruby file to fix RuboCop static analysis errors.

FILE: $current_file

THE ERRORS TO FIX:
$error_buffer

INSTRUCTIONS:
1. Fix the specific errors listed above.
2. If the error is "Metrics/MethodLength" or "Metrics/AbcSize", please extract logic into private helper methods.
3. If the error is "Style/FrozenStringLiteralComment", add the comment to the top of the file.
4. DO NOT change the external behavior of the code.
5. DO NOT remove comments unless they are the specific "rubocop:disable" comments causing issues.
6. Return the FULL content of the fixed file.

SOURCE CODE:
\`\`\`ruby
$source_code
\`\`\`
EOF

    echo "  📝 Generated: $prompt_file"
  elif [[ $collecting_errors -eq 1 ]]; then
    error_buffer+="$line"$'\n'
  fi
done < "$PROMPT_DIR/all_errors.txt"

# Cleanup intermediate file
rm "$PROMPT_DIR/all_errors.txt"

echo "--------------------------------------------------"
echo "✅ Done! Open the '$PROMPT_DIR' folder."
echo "Copy the content of a text file, paste it into your LLM, and copy the code back."
