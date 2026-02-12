# Plugin Reference

Liquid tags available for book reviews on alexgude.com.

## Source of Truth

The plugin source code lives in `_plugins/src/`. For full details on any tag, read the source:

- `_plugins/src/content/books/tags/` --- book_link, related tags
- `_plugins/src/content/authors/tags/` --- author_link
- `_plugins/src/content/series/tags/` --- series_link, series_text
- `_plugins/src/content/short_stories/tags/` --- short_story_link, short_story_title
- `_plugins/src/ui/tags/` --- citation, citedquote, rating_stars

Use the **plugin-navigator** skill to navigate between plugins and their tests:
- `.claude/skills/plugin-navigator/scripts/test-for-plugin` --- find tests for a plugin
- `.claude/skills/plugin-navigator/scripts/plugin-for-test` --- find plugin for a test
- `.claude/skills/plugin-navigator/scripts/coverage-stats` --- see test coverage

## Quick Reference

The examples below cover common usage. Check the source files for all options.

## Book Links

```liquid
{% book_link "Book Title" %}
{% book_link "Book Title" link_text="custom text" %}
{% book_link "Book Title" author="Author Name" %}  # disambiguate same titles
{% book_link "Book Title" cite=false %}  # no <cite> wrapper
```

Output: `<cite class="book-title"><a href="...">Book Title</a></cite>`

## Author Links

```liquid
{% author_link "Full Name" %}
{% author_link "Full Name" possessive %}  # adds 's
{% author_link "Full Name" link_text="Lastname" %}
{% author_link "Full Name" link_text="Lastname" possessive %}
```

Examples:
- `{% author_link "Iain M. Banks" %}` → Iain M. Banks (linked)
- `{% author_link "Iain M. Banks" possessive %}` → Iain M. Banks's
- `{% author_link "Iain M. Banks" link_text="Banks" %}` → Banks (linked)
- `{% author_link "Iain M. Banks" link_text="Banks" possessive %}` → Banks's

## Series Links

```liquid
{% series_link "Series Name" %}
{% series_link "Series Name" link_text="the series" %}
```

Output: `<span class="book-series"><a href="...">Series Name</a></span>`

## Short Story Links

```liquid
{% short_story_link "Story Title" %}
{% short_story_link "Story Title" from_book="Anthology Name" %}  # disambiguate
```

## Short Story Titles (no link)

```liquid
{% short_story_title "Story Title" %}
```

Output: `<cite class="short-story-title">Story Title</cite>`

## Rating Stars

```liquid
{% rating_stars 4 %}
```

Used in anthology reviews to rate individual stories.

## Citations

For inline citations:

```liquid
{% citation
  author_first="John"
  author_last="Doe"
  work_title="Article Title"
  container_title="Journal Name"
  date="2024"
  url="https://example.com"
%}
```

## Cited Quotes

For block quotes with attribution:

```liquid
{% citedquote
  author_first="John"
  author_last="Keats"
  work_title="Hyperion"
  date="1820"
  url="https://example.com"
%}
"None can usurp this height," returned that shade,
"But those to whom the miseries of the world
Are misery, and will not let them rest."
{% endcitedquote %}
```

## Capture Blocks

Standard Liquid, not a custom plugin. Used to define reusable variables:

```liquid
{% capture varname %}content here{% endcapture %}
```

Then use as `{{ varname }}` in the text.

## Common Capture Patterns

```liquid
# The current book
{% capture this_book %}<cite class="book-title">{{ page.title }}</cite>{% endcapture %}

# The author (various forms)
{% capture the_author %}<span class="author-name">{{ page.book_authors }}</span>{% endcapture %}
{% capture the_authors_lastname %}<span class="author-name">{{ page.book_authors | split: " " | last }}</span>{% endcapture %}
{% capture the_authors_lastname_possessive %}<span class="author-name">{{ page.book_authors | split: " " | last }}</span>'s{% endcapture %}

# Other books
{% capture other_book %}{% book_link "Other Book" %}{% endcapture %}

# Other authors (possessive lastname is common)
{% capture bankss %}{% author_link "Iain M. Banks" possessive %}{% endcapture %}
{% capture banks_lastname %}{% author_link "Iain M. Banks" link_text="Banks" %}{% endcapture %}
{% capture bankss_lastname %}{% author_link "Iain M. Banks" link_text="Banks" possessive %}{% endcapture %}

# Series
{% capture culture %}{% series_link "Culture" %}{% endcapture %}
```

## Important Notes

1. **Preserve tags exactly**: When editing, do not modify Liquid tags
2. **Spacing matters**: `{{ varname }}` not `{{varname}}`
3. **Quotes**: Use double quotes for tag arguments
4. **No tags in first paragraph**: Custom plugin tags cannot appear before capture definitions
