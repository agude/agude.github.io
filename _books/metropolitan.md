---
date: 2025-04-28
title: Metropolitan
book_author: Walter Jon Williams
series: Metropolitan
book_number: 1
rating: 4
image: /books/covers/metropolitan.jpg
---

<cite class="book-title">{{ page.title }}</cite>, by <span
class="author-name">{{ page.book_author }}</span>, is the first <span
class="book-series">{{ page.series }}</span> book.

{% capture this_book %}<cite class="book-title">{{ page.title }}</cite>{% endcapture %}
{% capture the_author %}<span class="author-name">{{ page.book_author }}</span>{% endcapture %}
{% capture the_authors_lastname %}<span class="author-name">{{ page.book_author | split: " " | last }}</span>{% endcapture %}
{% capture the_authors %}{% include author_link.html name=page.book_author possessive=true %}{% endcapture %}
{% capture the_author_link %}{% include author_link.html name=page.book_author %}{% endcapture %}
