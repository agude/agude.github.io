---
date: 2024-09-13
title: The Last Policeman
book_author: Ben H. Winters
series: The Last Policeman
book_number: 1
rating: 4
image: /books/covers/the_last_policeman.jpg
---

<cite class="book-title">{{ page.title }}</cite> by <span
class="author-name">{{ page.book_author }}</span> is in progress.

{% capture this_book %}<cite class="book-title">{{ page.title }}</cite>{% endcapture %}
{% capture the_author %}<span class="author-name">{{ page.book_author }}</span>{% endcapture %}
{% capture series %}<span class="book-series">{{ page.series }}</span>{% endcapture %}
{% capture the_authors %}{% include author_link.html name=page.book_author possessive=true %}{% endcapture %}
