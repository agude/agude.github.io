---
date: 2025-07-06
title: The War of the Worlds
book_authors: H. G. Wells
series: null
book_number: 1
rating: 3
image: /books/covers/the_war_of_the_worlds.jpg
---

<cite class="book-title">{{ page.title }}</cite>, by <span
class="author-name">{{ page.book_authors }}</span>, is a landmark science
fiction novel. It takes place in late Victorian England as an unnamed narrator
witnesses a terrifying invasion of Martians with advanced weaponry.

{% capture this_book %}<cite class="book-title">{{ page.title }}</cite>{% endcapture %}
{% capture the_author %}<span class="author-name">{{ page.book_authors }}</span>{% endcapture %}
{% capture the_authors_lastname %}<span class="author-name">{{ page.book_authors | split: " " | last }}</span>{% endcapture %}
{% capture the_authors %}{% author_link page.book_authors possessive %}{% endcapture %}
{% capture the_author_link %}{% author_link page.book_authors %}{% endcapture %}
{% capture this_series %}{% series_text page.series %}{% endcapture %}
