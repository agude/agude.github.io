---
name: parse-book-notes
description: >-
  Parse rough book-review notes into Liquid capture blocks. Use when starting
  a book review to turn voice-transcribed notes into template variables for
  books, authors, and series mentioned.
---

# Parse Book Notes

Turn rough notes (often voice-transcribed) into `{% capture %}` blocks for
book reviews.

## Usage

`/parse-book-notes` --- Pass rough notes and get back capture blocks for
books, authors, series, and other media referenced.

## Steps

1. Parse notes for mentions of books, authors, series, short stories,
   movies, games
2. Fix voice transcription errors (see below)
3. Generate capture blocks following the naming conventions below
4. Validate spellings against `_books/`, `books/authors/`, `books/series/`

## Capture Pattern

For each book referenced, generate this bundle (grouped by book, blank line
between groups):

```liquid
{% capture banks %}{% author_link "Iain M. Banks" %}{% endcapture %}
{% capture bankss %}{% author_link "Iain M. Banks" possessive %}{% endcapture %}
{% capture banks_lastname %}{% author_link "Iain M. Banks" link_text="Banks" %}{% endcapture %}
{% capture bankss_lastname %}{% author_link "Iain M. Banks" link_text="Banks" possessive %}{% endcapture %}
{% capture culture %}{% series_link "Culture" %}{% endcapture %}
{% capture surface_detail %}{% book_link "Surface Detail" %}{% endcapture %}
```

### Variable naming

- `banks` --- full name link
- `bankss` --- possessive (double s for names ending in s)
- `banks_lastname` --- surname-only link
- `bankss_lastname` --- surname-only possessive
- Books and series: `snake_case` of the title including articles
  (`the_player_of_games`). Common abbreviations are fine (`botns`).

### Rules

- **Generate all four author variants, always.** A partial set causes a
  missing-variable error later, when the review text needs a form that was never
  defined. Cheap to emit now, annoying to discover mid-draft.
- If multiple books share an author, include the author bundle only once
  (with the first book).
- Omit series capture for standalone books.
- Don't duplicate the standard captures from the book template (the book
  being reviewed, its author, its series).

## Treating the Notes

Two rules about the source notes themselves:

- **The notes outrank your reading of the text.** They record what is actually
  on the page; your objections are recalled from training data and are the less
  reliable of the two. Do not push back on a factual claim in the notes about
  plot, character, or biography — verify it or accept it. Offering an
  *additional* reading is fine; contradicting the note is not, unless the text
  is in front of you.

  Concrete failure: the notes said Sandii ("New Rose Hotel") is "a first run at
  Kumiko from *Mona Lisa Overdrive*." The objection that the mapping did not
  hold was wrong — Sandii is half Japanese, half Dutch, so both are
  mixed-heritage Japanese women caught between larger powers, exactly the
  connection the note was making.

- **Drafts are scratchpads.** The author scatters sentences and ideas into a
  draft as they occur to him, so they are not lost later. A sentence sitting
  under the wrong story section is usually a parking spot, not an error. Ask
  before flagging it as misfiled.

  `notes.md` holds raw reading notes above a separator and a `# Review Plan`
  below it. The plan carries a Status block, per-story theme assignments,
  factual corrections, and "captures still needed." Append to the plan; never
  touch the raw notes above the separator.

## Multiple Authors

Generate individual captures for each author, plus combined versions:

```liquid
{% capture el_mohtar_and_gladstone %}{% author_link "Amal El-Mohtar" %} and {% author_link "Max Gladstone" %}{% endcapture %}
{% capture el_mohtar_and_gladstones %}{% author_link "Amal El-Mohtar" %} and {% author_link "Max Gladstone" possessive %}{% endcapture %}
```

For siblings, use first names: `arkady_and_boris`. For 3+ authors
(anthologies), prefix with `author_`: `author_evans`, `author_weber`.

## Other Media

Movies, games, and TV shows use title tags (styled text, not hyperlinks):

```liquid
{% capture terminator %}{% movie_title "Terminator" %}{% endcapture %}
{% capture fallout %}{% game_title "Fallout" %}{% endcapture %}
{% capture ds9 %}{% tv_show_title "Deep Space Nine" %}{% endcapture %}
```

Filmmakers and showrunners get `author_link` pages. **Exception:** Disco
Elysium uses `{% book_link %}`.

## Voice Transcription Errors

Notes are often voice-transcribed and will contain errors:
- Misspellings ("shriek" for Shrike, "telehard" for Teilhard)
- Wrong words ("forecaster" for farcaster)
- Missing capitals, phonetic spellings ("bobiberse" for Bobiverse)

Check existing content for correct spellings. Use your knowledge of sci-fi
literature to resolve ambiguities. If unsure, ask.

Generate captures even without an existing review --- the plugins handle
missing content gracefully.
