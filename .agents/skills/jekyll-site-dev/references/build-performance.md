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

## Preview-integrity validation

`PreviewIntegrityValidator` checks that each raw book or footnote preview
marker is preceded by `>` and followed by `<` when those adjacent characters
exist. Keep this validation enabled for every HTML page.

Search for the violating marker and its adjacent character first. Extract up
to 40 characters on each side only when reporting an error. A leading
`.{0,40}` in the detection regex repeats the context search across valid
pages and makes successful validation expensive.

Measured on 2026-11-09 against the same 425 generated HTML files, three
serial validator-only runs took 0.585, 0.492, and 0.755 seconds before the
change and 0.0183, 0.0178, and 0.0177 seconds afterward. The test matrix
covers opening and closing markers for both preview types, newlines,
Unicode, and markers at string boundaries. Error messages retain the page
identifier and surrounding source.

Serial `make build` runs on the same branch used the original validator,
then the optimized validator. Each variant ran once after its plugin change
invalidated conversion caches, followed by three warm builds. Image building
was excluded; every page still rendered.

| Measurement                      | Original | Optimized |
| -------------------------------- | -------: | --------: |
| Jekyll compile, cold conversions | 16.899 s |  16.374 s |
| Jekyll compile, warm median      | 12.392 s |  12.156 s |
| Whole command, warm median       | 14.835 s |  14.770 s |

Warm Jekyll runs were 12.392, 12.296, 12.461 seconds before and 12.156,
11.782, 12.784 seconds afterward. The median compile reduction was 1.9%;
Docker startup and host load make whole-command differences noisy. These
samples establish a small compile improvement, not a uniform latency saving.

Verification: all 1,423 generated files matched after normalizing generated
sidebar and feed timestamps. `make test` passed 2,821 tests and 7,696
assertions; `make lint`, `make check-links`, `make check-refs`, and
`make check-liquid` passed. The final focused validator run passed 11 tests
and 128 assertions.

## Ruby execution and Markdown/HTML fast paths

The November 2026 follow-up keeps all rendering and validation enabled and
reduces work within those stages:

- `MarkdownFenceParser.fence_start` rejects lines without a three-backtick
  or three-tilde run before parsing containers. Eligible lines still use
  the full fence parser, including list and blockquote rules.
- `MarkdownCodeRegionParser` rejects lines without a possible code indent
  before allocating blockquote prefixes. Differential checks found identical
  protected ranges in 281 repository documents and 1,000 generated inputs.
- `HtmlCompressionFilter` handles the layout's whitespace-only settings in
  Ruby, preserving its literal `<pre`/`</pre>` splitting and whitespace
  behavior. `_layouts/compress.html` retains the upstream implementation
  for nonempty endings, startings, comments, or clippings, and for blank-line
  or profile modes. Tests compare both implementations, including malformed
  tags, ignored environments, and preformatted content.
- Local Docker commands enable Ruby YJIT by default. Use
  `make build RUBY_YJIT_ENABLE=0` for an interpreter-only comparison. The
  CI build job also enables it for both Jekyll builds. No content, validators,
  compression options, Markdown twins, or startup renders are skipped.

### Follow-up measurements

Measured on 2026-11-09 with Ruby 3.4.10. The baseline restores the original
tracked plugin/layout source and disables YJIT. The candidate uses all three
plugin optimizations, the compressor fast path, and YJIT.

Four serial production builds per variant measured one cold conversion
cache followed by three warm runs. Cold compile time fell from 15.266 to
12.746 seconds (16.5%). Warm medians in that series were 10.996 and 9.991
seconds; host-load variation warranted an alternating comparison.

The alternating comparison retained a separate matching conversion cache
and dependency fingerprint for each variant. It ran three warm builds per
variant in baseline/candidate, candidate/baseline, baseline/candidate order.
Every invocation still used the normal preparer to remove `_site` and
incremental metadata and render every page.

| Alternating warm-build median | Original | Optimized | Reduction |
| ----------------------------- | -------: | --------: | --------: |
| Jekyll compile                | 10.382 s |   8.702 s |     16.2% |
| Whole `make build` command    | 12.457 s |  11.075 s |     11.1% |
| Ruby process CPU time         | 10.997 s |   9.408 s |     14.4% |

Compile runs were 10.300, 10.713, 10.382 seconds before and 8.988, 8.702,
8.490 seconds afterward. Ruby CPU time includes process startup; compile
time is Jekyll's own elapsed-time report. Median warm peak RSS increased
from 152,596 to 184,684 KiB (about 31 MiB) with the candidate.

All 1,423 generated files matched the baseline after normalizing only the
generated sidebar and feed timestamps.

Final validation passed: `make test` (2,827 tests, 7,744 assertions, 99.59%
line and 90.62% branch coverage), `make lint`, `make check-links`,
`make check-refs`, and `make check-liquid`.
