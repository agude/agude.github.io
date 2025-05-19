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
<span class="book-series">{{ page.series }}</span>. It introduces us to
Murderbot as it saves a team of scientists.

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

{% capture laumers %}{% author_link "Keith Laumer" possessive %}{% endcapture %}
{% capture bolo_series %}{% series_link "Bolo" %} series{% endcapture %}

{{ this_book }} is a fun, quick read. Murderbot is relatable: it is depressed,
anxious, and just wants to binge-watch TV but has a (boring) job it has to do
first. It doesn't like being around people, but it also feels a need to
protect them.

{{ this_book }} reminded me the most of {{ laumers }} {{ bolo_series }}. Both
star intelligent weapon systems that are in some ways more human than their
human companions. Both deal with themes of duty and purpose. Murderbot is
different from the Dinochrome bridgade tanks in one clear manner: it chooses
to be loyal and honorable, whereas Bolos have that enforced through their
programing.
