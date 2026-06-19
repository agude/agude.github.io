---
name: stub-book
description: >-
  Stub out a new book review file with front matter and template captures.
  Use when adding a new book to _books/.
---

# Stub Book

Create a new book review stub in `_books/` with full front matter and
standard capture blocks.

## Usage

`/stub-book <title>` --- The user may also provide author, series, book
number, or a Wikidata QID. If not provided, look them up.

## Steps

### 1. Determine Book Details

Establish title, author, series, and book number. If the book is part of
a series already reviewed on the site, check an existing `_books/` entry
for the correct names and numbering convention.

### 2. Find the Wikidata QID

```bash
cd _scripts/metadata && uv run fetch_book_metadata.py "Book Title"
```

The script prints numbered search results to stderr. Pick the entry for
the original novel/work, not a specific edition or translation. If no
match, proceed without a QID.

### 3. Run the Stub Script

```bash
uv run _scripts/skills/stub_book.py \
    --title "The Honor of the Queen" \
    --author "David Weber" \
    --series "Honor Harrington" \
    --book-number 2 \
    --qid Q3400447
```

Flags: `--title` (required), `--author` (required), `--series`,
`--book-number` (default: 1), `--qid`, `--output`/`-o`.
Omit `--series` for standalone books.

### 4. Update Metadata

```bash
cd _scripts/metadata && uv run update_book_metadata.py _books/<slug>.md
```

Fetches ISBN, publication date, `same_as_urls`, and awards from Wikidata.
Updates the file in place.

### 5. Post-Processing

Check the metadata for issues that need manual fixes:
- **`date_published`** --- Wikidata dates may be year-only. Refine to
  `YYYY-MM` using Goodreads or the publisher's site.
- **ISBN** --- The script takes the first ISBN found, which may be a
  foreign-language edition. Find an English-language ISBN-13 (978-...).
- **`same_as_urls`** --- Work-level Wikidata entities have the richest
  URLs. If you used an edition QID, check whether a work entity exists.

### 6. Create Author and Series Pages

```bash
uv run _scripts/content/make_pages.py
cd _scripts/metadata && uv run fetch_author_same_as.py "Author Name"
```

`make_pages.py` creates stub pages for any new authors or series.
`fetch_author_same_as.py` prints search results --- pick the person
entry and copy `same_as_urls` into the author page under
`books/authors/`.

### 7. Report

Tell the user what was created and flag remaining manual steps:
- Cover image needs to be added at the `image` path.
- Any metadata issues found in step 5.
