---
date: 2024-09-23
title: World of Trouble
book_author: Ben H. Winters
series: The Last Policeman
book_number: 3
rating: 3
image: /books/covers/world_of_trouble.jpg
---

<cite class="book-title">{{ page.title }}</cite> by <span
class="author-name">{{ page.book_author }}</span> is in progress.

{% capture this_book %}<cite class="book-title">{{ page.title }}</cite>{% endcapture %}
{% capture the_author %}<span class="author-name">{{ page.book_author }}</span>{% endcapture %}
{% capture series %}<span class="book-series">{{ page.series }}</span>{% endcapture %}
{% capture the_authors %}{% include author_link.html name=page.book_author possessive=true %}{% endcapture %}
