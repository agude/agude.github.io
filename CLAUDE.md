# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a Jekyll-based static site (alexgude.com) that serves as a personal blog and book review platform. The site runs entirely in Docker containers to ensure consistent builds across environments.

## Common Commands

All development is done through Docker via the Makefile. Never run Jekyll commands directly.

### Building and Serving
- `make serve` - Build and serve the site at http://localhost:4000 with live reload
- `make drafts` - Serve the site including draft posts and future-dated content
- `make build` - Build the site to `_site/` directory
- `make clean` - Clean Jekyll build artifacts
- `make profile` - Profile Jekyll build performance

### Docker Image Management
- `make image` - Build the Docker image (automatically runs before serve/build)
- `make refresh` - Rebuild Docker image without cache (use when Dockerfile changes)

### Testing
- `make test` - Run all Minitest tests in `_tests/`
- `make test TEST=_tests/plugins/test_specific.rb` - Run a specific test file
- `make test TEST=$(find _tests/plugins/utils -name 'test_*.rb')` - Run tests matching a pattern

### Dependency Management
- `make lock` - Update and normalize Gemfile.lock using Docker (commit result)
- `make debug` - Start interactive bash session in Docker container

**Important**: The `--host 0.0.0.0` flag is NOT used on the command line because it forces Jekyll to set `site.url` to "http://0.0.0.0:4000", which breaks in modern browsers. Instead, host configuration is handled in `_config_docker.yml` which sets `host: 0.0.0.0` (for Docker networking) and `url: ""` (for browser-friendly relative links).

## Architecture

### Content Collections
- `_posts/` - Blog posts (Markdown with YAML front matter)
- `_books/` - Book reviews as a Jekyll collection with custom front matter
- `_layouts/` - HTML templates (book.html, post.html, etc.)
- `_includes/` - Reusable template fragments

### Custom Plugin System

This site has an extensive custom plugin architecture with ~40 plugins in `_plugins/`:

**Core Infrastructure**:
- `link_cache_generator.rb` - Pre-builds lookup caches for authors, books, series, and navigation to avoid expensive page traversals during rendering. Creates `site.data['link_cache']` with keys: `authors`, `books`, `series`, `short_stories`, `sidebar_nav`, `backlinks`, etc.
- `environment_setter.rb` - Sets Jekyll environment variables
- `front_matter_validator.rb` - Validates front matter fields

**Liquid Tags** (custom template tags):
- Book/content rendering: `book_card_lookup_tag.rb`, `article_card_lookup_tag.rb`, `render_book_card_tag.rb`, `render_article_card_tag.rb`
- Linking: `book_link_tag.rb`, `author_link_tag.rb`, `series_link_tag.rb`, `short_story_link_tag.rb`
- Lists: `display_books_by_author_tag.rb`, `display_category_posts_tag.rb`, `display_ranked_books_tag.rb`, `front_page_feed_tag.rb`
- Relationships: `related_books_tag.rb`, `related_posts_tag.rb`, `book_backlinks_tag.rb`
- Utilities: `rating_stars_tag.rb`, `units_tag.rb`, `citation_tag.rb`

**Plugin Utilities** (`_plugins/utils/`):
- Card rendering: `article_card_utils.rb`, `book_card_utils.rb`, `card_renderer_utils.rb`, `card_data_extractor_utils.rb`
- Linking: `link_helper_utils.rb`, `author_link_util.rb`, `book_link_util.rb`, `series_link_util.rb`, `short_story_link_util.rb`
- Lists: `book_list_utils.rb`, `post_list_utils.rb`, `feed_utils.rb`
- Structured data: `json_ld_utils.rb` with generators in `json_ld_generators/` (book_review_generator.rb, blog_posting_generator.rb, etc.)
- Text/logging: `text_processing_utils.rb`, `typography_utils.rb`, `plugin_logger_utils.rb`
- Other: `rating_utils.rb`, `url_utils.rb`, `citation_utils.rb`, `backlink_utils.rb`

### Plugin Logging System

Plugins use a centralized logging system configured in `_config.yml`:
- `plugin_log_level`: Global log level (debug, info, warn, error)
- `plugin_logging`: Individual switches for each tag type (e.g., `BOOK_CARD_LOOKUP: true`)

Use `PluginLoggerUtils.log_liquid_failure()` to log errors/warnings with a specific `tag_type` that maps to config switches.

### Testing

Tests use Minitest and live in `_tests/`:
- `test_helper.rb` - Loads Jekyll, plugins, and provides mock objects (MockDocument, MockSite, MockDrop, MockContext)
- `_tests/plugins/` - Tests for individual plugins
- `_tests/plugins/utils/` - Tests for utility modules

Tests run inside Docker via `make test` to ensure the same environment as builds.

### Book Review Features

Books have rich metadata in front matter:
- `book_authors`: Author name(s)
- `series`: Series name (if applicable)
- `book_number`: Position in series
- `rating`: 1-5 star rating
- `awards`: Array of awards (hugo, nebula, etc.)
- `is_anthology`: Boolean flag

Book reviews use Liquid captures extensively to create reusable text snippets:
```liquid
{% capture this_book %}<cite class="book-title">{{ page.title }}</cite>{% endcapture %}
{% capture the_author_link %}{% author_link page.book_authors %}{% endcapture %}
```

Custom tags handle cross-linking:
- `{% book_link "Title" %}` - Link to a book review
- `{% author_link "Name" %}` - Link to author page
- `{% series_link "Series" %}` - Link to series page
- `{% short_story_link "Title" %}` - Link within anthology

### Generated Pages

The `books/` directory contains generated navigation pages:
- `by_author.md`, `by_title.md`, `by_series.md`, `by_rating.md`, `by_awards.md`
- `authors/` - Individual author pages
- `series/` - Individual series pages

These use custom display tags to render book lists.

### Python Scripts

`_scripts/` contains Python utilities:
- `make_pages.py` - Generates author/series pages
- `compare_backlinks.py` - Analyzes book cross-references
- `jekyll_clean_captures.py` - Cleans up Liquid capture syntax
- Uses `uv` for Python dependency management (see `pyproject.toml`, `uv.lock`)

## Jekyll Configuration

- Main config: `_config.yml`
- Docker config overlay: `_config_docker.yml` (merged with main via `--config _config.yml,_config_docker.yml`)
- Ruby version: Defined in `.ruby-version` (currently 3.2)
- Bundler version: Hardcoded in Makefile as `BUNDLER_VERSION := 2.6.8`

Key settings:
- Permalink format: `/blog/:slug/`
- Paginate: 10 posts per page at `/blog/page:num/`
- Collections: `books` with output enabled
- Plugins: jekyll-feed, jekyll-paginate, jekyll-redirect-from, jekyll-seo-tag, jekyll-sitemap

## Development Workflow

1. Make changes to content/code
2. Run `make serve` (or `make drafts` for draft posts)
3. View at http://localhost:4000
4. Changes auto-reload (incremental builds enabled)
5. Run `make test` before committing to verify plugin changes
6. If Gemfile changes, run `make lock` and commit the updated Gemfile.lock
7. If Dockerfile changes, run `make refresh` to rebuild image without cache

## Commit Message Style

This repository follows a structured commit message format for clarity and consistency:

**Format:**
```
Short imperative headline (50-60 chars)

Detailed explanation paragraph describing what was refactored and why. Long
lines are hard wrapped at 80 chars.

- First specific change with `code elements` in backticks.
- Second specific change.
- Additional changes as needed.
```

**Guidelines:**
- **Headline**: Use imperative mood (e.g., "Decouple", "Refactor", "Isolate"), be concise
- **Body**: Start with "Refactored the `ClassName.method_name` method by..." or similar
- **Changes list**: Use `*` bullets with backticks for method names, class names, and code elements
- **Benefit**: End with a sentence explaining the improvement (clarity, maintainability, testability, etc.)

**Example:**
```
Decouple BlogPostingLdGenerator logic into private helpers

Refactored the `BlogPostingLdGenerator.generate_hash` method by
extracting its data construction logic into dedicated private helper
methods.

The changes include:
*   Extracting the base data structure creation into `base_data_hash`.
*   Isolating headline addition into `add_headline`.
*   Moving author and publisher entity construction into
    `add_author_and_publisher`.

This improves the clarity and maintainability of the JSON-LD generation
logic.
```

## File Organization

- `/files/` - Static assets (images, PDFs, data files)
- `/public/` - Public static files
- `/_sass/` - Sass stylesheets
- `/assets/` - Compiled assets
- `/topics/` - Topic/category pages
- `/.jekyll-cache/`, `/.jekyll-metadata` - Build caches (ignored in git)

## Key Constraints

- Always use Docker via Makefile - never run `jekyll` or `bundle` commands directly
- Test files must be named `test_*.rb` and NOT be named `test_helper.rb`
- Plugin utils must be required with correct paths (e.g., `require_relative 'utils/plugin_logger_utils'`)
- The link cache must be built before tags that depend on it can run (handled by generator priority)
- Book front matter must be valid for the custom tags to work correctly
