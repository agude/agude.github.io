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

    # Determine context (Plugin vs Test) for better instructions
    context_instruction=""
    if [[ "$current_file" == *"_tests"* ]]; then
        context_instruction="CONTEXT: This is a Minitest file. Documentation should briefly explain what is being tested. Do not over-engineer refactoring in tests; prefer readability."
    else
        context_instruction="CONTEXT: This is a Jekyll Plugin (Production Code). Documentation must be clear, explaining the purpose of the Tag/Generator and how it is used in Liquid."
    fi

    # WRITE THE PROMPT
    cat <<EOF > "$prompt_file"
You are a Senior Ruby Engineer specializing in Jekyll. I need you to fix RuboCop static analysis errors in the following file.

FILE: $current_file
$context_instruction

THE ERRORS TO FIX:
$error_buffer

--------------------------------------------------
STYLE GUIDE & INSTRUCTIONS:

1. **Documentation (Style/Documentation):**
   - **Requirement:** Every Class and Module must have a top-level comment block.
   - **Format:**
     \`\`\`ruby
     # Short summary of what this class does.
     #
     # (Optional) Detailed explanation or Liquid usage example:
     # {% my_tag param="value" %}
     class MyClass ...
     \`\`\`
   - **Quality:** Do not write "Class for X". Write "Generates X based on Y configuration."

2. **Frozen String Literals:**
   - Ensure \`# frozen_string_literal: true\` is the **very first line** of the file.

3. **Naming & Variables:**
   - Fix short variable names (e.g., change \`l\` to \`logger\`, \`p\` to \`path\`).
   - Use snake_case for variables and methods.

4. **Refactoring Strategy (Only if Metrics/* errors exist):**
   - **If** the error is \`Metrics/MethodLength\` or \`Complexity\`:
     - Extract logic into private helper methods (e.g., \`def _helper_method\`).
     - Or, extract a private helper class if state management is complex.
   - **If** there are NO metrics errors, **DO NOT** refactor the logic structure. Just fix the style/docs.

5. **Safety:**
   - **CRITICAL:** Do not change the external behavior or API of the code.
   - Do not remove existing comments unless they are the specific "rubocop:disable" comments causing issues.

--------------------------------------------------
SOURCE CODE:
\`\`\`ruby
$source_code
\`\`\`

**OUTPUT:**
Return ONLY the full, valid Ruby code for the file. No markdown wrappers, no conversational filler.
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
echo "Process these files one by one."
