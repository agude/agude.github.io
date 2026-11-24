---
title: 'The "Future" & Golden Edge — café'
date: 2099-01-02 09:00:00 -0800
excerpt: ""
categories: [golden-edge]
hide_lead_image: true
book_authors: [Edge Author]
ranked_list: []
---

This future post exercises content that is not part of a normal production build.

## Liquid tags

{% article_card_lookup "/blog/no-golden-edge-post/" %}
{% author_link "Edge Author" link_text="the Edge Author" possessive %}
{% author_link "Missing Golden Author" link_text="a missing author" possessive %}
{% book_backlinks %}
{% book_card_lookup "Golden Future Review" %}
{% book_link "Golden Future Review" link_text="the future review" author="Edge Author" cite=false %}
{% book_link "Missing Golden Book" link_text="a missing book" cite=false %}
{% citation author_first="Ada" author_last="Lovelace" work_title="Notes" date="1843" %}
{% citedquote author_last="Lovelace" work_title="Notes" %}A short attributed quotation.{% endcitedquote %}
{% display_all_books_grouped %}
{% display_authors page.book_authors %}
{% display_awards_page %}
{% display_books_by_author "Edge Author" %}
{% display_books_by_author_then_series %}
{% display_books_by_title_alpha_group %}
{% display_books_by_year %}
{% display_books_for_series "Golden Edge Series" %}
{% display_category_posts topic="golden-edge" %}
{% display_previous_reviews %}
{% display_ranked_books page.ranked_list %}
{% display_ranked_by_backlinks %}
{% display_unreviewed_mentions %}
{% front_page_feed limit=2 %}
{% game_title "Elden Ring" %}
{% llms_txt_index %}
{% movie_title "The Matrix" %}
{% rating_stars 4 %}
{% related_books %}
{% related_posts %}
{% render_article_card page %}
{% render_book_awards %}
{% resume_experience company="Golden Books" location="Remote" position="Test Author" dates="2099" %}
{% resume_skills languages="Ruby, Python" tools="Jekyll, Liquid" %}
{% series_link "Golden Edge Series" link_text="the numbered series" %}
{% series_link "Missing Golden Series" link_text="a missing series" %}
{% series_text "Golden Edge Series" %}
{% short_story_link "Golden Thread" from_book="Golden Anthology" %}
{% short_story_link "Missing Golden Story" %}
{% short_story_title "Golden Thread" no_id %}
{% subtitle "Golden test subtitle" %}
{% tv_show_title "The Wire" %}
{% units number="37" unit="C" %}

## Markdown edge cases

- A nested list item
  - A deeper item with a fenced block:

    ```python
    print("nested fence")
    ```

<div markdown="1">

This raw HTML block contains **Markdown** and a nested list:

1. First item
2. Second item

</div>

A footnote has a preview[^preview], and a reference link points to [the edge reference][edge-reference].

| Input          | Expected path         |
| -------------- | --------------------- |
| Future content | Rendered with EDGES=1 |
| Normal build   | Omitted               |

Inline math is $$x^2 + y^2 = z^2$$.

[^preview]: A footnote with a preview of {% book_link "Golden Future Review" %}.

[edge-reference]: https://example.org/golden-edge-reference
