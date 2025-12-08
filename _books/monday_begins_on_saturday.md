---
date: 2025-12-07
title: Monday Begins on Saturday
book_authors:
  - Arkady Strugatsky
  - Boris Strugatsky
book_number: 1
rating: 3
image: /books/covers/monday_begins_on_saturday.jpg
---

<cite class="book-title">{{ page.title }}</cite>, by brothers <span
class="author-name">{{ page.book_authors[0] | split: " " | first }}</span> and
<span class="author-name">{{ page.book_authors[1] }}</span>, is a Soviet
sci-fi novel.

{% capture this_book %}<cite class="book-title">{{ page.title }}</cite>{% endcapture %}
{% capture the_authors %}<span class="author-name">{{ page.book_authors[0] | split: " " | first }}</span> and <span class="author-name">{{ page.book_authors[1] }}</span>{% endcapture %}
{% capture the_authors_first_only %}<span class="author-name">{{ page.book_authors[0] | split: " " | first }}</span> and <span class="author-name">{{ page.book_authors[1] | split: " " | first }}</span>{% endcapture %}
{% capture the_authors_possessive %}<span class="author-name">{{ page.book_authors[0] | split: " " | first }}</span> and <span class="author-name">{{ page.book_authors[1] }}</span>'s{% endcapture %}
