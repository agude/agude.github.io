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

`BookFamilyValidator` stops the build if a page used as a canonical target
also sets `canonical_url`. It is tagged `@validator`; list build validators
with `make doc-index QUERY='has_tag?(:validator)'`. The link resolver excludes
archived reviews by rejecting entries with a local `canonical_url`.

## Metadata and SEO

- All reviews in a family share the same `wikidata_qid`, `isbn`, and
  `same_as_urls` values because they describe the same book.
- `BookIdentityResolver` maps an archived review to the canonical review's
  URL. Every review in the family therefore uses the same Book `@id`
  (`/books/hyperion/#book`) and Book `url`. Each review keeps its own `Review`
  URL, date, and rating.
- Each archived review is distinct content, so its HTML canonical link points
  to its own URL.
- A book family contains multiple reviews of one edition. Different editions,
  such as the original and revised _There Is No Antimemetics Division_, each
  get their own canonical page and do not form a family.
