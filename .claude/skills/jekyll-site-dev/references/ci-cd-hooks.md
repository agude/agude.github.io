# CI/CD & Hooks

**GitHub Actions** (`.github/workflows/jekyll.yml`) runs on every push:

1. `bundle exec rubocop` (lint).
2. `bundle exec ruby ... load test_*.rb` (Ruby tests).
3. `setup-python` + `uv run pytest` (Python script tests in `_scripts/`).
4. `bundle exec ruby _bin/check_strict.rb` (strict Liquid variables).
5. Build, HTML validation, feed XML validation, broken-link check (main branch deploys).

Test runs use per-ref concurrency (`test-$ref`, cancel-in-progress); the
deploy lock (`group: pages`) is scoped to the deploy job only.

**Pre-commit hook** (`_bin/pre-commit.sh`, install via `make hooks-install`):

- Stage 1: `rubocop --autocorrect` inside Docker on staged `.rb` files.
- Stage 2: `prettier --write` inside Docker on staged `.md` files (excluding meta files).
- Stage 3: `ruff check --fix` + `ruff format` on staged `.py` files.
- Uses `git stash --keep-index` to isolate staged content, so partial
  staging (`git add -p`) is preserved correctly.
- Auto-corrected files are re-staged; rejects the commit if uncorrectable offenses remain.
