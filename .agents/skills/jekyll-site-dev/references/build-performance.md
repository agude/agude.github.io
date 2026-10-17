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
