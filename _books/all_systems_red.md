---
date: 2025-05-17
title: All Systems Red
book_author: Martha Wells
series: The Murderbot Diaries
book_number: 1
rating: 4
image: /books/covers/all_systems_red.jpg
awards:
  - hugo
  - locus
  - nebula
---

<cite class="book-title">{{ page.title }}</cite>, by <span
class="author-name">{{ page.book_author }}</span>, is the first book in the
<span class="book-series">{{ page.series }}</span>.

{% capture this_book %}<cite class="book-title">{{ page.title }}</cite>{% endcapture %}
{% capture the_author %}<span class="author-name">{{ page.book_author }}</span>{% endcapture %}
{% capture the_authors_lastname %}<span class="author-name">{{ page.book_author | split: " " | last }}</span>{% endcapture %}
{% capture the_authors %}{% author_link page.book_author possessive %}{% endcapture %}
{% capture the_author_link %}{% author_link page.book_author %}{% endcapture %}
{% capture this_series %}{% series_text page.series %}{% endcapture %}

{% capture mb1 %}{% book_link "All Systems Red" %}{% endcapture %}
{% capture mb2 %}{% book_link "Artificial Condition" %}{% endcapture %}
{% capture mb3 %}{% book_link "Rogue Protocol" %}{% endcapture %}
{% capture mb4 %}{% book_link "Exit Strategy" %}{% endcapture %}
{% capture mb5 %}{% book_link "Network Effect" %}{% endcapture %}
{% capture mb6 %}{% book_link "Fugitive Telemetry" %}{% endcapture %}
{% capture mb7 %}{% book_link "System Collapse" %}{% endcapture %}
