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

## Sentence Structure

- Mix short and medium sentences
- Not overly complex
- Use colons before lists
- "But" to introduce counterpoints is fine

## Punctuation & Mechanics

- **Oxford comma**: Always use it
- **Em-dashes**: Use sparingly. Do not add unless it significantly improves the prose.
- **Contractions**: Use naturally (don't, isn't, I've)
- **Exclamation marks**: Rarely. Only for genuine enthusiasm.
- **Ellipses**: Avoid

## Comparisons to Other Works

A distinctive feature of these reviews is extensive comparison to other books.

Common patterns:
- "reminded me of" (most frequent)
- "similar to"
- "like X's Y"
- "references"

These comparisons serve two purposes:
1. Help readers understand the book by relating it to known works
2. Generate backlinks displayed on the referenced book's page

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
