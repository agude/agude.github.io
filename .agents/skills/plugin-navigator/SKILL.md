---
name: plugin-navigator
description: Navigates between Jekyll plugin source files and their tests, reports file-level test presence, and finds missing or orphaned files. Use when working on Jekyll plugins or tests under `_plugins/` or `_tests/`, locating a corresponding test or plugin, or reviewing test coverage.
---

# Plugin Navigator

Use the scripts in this skill to map plugin source files to tests and to
review whether the two trees stay aligned. Run them from the project root. The
scripts use Git to locate the project root and expect these paths:

- Plugin source: `_plugins/src/`
- Tests: `_tests/src/`

These checks measure the presence of matching test files. They do not run
tests or measure line, branch, or method coverage.

## Find the corresponding file

Use the script that matches the file you have:

```bash
# Find test file(s) for a plugin
.claude/skills/plugin-navigator/scripts/test-for-plugin \
  _plugins/src/infrastructure/url_utils.rb

# Find the plugin file for a test
.claude/skills/plugin-navigator/scripts/plugin-for-test \
  _tests/src/infrastructure/test_url_utils.rb
```

`test-for-plugin` accepts one plugin path under `_plugins/src/`. It prints
matching test paths. It checks both an exact test name and tests with a
suffix:

```text
_plugins/src/<path>/<name>.rb
_tests/src/<path>/test_<name>.rb
_tests/src/<path>/test_<name>_*.rb
```

If no test matches, it prints `MISSING` and exits with status 1.

`plugin-for-test` accepts one test path under `_tests/src/`. It prints the
matching plugin path. It first checks the full name after `test_`, then removes
underscore-separated suffixes from right to left until it finds a plugin. For
example, `test_link_cache_generator_favorites.rb` first checks
`link_cache_generator_favorites.rb`, then can resolve to
`link_cache_generator.rb`. If no plugin matches, it prints `ORPHAN` and exits
with status 1.

Because matching uses the plugin name as a prefix, a suffixed test such as
`test_user_profile.rb` also matches `user.rb`. Keep plugin names and test names
unambiguous when adding files.

## Review coverage and inventory

Run these commands from the project root:

```bash
# Show tested-plugin counts by domain and for the whole repository
.claude/skills/plugin-navigator/scripts/coverage-stats

# List plugins without a matching test
.claude/skills/plugin-navigator/scripts/coverage-stats --list-missing

# Group missing plugins by domain
.claude/skills/plugin-navigator/scripts/coverage-stats \
  --list-missing --by-domain

# List tests that do not resolve to a plugin
.claude/skills/plugin-navigator/scripts/orphan-tests
```

`coverage-stats` scans every Ruby file below `_plugins/src/`. In its default
mode, each domain is reported as `tested/total`; a plugin counts as tested when
at least one matching test file exists. `--list-missing` changes the output to
the missing plugin paths and a total. Adding `--by-domain` groups those paths
under domain headings.

`orphan-tests` scans every Ruby file below `_tests/src/`. It excludes the
cross-cutting test filenames intentionally allowlisted by the script:

- `test_helper.rb`
- `test_render_mode_coverage.rb`
- `test_link_cache_structure.rb`
- `test_architecture.rb`

## Plugin domains

The top-level directories under `_plugins/src/` are:

| Domain | Purpose |
| --- | --- |
| `infrastructure/` | Low-level utilities such as logging, URL and text processing, and the link cache. |
| `content/` | Site-domain logic for books, posts, authors, series, short stories, and markdown output. |
| `seo/` | JSON-LD generators and front-matter validation. |
| `ui/` | Reusable components such as cards, ratings, citations, quotes, and tags. |

The test tree generally mirrors the plugin tree. Root-level tests under
`_tests/src/` are cross-cutting exceptions and may not have a corresponding
plugin file.

## When changing a plugin

1. Run `test-for-plugin` before editing to locate every existing test.
2. Add or update a test in the same relative directory. Use
   `test_<name>.rb` for the primary test or `test_<name>_<purpose>.rb` for a
   focused integration or edge-case suite.
3. Run each affected test through the repository task runner:

   ```bash
   make test TEST=_tests/src/path/to/test_file.rb
   ```

4. Run `coverage-stats --list-missing` and `orphan-tests` when changing file
   layout or adding a new plugin/test pair.

Do not invoke `jekyll`, `bundle`, or Ruby test files directly. Use `make`
commands for repository operations.

## Review test comprehensiveness

For a plugin with matching tests, check:

1. All public methods and other supported entry points.
2. Nil, empty, missing-data, invalid-input, and malformed-input cases where applicable.
3. Error paths and missing dependencies.
4. Boundary cases such as first/last items and single-item versus multi-item collections.
5. Integration with real or representative Jekyll site data.
