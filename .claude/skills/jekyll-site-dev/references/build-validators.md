# Build Validators

Validators raise `FatalException` to break the build on data errors. Each
one is a standalone class that accumulates all violations and raises once
with a clear, actionable message.

| Validator | File | What it catches |
| --- | --- | --- |
| **BookFamilyValidator** | `infrastructure/link_cache/book_family_validator.rb` | Book referenced as a canonical target by another book also has `canonical_url` set (copy-paste error) |
| **FavoritesValidator** | `infrastructure/link_cache/favorites_validator.rb` | `book_card_lookup` in favorites posts missing `date=` param or date mismatch |
| **LinkValidator** | `infrastructure/links/link_validator.rb` | Raw Markdown/HTML links to items that should use custom tags |
| **FrontMatterValidator** | `seo/front_matter_validator.rb` | Missing required front matter fields for a collection |

**When to add a validator:** If bad data can produce wrong output that would
go unnoticed, add a validator. If the issue is cosmetic or recoverable, log
a warning with `PluginLoggerUtils` instead.
