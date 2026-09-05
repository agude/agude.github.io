---
name: stub-book
description: >-
  Creates a new book-review stub in _books/ with standard front matter, Liquid
  captures, Wikidata metadata, and supporting author or series pages. Use when
  adding a new book review, including requests to create a book-review file.
---

# Stub Book

Create a canonical book-review stub in `_books/`. Run the commands below from
the project root.

This workflow does not cover re-reviews. For a review whose book already has a
canonical page, follow the book-family and `canonical_url` workflow in
`../jekyll-site-dev/references/book-families.md` instead.

Use `/stub-book <title>`. The request may also include the author, series,
book number, or a Wikidata QID. Look up any missing detail before creating the
file.

## Gather the book details

Confirm the title and author before creating the file. Also determine whether
the work belongs to a series, its number in that series, and whether it is an
anthology or short-story collection.

For a series that already appears on the site, use an existing `_books/` entry
to match the stored author name, series name, and numbering. Do not run the
stub script against an existing output path: it overwrites that file.

The stub script creates a single-author novel. For multiple authors, an
anthology, or another atypical work, use its output only as a starting point:

- Change `book_authors` to a YAML list when applicable.
- Set `is_anthology: true` for an anthology or short-story collection. The
  short-story link cache scans only books with this exact value.
- Replace the generated opening and captures with forms appropriate to the
  contributors. The standard template assumes one author.

If a title, author, or series name contains YAML-significant characters such
as `:`, `#`, `&`, `?`, brackets, braces, or quotes, quote and escape that value
in the generated front matter before continuing. The stub script writes these
values without YAML quoting.

## Resolve the Wikidata work

Use a work-level QID when one exists. It identifies the original literary work
and normally has more complete metadata than an edition or translation.

```bash
(cd _scripts/metadata && uv run fetch_book_metadata.py "Book Title")
```

The script lists candidates on stderr. In an interactive terminal, select the
correct work; otherwise it uses the first result. Inspect the candidates before
using the QID. If no appropriate work exists, continue without one and report
that metadata still needs manual entry.

Use the metadata scripts rather than an ad hoc Wikidata request. They include
the required `User-Agent`; raw `requests` or `urllib` calls can receive a 403.

## Create the stub

Run the script with the known details. Omit `--series` for a standalone work,
and omit `--qid` only when no reliable work QID is available.

```bash
uv run _scripts/skills/stub_book.py \
    --title "The Honor of the Queen" \
    --author "David Weber" \
    --series "Honor Harrington" \
    --book-number 2 \
    --qid Q3400447
```

The script writes `_books/<snake_case_title>.md` by default. Use
`--output _books/<filename>.md` or `-o _books/<filename>.md` only after
confirming that the path is new.
`--title` and `--author` are required; `--book-number` defaults to `1`.
It generates:

- today’s `date`, the title, author, series, book number, `rating: null`,
  `is_anthology: false`, and the expected cover-image path;
- `wikidata_qid` when `--qid` is supplied;
- a first paragraph that uses the book, author, and series Liquid tags; and
- the standard capture blocks after that paragraph, including `this_series`
  only for a series work.

The opening paragraph is the excerpt. Keep capture blocks below it.

## Enrich the front matter

When the file has a reliable QID, populate its metadata:

```bash
(cd _scripts/metadata && uv run update_book_metadata.py \
    _books/the_honor_of_the_queen.md)
```

By default, the updater only adds missing values. It manages
`wikidata_qid`, `isbn`, `date_published`, `awards`, and `same_as_urls`; do not
use `--force` unless replacing a manually curated value is intentional. Use
`--only` to refresh a specific field.

Review the result before treating it as final:

- Refine a year-only `date_published` value to `YYYY-MM` or `YYYY-MM-DD` when
  Goodreads, a publisher, or another reliable source supports a more precise
  date.
- The updater prefers an ISBN-13 on the work. If the work has none, it checks
  editions and prefers the first English-language ISBN it finds, then falls
  back to the first available ISBN. Check that the selected ISBN describes the
  intended edition, and prefer a 13-digit ISBN (`978-...`) when one is
  available. To inspect editions, run:

  ```bash
  (cd _scripts/metadata && uv run list_editions.py Q_WORK_ID)
  ```

- For an anthology, inspect awards for the individual stories as well as the
  collection. The updater only looks up awards attached to the book’s QID;
  add verified Hugo, Nebula, or Locus awards for its contents to `awards`.
- Check that `same_as_urls` came from a work-level QID. An edition QID often
  has fewer useful links.

## Create supporting pages

Generate missing author and series page stubs after the new book is in `_books/`:

```bash
uv run _scripts/content/make_pages.py
```

For each new author page, fetch the person’s metadata:

```bash
(cd _scripts/metadata && uv run fetch_author_same_as.py "Author Name")
```

Select the person rather than a bibliography or disambiguation item. Copy the
returned `pen_names` and `same_as_urls` into the author page under
`books/authors/`. Preserve values already curated on an existing author page.

## Validate and report

Run `make check-liquid` after the stub and supporting pages are complete. It
renders the generated Liquid without requiring a finished review. Before
publishing the completed review and cover image, run all content gates:

```bash
make check-links && make check-refs && make check-liquid
```

Report the file and supporting pages created, the QID and metadata added, and
the remaining work: cover image at the `image` path, final rating and review
date, any manual metadata corrections, and any validation failure.
