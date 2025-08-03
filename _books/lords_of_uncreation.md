---
date: 2025-07-31
title: Lords of Uncreation
book_authors: Adrian Tchaikovsky
series: The Final Architecture
book_number: 3
rating: 3
image: /books/covers/lords_of_uncreation.jpg
---

<cite class="book-title">{{ page.title }}</cite>, by <span
class="author-name">{{ page.book_authors }}</span>, is the third book in the
<span class="book-series">{{ page.series }}</span> series.

{% capture this_book %}<cite class="book-title">{{ page.title }}</cite>{% endcapture %}
{% capture the_author %}<span class="author-name">{{ page.book_authors }}</span>{% endcapture %}
{% capture the_authors %}<span class="author-name">{{ page.book_authors }}</span>'s{% endcapture %}
{% capture author_last_name_text %}{{ page.book_authors | split: " " | last }}{% endcapture %}
{% capture the_authors_lastname %}<span class="author-name">{{ page.book_authors | split: " " | last }}</span>{% endcapture %}
{% capture the_authors_lastname_possessive %}<span class="author-name">{{ page.book_authors | split: " " | last }}</span>'s{% endcapture %}
{% capture the_author_link %}{% author_link page.book_authors %}{% endcapture %}
{% capture the_authors_link %}{% author_link page.book_authors possessive %}{% endcapture %}
{% capture the_authors_lastname_link %}{% author_link page.book_authors link_text=author_last_name_text %}{% endcapture %}
{% capture the_authors_lastname_possessive_link %}{% author_link page.book_authors link_text=author_last_name_text possessive %}{% endcapture %}
{% capture this_series %}{% series_text page.series %}{% endcapture %}

{% capture fa1 %}{% book_link "Shards of Earth" %}{% endcapture %}
{% capture fa2 %}{% book_link "Eyes of the Void" %}{% endcapture %}

{% capture judas %}{% book_link "Judas Unchained" %}{% endcapture %}
{% capture ender %}{% book_link "Ender's Game" %}{% endcapture %}
{% capture speaker %}{% book_link "Speaker for the Dead" %}{% endcapture %}
{% capture borg %}<cite class="tv-show-title">Star Trek</cite>'s <cite class="tv-show-title">I, Borg</cite>{% endcapture %}

{{ this_book }} was my favorite of the trilogy, beating out {{ fa1 }} and {{
fa2 }}, because it focuses more on the story. I'm also become more accepting
of the characters and their flaws---even Olli did not annoy me as much as she
normally does. The writing has improved enough that it didn't keep dragging me
out of the narrative, although the repetition is still there.

That said the book is far from perfect. The first third is restarting the
human civil war. At this point in the trilogy I'm ready for the minor villains
to get their due and for the heroes to finally confront the Progenators, so
the civil war feels like filler. Idris is a lot more whiny than usual, arguing
against genociding the Architects. It's the same, failed, argument made in 
