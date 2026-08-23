# Book Families & `canonical_url`

When a book is re-reviewed, the old review moves to a subdirectory and a new
canonical review takes its place:

```
_books/hyperion.md                      ← canonical (NO canonical_url)
_books/hyperion/review-2023-10-17.md    ← archived  (canonical_url: /books/hyperion/)
```

## Rules

- The **canonical review** (top-level file) must **never** have `canonical_url`
  in its front matter. It _is_ the canonical page.
- **Archived reviews** set `canonical_url` to the canonical page's URL so the
  link resolver filters them out and `book_link` always points to the current
  review.
- When adding metadata (ISBN, Wikidata, etc.) to book families, do **not**
  copy `canonical_url` from an archived review into the canonical file.

`BookFamilyValidator` breaks the build if a page referenced as a canonical
target also has `canonical_url` set (see **Build Validators**).
The link resolver filters archived reviews by rejecting entries with a
local `canonical_url`.
