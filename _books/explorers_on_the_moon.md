---
date: 2025-07-09
title: Explorers on the Moon
book_authors: Hergé
series: The Adventures of Tintin
book_number: 17
rating: 5
image: /books/covers/explorers_on_the_moon.jpg
---

<cite class="book-title">{{ page.title }}</cite>, by <span
class="author-name">{{ page.book_authors }}</span>, is the seventeenth book in
the <span class="book-series">{{ page.series }}</span>. It's the second part of
a two-book story arc where Tintin, Haddock, and Calculus land on the moon.

{% capture this_book %}<cite class="book-title">{{ page.title }}</cite>{% endcapture %}
{% capture the_author %}<span class="author-name">{{ page.book_authors }}</span>{% endcapture %}
{% capture the_authors_lastname %}<span class="author-name">{{ page.book_authors | split: " " | last }}</span>{% endcapture %}
{% capture the_authors %}{% author_link page.book_authors possessive %}{% endcapture %}
{% capture the_author_link %}{% author_link page.book_authors %}{% endcapture %}
{% capture this_series %}{% series_text page.series %}{% endcapture %}

{% capture tt16 %}{% book_link "Destination Moon" %}{% endcapture %}
