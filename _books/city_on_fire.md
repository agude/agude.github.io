---
date: 2025-05-16
title: City on Fire
book_author: Walter Jon Williams
series: Metropolitan
book_number: 2
rating: 4
image: /books/covers/city_on_fire.jpg
---

<cite class="book-title">{{ page.title }}</cite>, by <span
class="author-name">{{ page.book_author }}</span>, is the second book in the
<span class="book-series">{{ page.series }}</span> series.

{% capture this_book %}<cite class="book-title">{{ page.title }}</cite>{% endcapture %}
{% capture the_author %}<span class="author-name">{{ page.book_author }}</span>{% endcapture %}
{% capture the_authors_lastname %}<span class="author-name">{{ page.book_author | split: " " | last }}</span>{% endcapture %}
{% capture the_authors %}{% author_link page.book_author possessive %}{% endcapture %}
{% capture the_author_link %}{% author_link page.book_author %}{% endcapture %}

{% capture m1 %}{% book_link "Metropolitan" %}{% endcapture %}
{% capture m3 %}{% book_link "Heaven in Flames" %}{% endcapture %}
