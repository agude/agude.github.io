---
date: 2026-02-21 12:57:55 -0800
title: Sunstone Imperative
book_authors: Scott Warren
series: War Horses
book_number: 6
rating: 4
image: /books/covers/sunstone_imperative.jpg
---

<cite class="book-title">{{ page.title }}</cite>, by <span
class="author-name">{{ page.book_authors }}</span>, is the sixth book in the
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

{% capture w1 %}{% book_link "Chevalier" %}{% endcapture %}
{% capture w2 %}{% book_link "Ymir" %}{% endcapture %}
{% capture w3 %}{% book_link "Serpent Valley" %}{% endcapture %}
{% capture w4 %}{% book_link "Dog Soldier" %}{% endcapture %}
{% capture w5 %}{% book_link "Grand Melee" %}{% endcapture %}
