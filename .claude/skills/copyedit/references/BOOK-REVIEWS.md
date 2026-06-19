# Book Review Structure

Structure and conventions for book reviews on alexgude.com.

## File Location

Book reviews live in `_books/` as markdown files.

## Front Matter

```yaml
---
date: 2025-01-19
title: Book Title
book_authors: Author Name
series: Series Name  # or null
book_number: 1
rating: 4
image: /books/covers/book_title.jpg
awards:
  - hugo
  - nebula
---
```

For multiple authors:
```yaml
book_authors:
  - First Author
  - Second Author
```

## First Paragraph

The first paragraph is special:

1. **Pulled out for previews**: Used on social media cards, front page, related books sections
2. **No capture variables**: Cannot define `{% capture %}` blocks and use them here (the capture becomes the excerpt instead of the paragraph text). Inline plugin tags (`{% book_link %}`, `{% author_link %}`, `{% series_text %}`) work fine.
3. **Can use page variables**: `{{ page.title }}`, `{{ page.book_authors }}`, `{{ page.series }}`
4. **Must stand alone**: Should make sense without the rest of the review
5. **No quality verdict**: give the plot premise (new situation, conflict, who's involved), not how good it is — the verdict belongs in paragraph 2. Before drafting P1 options, read the existing P2 so P1 doesn't preempt it (the constraint runs both ways).

Standard opening pattern:
```markdown
{% book_link page.title %}, by {% author_link page.book_authors link=false %},
is [description]. It follows [brief plot/premise].
```

For series:
```markdown
{% book_link page.title %}, by {% author_link page.book_authors link=false %},
is the [Nth] book in {% series_text page.series link=false %}. It [continues/follows]...
```

For multiple authors:
```markdown
<cite class="book-title">{{ page.title }}</cite>, by <span
class="author-name">{{ page.book_authors[0] }}</span> and <span
class="author-name">{{ page.book_authors[1] }}</span>, is ...
```

For siblings (like the Strugatsky brothers):
```markdown
<cite class="book-title">{{ page.title }}</cite>, by brothers <span
class="author-name">{{ page.book_authors[0] | split: " " | first }}</span> and
<span class="author-name">{{ page.book_authors[1] }}</span>, is ...
```

For 3+ authors (anthologies): Don't enumerate all authors in the first paragraph. Describe generically:
```markdown
<cite class="book-title">{{ page.title }}</cite> is the twelfth book in
{% series_text page.series link=false %}. It's an anthology
of Bolo stories written by three different authors.
```

## Capture Blocks

After the first paragraph, define template variables:

```liquid
{% capture this_book %}{% book_link page.title %}{% endcapture %}
{% capture the_author %}{% author_link page.book_authors link=false %}{% endcapture %}

{% capture other_book %}{% book_link "Other Book Title" %}{% endcapture %}
{% capture authors_lastname %}{% author_link "Full Name" link_text="Lastname" possessive %}{% endcapture %}
```

Naming conventions:
- `this_book` --- the book being reviewed
- `the_author` or `the_authors_lastname` --- the author
- Book titles as snake_case: `look_to_windward`, `the_player_of_games`
- Author possessives: `bankss`, `simmonss` (add 's even after s)
- Author lastname: `banks_lastname`, `simmons_lastname`
- Author lastname possessive: `bankss_lastname`

These come from the template in _books/_template/*.md

## Paragraph 2 Transition

The transition from paragraph 1 to paragraph 2 is a prose challenge:

**Problem**: Paragraph 1 gives an overview. The captures come next. Then paragraph 2 continues. Don't just repeat what paragraph 1 said.

**Solutions**:
- Continue a thought from paragraph 1
- Zoom in on a specific aspect
- Introduce the themes you'll discuss
- Start with your reaction/opinion

**Bad** (repetitive):
> P1: "This book follows a soldier named Kassad..."
> P2: "The book is about Kassad, a soldier who..."

**Good** (continues):
> P1: "This book follows a soldier named Kassad..."
> P2: "Kassad's story is military sci-fi at its best, but it's also our first hint that the Hegemony isn't what it seems."

## Paragraph Structure

- **Every sentence must support the paragraph's thesis.** A sentence that's
  actually a dig at a weakness doesn't belong in a paragraph arguing a strength —
  even if it's true.
- **Preserve intentional logical buildup within a sentence.** If the author
  chains ideas (multiple storylines → expands the universe → bigger battles),
  splitting the chain can destroy the rhetorical flow.
- **Avoid vague claims** ("the action is tighter"). Prefer concrete specifics.

## Common Sections

Reviews often include:
- **Themes** --- Analysis of major themes
- **Story** --- Plot discussion, pacing, what worked/didn't
- **Literary References** --- Connections to other works (generates backlinks)
- Per-story sections for anthologies

## Literary Comparisons

The "reminded me" section — typically the last substantive section before the
close. It's a **signature** of these reviews (see `STYLE.md`), so a long one is
fine.

- **Lead in.** Open with a sentence like `{{ this_book }} reminded me of many
  other books.` (or "several others" / "a few others"). Don't jump straight into
  the comparisons.
- **Format varies with content.** Flowing prose for a few tightly-related works;
  a bullet list when collecting many discrete connections.
- **Group by theme, not chronology** — related works share a sentence joined with
  semicolons (e.g. an identity/consciousness cluster; "death when optional"; the
  author's own other work).
- **Digits for numbers:** "3 generations", "9 stories", "20 years."
- **Never close on a bare list** — end on a sentence that states the point.
  Comparisons also get woven into the thematic sections as influence lists; don't
  trim those to hit a count either.

## Backlinks

When you mention another book, author, or series using the link tags, the site generates backlinks. On the referenced work's page, a section appears: "Other reviews that mention this book."

This is intentional and valuable. Comparing works builds a web of connections.

## Ending Pattern

Reviews often end with "what I'm reading next":

```markdown
Up next is {{ bankss }} {{ look_to_windward }} for my book club.
```

This creates a reading journal feel and generates another backlink.
