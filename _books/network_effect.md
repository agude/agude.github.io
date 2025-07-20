---
date: 2025-07-17
title: Network Effect
book_authors: Martha Wells
series: The Murderbot Diaries
book_number: 5
rating: 5
image: /books/covers/network_effect.jpg
---

<cite class="book-title">{{ page.title }}</cite>, by <span
class="author-name">{{ page.book_authors }}</span>, is the fifth book in the
<span class="book-series">{{ page.series }}</span>.

{% capture this_book %}<cite class="book-title">{{ page.title }}</cite>{% endcapture %}
{% capture the_author %}<span class="author-name">{{ page.book_authors }}</span>{% endcapture %}
{% capture the_authors_lastname %}<span class="author-name">{{ page.book_authors | split: " " | last }}</span>{% endcapture %}
{% capture the_authors %}{% author_link page.book_authors possessive %}{% endcapture %}
{% capture the_author_link %}{% author_link page.book_authors %}{% endcapture %}
{% capture this_series %}{% series_text page.series %}{% endcapture %}

{% capture mb1 %}{% book_link "All Systems Red" %}{% endcapture %}
{% capture mb2 %}{% book_link "Artificial Condition" %}{% endcapture %}
{% capture mb3 %}{% book_link "Rogue Protocol" %}{% endcapture %}
{% capture mb4 %}{% book_link "Exit Strategy" %}{% endcapture %}
{% capture mb4_5 %}{% book_link "Home: Habitat, Range, Niche, Territory" %}{% endcapture %}
{% capture mb5 %}{% book_link "Network Effect" %}{% endcapture %}
{% capture mb6 %}{% book_link "Fugitive Telemetry" %}{% endcapture %}
{% capture mb7 %}{% book_link "System Collapse" %}{% endcapture %}

{% capture brunner %}{% author_link "John Brunner" %}{% endcapture %}
{% capture zanzibar %}{% book_link "Stand on Zanzibar" %}{% endcapture %}

{{ this_book }} brings back the best non-Murderbot character from the GrayCris
story: ART, the asshole research transport, first seen in {{ mb2 }}. The power
fantasy is toned-down a little---instead of being able to deal with anything,
ART has been taken over and needs help.

- The `HelpMe.file` used to tell a parallel story reminds me of how {{
  brunner }} builds the world with various in-world media in {{ zanzibar }}.
