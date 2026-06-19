# Style Guide

Voice and style reference for alexgude.com.

## Tone

- **First-person**: Always write as "I"
- **Conversational but substantive**: Not casual/chatty, but not academic either
- **Direct and opinionated**: State opinions clearly. "I loved it" or "I didn't like it"
- **No hedging**: Avoid "perhaps", "somewhat", "I think maybe"

## Vocabulary

Use simple, direct words:

| Prefer | Avoid |
|--------|-------|
| great | exceptional, remarkable |
| fun | delightful, enjoyable |
| loved | adored, was enamored with |
| good | commendable, praiseworthy |
| bad | suboptimal, less than ideal |
| interesting | intriguing, fascinating |
| boring | tedious, unengaging |

The test: Would you say it out loud to a friend? If not, simplify.

**Stacked adjectives**: Avoid comma-separated adjective pairs like "brutal,
high-stakes" or "dark, gritty". Pick the one that does the most work and drop
the other. LLMs love doubling up adjectives; the author almost never does.

## Sentence Structure

- Mix short and medium sentences
- Not overly complex
- Use colons before lists
- "But" to introduce counterpoints is fine

## Interpretation, Metaphor, Voice

- **Don't overclaim interpretation.** Distinguish what the text supports
  (observation) from what you're reading into it (a character's intent, desire,
  aspiration). The author pushes back on "this feels like reading into it" — stay
  with what's on the page.
- **No metaphors or figurative language.** "Stepping away from the bridge" is too
  cute; say what you mean literally.
- **Reference other works in passing** — one phrase, trust the reader. Don't
  summarize the other work inline.
- **Preserve the author's structural choices.** A repeated _But_ / **But**
  pattern is intentional; don't flatten it. Don't editorialize or impose a new
  voice.
- **"Physicist writing" tendency:** the author over-uses thesis-statement
  phrasing ("in one specific way"). Flag it, but don't overcorrect.

## Punctuation & Mechanics

- **Oxford comma**: Always use it
- **Em-dashes**: Use sparingly. Do not add unless it significantly improves the prose.
- **Contractions**: Use naturally (don't, isn't, I've), but don't insert too
  many.
- **Exclamation marks**: Rarely. Only for genuine enthusiasm.
- **Ellipses**: Avoid
- **Bold**: Use `**double stars**` only.
- **Italics**: Use `_single underscores_` only.

## Comparisons to Other Works

A distinctive, **signature** feature — the author likes long, comprehensive
comparison sections and calls it "kinda my thing." Do **not** trim a long one
just to hit a count.

Common patterns:
- "reminded me of" (most frequent)
- "similar to"
- "like X's Y"
- "references"

Voice rules:
- **In passing** — one phrase, trust the reader. Don't summarize the other work
  inline.
- **Specific reasons.** Not "both have X" but "X in this book works like Y in
  that book because Z."

These comparisons serve two purposes:
1. Help readers understand the book by relating it to known works
2. Generate backlinks displayed on the referenced book's page

See `BOOK-REVIEWS.md` › Literary Comparisons for how the dedicated comparisons
section is structured (lead-in sentence, format, thematic grouping).

## Footnotes

Use footnotes for:
- Extended quotes from the book
- Tangential but interesting details
- Plot summaries that would interrupt flow

Format:
```markdown
Something in the text.[^label]

[^label]: The footnote content here.
```

## Block Quotes

For attributed quotes, use the `citedquote` tag:

```liquid
{% citedquote author_first="John" author_last="Keats" work_title="Poem" %}
Quote text here.
{% endcitedquote %}
```

For unattributed quotes from the book being reviewed, use markdown:

```markdown
> Quote from the book here.
```
