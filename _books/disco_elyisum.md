---
date: 2025-07-03
title: Disco Elysium
book_authors: Robert Kurvitz
series: Elysium
book_number: 2
rating: 5
image: /books/covers/disco_elysium.jpg
---

<cite class="video-game-title">{{ page.title }}</cite>, written by <span
class="author-name">{{ page.book_authors }}</span>, is a role-playing game
produced by ZA/UM.

{% capture this_book %}<cite class="book-title">{{ page.title }}</cite>{% endcapture %}
{% capture the_author %}<span class="author-name">{{ page.book_authors }}</span>{% endcapture %}
{% capture the_authors_lastname %}<span class="author-name">{{ page.book_authors | split: " " | last }}</span>{% endcapture %}
{% capture the_authors %}{% author_link page.book_authors possessive %}{% endcapture %}
{% capture the_author_link %}{% author_link page.book_authors %}{% endcapture %}
{% capture this_series %}{% series_text page.series %}{% endcapture %}
