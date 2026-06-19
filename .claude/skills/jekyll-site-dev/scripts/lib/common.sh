#!/usr/bin/env bash
# Shared functions for plugin-navigator scripts

export PROJECT_ROOT="${PROJECT_ROOT:-$(git rev-parse --show-toplevel)}"
export PLUGINS_DIR="_plugins/src"
export TESTS_DIR="_tests/src"

# Get test pattern(s) for a plugin.
# Uses precise matching: test_foo.rb OR test_foo_*.rb (not test_foobar.rb)
# Input: _plugins/src/subdir/foo.rb
# Output: Two patterns on separate lines
get_test_patterns_for_plugin() {
    local plugin_path="$1"
    local relative="${plugin_path#$PLUGINS_DIR/}"
    local dir
    dir="$(dirname "$relative")"
    local name
    name="$(basename "$relative" .rb)"

    # Exact match: test_foo.rb
    echo "$TESTS_DIR/$dir/test_${name}.rb"
    # Suffixed match: test_foo_*.rb (for test_foo_integration.rb, etc.)
    echo "$TESTS_DIR/$dir/test_${name}_*.rb"
}

# Check if any test exists for a plugin
# Returns 0 if found, 1 if not
plugin_has_test() {
    local plugin_path="$1"
    local pattern

    while IFS= read -r pattern; do
        if compgen -G "$PROJECT_ROOT/$pattern" > /dev/null 2>&1; then
            return 0
        fi
    done < <(get_test_patterns_for_plugin "$plugin_path")

    return 1
}

# Find all tests for a plugin
# Input: _plugins/src/subdir/foo.rb
# Output: List of matching test paths (relative to project root)
find_tests_for_plugin() {
    local plugin_path="$1"
    local pattern
    local found=false

    while IFS= read -r pattern; do
        for f in $PROJECT_ROOT/$pattern; do
            if [[ -f "$f" ]]; then
                echo "${f#$PROJECT_ROOT/}"
                found=true
            fi
        done
    done < <(get_test_patterns_for_plugin "$plugin_path")

    $found
}

# Find plugin for a test file
# Input: _tests/src/subdir/test_foo_bar.rb
# Output: _plugins/src/subdir/foo.rb (or returns 1 if not found)
find_plugin_for_test() {
    local test_path="$1"
    local relative="${test_path#$TESTS_DIR/}"
    local dir
    dir="$(dirname "$relative")"
    local basename
    basename="$(basename "$relative" .rb)"

    # Must start with test_
    [[ "$basename" =~ ^test_ ]] || return 1

    local core_name="${basename#test_}"

    # Strategy 1: Exact match
    local candidate="$PROJECT_ROOT/$PLUGINS_DIR/$dir/${core_name}.rb"
    if [[ -f "$candidate" ]]; then
        echo "$PLUGINS_DIR/$dir/${core_name}.rb"
        return 0
    fi

    # Strategy 2: Suffix stripping (greedy, right to left)
    # test_link_cache_generator_favorites -> link_cache_generator
    IFS='_' read -ra parts <<< "$core_name"
    for ((i=${#parts[@]}-1; i>=1; i--)); do
        local sub_name
        sub_name=$(IFS='_'; echo "${parts[*]:0:i}")
        candidate="$PROJECT_ROOT/$PLUGINS_DIR/$dir/${sub_name}.rb"
        if [[ -f "$candidate" ]]; then
            echo "$PLUGINS_DIR/$dir/${sub_name}.rb"
            return 0
        fi
    done

    return 1
}

