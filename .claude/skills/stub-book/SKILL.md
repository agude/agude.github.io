---
name: stub-book
description: Stub out a new book review file with front matter and template captures. Use when adding a new book to _books/.
---

# Stub Book Skill

Create a new book review stub in `_books/` with full front matter and
standard capture blocks.

## Usage

`/stub-book <title>` --- Create a stub for the given book title.

The user may also provide author, series, book number, or a Wikidata QID.
If not provided, look them up.

## Steps

### 1. Determine Book Details

From the user's input, establish:
- **Title** (required)
- **Author** (required)
- **Series** and **book number** (null if standalone)

If the book is part of a series already reviewed on the site, check an
existing entry in `_books/` for the correct author name, series name, and
series numbering convention.

### 2. Find the Wikidata QID

If the user did not provide a QID, search for one:

```bash
cd _scripts/metadata && uv run fetch_book_metadata.py "Book Title"
```

The script prints numbered search results to stderr and picks the first
match by default. **Read the results carefully.** Look for the entry
described as the original novel/work, not a specific edition or
translation.

- If the top result is wrong (e.g., a 2000 Baen edition instead of the
  1993 original novel), note the correct QID from the list and pass it
  to `--qid` in step 3. There is no need to re-run the search script;
  the QID is all the stub script needs.
- If the results are all wrong or empty, the book has no Wikidata entry.
  Proceed to step 3 without a QID.

### 3. Build the Front Matter and Opening

You are responsible for composing these two pieces. The script
(`stub_book.py`) is a mechanical assembler — it does not make content
decisions.

#### Front matter

Build a YAML block (without `---` delimiters) containing these fields:

```yaml
date: <today, YYYY-MM-DD>
title: <title>
book_authors: <author>
series: <series name or null>
book_number: <number, use 1 for standalone>
is_anthology: false
rating: null
image: /books/covers/<snake_case_title>.jpg
```

#### Opening paragraph

Write a one-line Liquid opening. Examples by case:

- **Series with number:**
  `{% book_link page.title %}, by {% author_link page.book_authors link=false %}, is the second book in {% series_text page.series link=false %}.`
- **Series without number:**
  `{% book_link page.title %}, by {% author_link page.book_authors link=false %}, is a book in {% series_text page.series link=false %}.`
- **Standalone:**
  `{% book_link page.title %}, by {% author_link page.book_authors link=false %}, is ...`

### 4. Run the Stub Script

The script at `scripts/stub_book.py` (relative to this skill) reads
`_books/_template/book_template.md`, replaces sentinel comments with the
values you provide, and writes the result.

Run from the **project root**:

```bash
uv run .claude/skills/stub-book/scripts/stub_book.py \
    --front-matter "date: 2025-01-15
title: The Honor of the Queen
book_authors: David Weber
series: Honor Harrington
book_number: 2
is_anthology: false
rating: null
image: /books/covers/the_honor_of_the_queen.jpg" \
    --opening "{% book_link page.title %}, by {% author_link page.book_authors link=false %}, is the second book in {% series_text page.series link=false %}." \
    --series \
    --qid Q3400447 \
    --output _books/the_honor_of_the_queen.md
```

**Flags:**

| Flag | Purpose |
|---|---|
| `--front-matter` | YAML content (no `---` delimiters). Required. |
| `--opening` | Opening paragraph with Liquid tags. Required. |
| `--series` | Include the `this_series` capture block. Omit for standalone books. |
| `--qid` | Wikidata Q-ID. Fetches `isbn`, `date_published`, `same_as_urls` and appends them to the front matter. |
| `--output` / `-o` | Write to file. Omit to print to stdout. |

### 5. Post-Processing

After the script runs, check for issues that need manual fixes:

#### Refine `date_published`

The Wikidata date may be year-only (e.g., `1993`). Existing entries use
`YYYY-MM` format (e.g., `1993-04`). Search Goodreads or the publisher's
site for a more specific date and update the front matter.

#### Check the ISBN

The script takes the first ISBN it finds. This may be a foreign-language
edition. If so, search the Wikidata edition entities for an
English-language ISBN, or find one on the publisher's site. The ISBN
should be ISBN-13 format (978-...).

#### Verify `same_as_urls`

The work-level Wikidata entity (the original novel, not a specific
edition) will have the richest set of `same_as_urls`. If you had to use
an edition QID instead, the URLs may be sparse. Check whether the work
entity exists separately and use its QID if possible.

### 6. Create Author and Series Pages

If the author is new to the site (no existing page under
`books/authors/`), generate the page:

```bash
uv run _scripts/content/make_pages.py
```

This creates stub pages for any authors or series in `_books/` that
don't already have one.

Then fetch the author's `same_as_urls` from Wikidata:

```bash
cd _scripts/metadata && uv run fetch_author_same_as.py "Author Name"
```

The script prints numbered search results. Pick the entry for the
person (not a bibliography or disambiguation page). Copy the
`same_as_urls` list into the newly created author page under
`books/authors/`.

### 7. Report

Tell the user what was created and flag remaining manual steps:
- Cover image needs to be added at the `image` path.
- `rating` and `date` need updating after the review is written.
- Any metadata issues found in step 5.
