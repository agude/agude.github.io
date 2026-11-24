# Book Families and `canonical_url`

When a book is re-reviewed, keep the new review at the canonical book path and
move each older review into a subdirectory under that book's name.

- The canonical review must not have `canonical_url` in its front matter.
- Each archived review sets `canonical_url` to the canonical review's exact
  local URL, including its trailing slash. This keeps book links pointed at
  the current review. Do not add whitespace or use an external or
  protocol-relative URL.
- If an archived review is used as a canonical target, that target must not
  itself set `canonical_url`.
- A canonical URL that is not a string or local path, has surrounding
  whitespace, or differs from an existing book URL by its trailing slash
  stops the build. A canonical page that also has `canonical_url` stops the
  build.
- Reviews of the same edition share `wikidata_qid`, `isbn`, and
  `same_as_urls` values. Different editions have separate canonical pages
  and do not belong to one family.

