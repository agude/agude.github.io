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
2. **No custom plugin tags**: Cannot use `{% book_link %}`, `{% author_link %}`, etc.
3. **Can use page variables**: `{{ page.title }}`, `{{ page.book_authors }}`, `{{ page.series }}`
4. **Must stand alone**: Should make sense without the rest of the review

Standard opening pattern:
```markdown
<cite class="book-title">{{ page.title }}</cite>, by <span
class="author-name">{{ page.book_authors }}</span>, is [description]. It follows
[brief plot/premise].
```

For series:
```markdown
<cite class="book-title">{{ page.title }}</cite> is the [Nth] book in the
<span class="book-series">{{ page.series }}</span>. It [continues/follows]...
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
<cite class="book-title">{{ page.title }}</cite> is the twelfth book in the
<span class="book-series">{{ page.series }}</span> series. It's an anthology
of Bolo stories written by three different authors.
```

## Capture Blocks

After the first paragraph, define template variables:

```liquid
{% capture this_book %}<cite class="book-title">{{ page.title }}</cite>{% endcapture %}
{% capture the_author %}<span class="author-name">{{ page.book_authors }}</span>{% endcapture %}

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

## Common Sections

Reviews often include:
- **Themes** --- Analysis of major themes
- **Story** --- Plot discussion, pacing, what worked/didn't
- **Literary References** --- Connections to other works (generates backlinks)
- Per-story sections for anthologies

## Backlinks

When you mention another book, author, or series using the link tags, the site generates backlinks. On the referenced work's page, a section appears: "Other reviews that mention this book."

This is intentional and valuable. Comparing works builds a web of connections.

## Ending Pattern

Reviews often end with "what I'm reading next":

```markdown
Up next is {{ bankss }} {{ look_to_windward }} for my book club.
```

This creates a reading journal feel and generates another backlink.
