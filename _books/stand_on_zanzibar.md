---
date: 2025-03-01
title: Stand on Zanzibar
book_author: John Brunner
series: null
book_number: 1
rating: 2
image: /books/covers/stand_on_zanzibar.jpg
---

<cite class="book-title">{{ page.title }}</cite>, by <span
class="author-name">{{ page.book_author }}</span>, is a science fiction novel
that explores overpopulation, corporate power, and societal collapse.

{% capture this_book %}<cite class="book-title">{{ page.title }}</cite>{% endcapture %}
{% capture the_author %}<span class="author-name">{{ page.book_author }}</span>{% endcapture %}
{% capture the_authors %}{% include author_link.html name=page.book_author possessive=true %}{% endcapture %}
{% capture the_author_link %}{% include author_link.html name=page.book_author %}{% endcapture %}
