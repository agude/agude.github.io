# CI/CD & Hooks

**GitHub Actions** (`.github/workflows/jekyll.yml`) runs on every push:

1. `bundle exec rubocop` (lint).
2. `bundle exec ruby ... load test_*.rb` (tests).
3. `bundle exec ruby _bin/check_strict.rb` (strict Liquid variables).
4. Build, HTML validation, broken-link check (main branch deploys).

**Pre-commit hook** (`_bin/pre-commit.sh`, install via `make hooks-install`):

- Runs `rubocop --autocorrect` inside Docker on staged `.rb` files.
- Runs `prettier --write` inside Docker on staged `.md` files (excluding meta files).
- Auto-corrected files are re-staged automatically.
- Rejects the commit if uncorrectable offenses remain.
