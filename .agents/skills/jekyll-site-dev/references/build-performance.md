# Build performance decisions

## Retain HTML compression (D4)

Measured on 2026-10-17 on the same machine and branch, after D5 and D6.
Each variant ran `make serve-profile` followed by `make build`. The
uncompressed variant temporarily removed `layout: compress` from
`_layouts/default.html`; the original file was restored afterward.

| Liquid template        | Compressed | Uncompressed |
| ---------------------- | ---------: | -----------: |
| `compress.html`        |    1.058 s |       absent |
| `anchor_headings.html` |    0.917 s |      0.855 s |

The profile build took 18.83 s versus 17.76 s wall; production took 19.24 s
versus 16.40 s. These are single runs, so the wall-time difference includes
host-load variation. Template times are nested; do not add them together.

Production transfer sizes, gzip level 6:

| Page                            | Compressed HTML | Without compression | Increase |
| ------------------------------- | --------------: | ------------------: | -------: |
| `/`                             |         6,877 B |             7,070 B |    2.81% |
| `/books/by-rating/`             |        29,094 B |            29,988 B |    3.07% |
| `/books/`                       |        28,898 B |            29,683 B |    2.72% |
| `/blog/favorite-books-of-2025/` |        16,240 B |            16,716 B |    2.93% |
| `/books/by-author/`             |        36,337 B |            37,512 B |    3.23% |

The plan requires an increase under 2% to remove compression. Every sample
exceeds it, so retain the layout. Across 425 HTML files, HTML5 parsing found
the same element structure, prose text across inline tags, and exact `pre`
contents after normalizing build timestamps and attribute whitespace. The
extra files include local ignored notes and redirect stubs.

## Conversion caches and full startup renders (D9)

`make build`, `make serve`, `make serve-drafts`, and `make serve-profile`
retain conversion caches in separate directories under `.jekyll-cache/`:
`production`, `serve`, `serve-drafts`, and `profile`.

Before Jekyll starts, `_bin/prepare_build.rb` removes `_site` and
`.jekyll-metadata`. Each target calls it as the first command of its own
recipe, not as a shared prerequisite: make runs a prerequisite once per
invocation, so `make build serve` would prepare only `production`.
`test_one_make_invocation_prepares_every_mode_before_its_jekyll_command`
checks this with `make -n`. Every invocation starts with a full render,
including preview targets that use incremental rendering while the server
runs.
`make check-links` therefore checks fresh output. CI still builds from its
fresh checkout; the workflow does not restore site conversion caches.
`make clean` remains a full reset of output, all conversion caches, and
incremental metadata.

The preparer hashes paths and contents of `Gemfile.lock`, `Dockerfile`,
`.ruby-version`, root `_config*.yml`, and every file under `_plugins/`.
A changed fingerprint removes that mode's cache before reuse. Adding or
deleting a config or plugin also invalidates it. The generated YAML overlays
select `cache_dir`; Jekyll 4.4.1 rejects a `--cache-dir` command-line option.
Fingerprints and overlays live beside the cache directories and disappear
with `make clean`. Ordinary content changes preserve conversions, whose keys
include their rendered Markdown input; plugins and related lists still run
for every page at startup.

### Measurement and decision

Retain conversion caches between builds. The cross-document checks below
passed, and repeated builds and preview startup both became faster.

Measured on 2026-10-17 after D4–D6, on the same Intel i5-7267U with Ruby
3.4.10 and Jekyll 4.4.1. Each target ran three times serially with the
original Makefile, then three times with the candidate. Times include Docker
startup; server timing stops at `Server address:`. Image building is excluded.
The production cache was primed before the candidate runs. The first preview
run populated its separate cache; the following two reused it.

| Command      | Original median | Candidate median | Saving |
| ------------ | --------------: | ---------------: | -----: |
| `make build` |        19.356 s |         13.342 s |  31.1% |
| `make serve` |        18.058 s |         13.200 s |  26.9% |

Build runs were 20.026, 18.751, 19.356 s before and 13.253, 13.342,
13.398 s after. Preview startup was 18.876, 18.044, 18.058 s before and
17.306, 13.200, 12.756 s after. These measurements compare the original
full cleanup with retained conversions; every run still renders every page.
The benefit depends on warm conversions, and host load affects wall time.

### Cross-document verification procedure

Run these checks in a temporary copy of the repository. Use the real
Makefile, dependency manifests, plugins, layouts, includes, config, and image
assets, with only two book reviews and their author page. Alpha links to
Beta with `{% book_link "Beta" %}`; both have the same author and no series.
Give Alpha rating 4 and Beta rating 3, valid Wikidata IDs and local covers.
Their publication dates must be in the past. Add a valid draft post at
`_drafts/cache-draft.md`.

Add this Liquid to each review to distinguish production and preview output:

```liquid
{% if jekyll.environment == "production" %}
D9_PRODUCTION_ONLY
{% else %}
D9_PREVIEW_ONLY
{% endif %}
```

1. Run `make build`. Confirm Beta's backlinks name Alpha and its related
   card shows rating 4. Write a sentinel file inside
   `.jekyll-cache/production/`.
2. Rename Alpha in its front matter; run `make build` again. Confirm Beta's
   HTML and Markdown backlinks use the new title and the sentinel survives.
3. Change Alpha's rating to 5 and build again. Confirm Beta's related card
   shows 5, no longer shows 4, and the sentinel survives.
4. Record all HTML paths. Add `_plugins/cache_probe.rb` with a post-render
   hook for both `:documents` and `:pages` that appends an HTML comment marker
   to HTML output. Build again. Confirm the sentinel is removed and every
   recorded HTML page contains the marker. Remove the plugin and build again.
5. Seed the production sentinel again. Write `_site/obsolete.txt`, then run
   `make serve-drafts` to its server-address message. Confirm the draft
   exists, output contains only `D9_PREVIEW_ONLY`, obsolete output is gone,
   and the production sentinel survives. Stop the server.
6. Seed a sentinel inside `.jekyll-cache/serve-drafts/`. Rename Alpha again,
   add obsolete output, and restart `make serve-drafts`. Confirm Beta's
   backlink reflects the new title, obsolete output is gone, and the draft
   cache sentinel survives. This checks a full initial render with warm
   conversions and saved incremental metadata. Stop the server.
7. Run `make build` again. Confirm the draft is absent, only
   `D9_PRODUCTION_ONLY` appears, and both mode sentinels survive.
8. Run `make serve`. Confirm drafts are absent, only `D9_PREVIEW_ONLY`
   appears, and the other modes' sentinels survive. Stop the server.
9. Run `make clean`. Confirm `_site`, `.jekyll-cache`, and `.jekyll-metadata`
   are gone.

All nine checks passed on 2026-10-17. The temporary fixture used the real
Makefile and plugins; each build and server ran in its own Docker process.
`_tests/bin/test_prepare_build.rb` additionally checks dependency edits with
unchanged mtimes, added/deleted inputs, mode separation, content-only edits,
generated overlays, output removal, and invalid mode rejection.

Final validation on the same date: `make test` passed 2,818 tests and 7,554
assertions, with 99.59% line and 90.65% branch coverage. `make lint`,
`make check-links`, `make check-refs`, and `make check-liquid` passed. An
obsolete file seeded in `_site` before `make check-links` was removed by its
build, confirming that the link checker sees fresh output.
