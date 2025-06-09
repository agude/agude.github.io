---
date: 2025-06-09
title: Eyes of the Void
book_authors: Adrian Tchaikovsky
series: The Final Architecture
book_number: 2
rating: null
image: /books/covers/eyes_of_the_void.jpg
---

<cite class="book-title">{{ page.title }}</cite>, by <span
class="author-name">{{ page.book_authors }}</span>, is the second book in the
<span class="book-series">{{ page.series }}</span> series.

{% capture this_book %}<cite class="book-title">{{ page.title }}</cite>{% endcapture %}
{% capture the_author %}<span class="author-name">{{ page.book_authors }}</span>{% endcapture %}
{% capture the_authors_lastname %}<span class="author-name">{{ page.book_authors | split: " " | last }}</span>{% endcapture %}
{% capture the_authors %}{% author_link page.book_authors possessive %}{% endcapture %}
{% capture the_author_link %}{% author_link page.book_authors %}{% endcapture %}
{% capture this_series %}{% series_text page.series %}{% endcapture %}

{% capture fa1 %}{% book_link "Shards of Earth" %}{% endcapture %}
{% capture fa2 %}{% book_link "Eyes of the Void" %}{% endcapture %}
{% capture fa3 %}{% book_link "Lords of Uncreation" %}{% endcapture %}
