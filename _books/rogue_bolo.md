---
date: 2025-06-07
title: "Rogue Bolo"
book_authors: Keith Laumer
series: Bolo
book_number: 2
rating: null
image: /books/covers/rogue_bolo.jpg
---

<cite class="book-title">{{ page.title }}</cite>, by <span
class="author-name">{{ page.book_authors }}</span>, is the second book in the
<span class="book-series">{{ page.series }}</span> series. It is a collection
of two novellas featuring the sentient tanks.

{% capture this_book %}<cite class="book-title">{{ page.title }}</cite>{% endcapture %}
{% capture the_author %}<span class="author-name">{{ page.book_authors }}</span>{% endcapture %}
{% capture the_authors_lastname %}<span class="author-name">{{ page.book_authors | split: " " | last }}</span>{% endcapture %}
{% capture the_authors %}{% author_link page.book_authors possessive %}{% endcapture %}
{% capture the_author_link %}{% author_link page.book_authors %}{% endcapture %}
{% capture this_series %}{% series_text page.series %}{% endcapture %}

{% capture bolo1 %}{% book_link "Bolo: Annals of the Dinochrome Brigade" %}{% endcapture %}
{% capture bolo2 %}{% book_link "Rogue Bolo" %}{% endcapture %}
{% capture bolo3 %}{% book_link "The Stars Must Wait" %}{% endcapture %}
{% capture bolo4 %}{% book_link "Bolo Brigade" %}{% endcapture %}
{% capture bolo5 %}{% book_link "Bolo Rising" %}{% endcapture %}
{% capture bolo6 %}{% book_link "Bolo Strike" %}{% endcapture %}
{% capture bolo7 %}{% book_link "The Road to Damascus" %}{% endcapture %}
{% capture bolo8 %}{% book_link "Bolo!" %}{% endcapture %}
{% capture bolo9 %}{% book_link "Old Soldiers" %}{% endcapture %}
{% capture bolo10 %}{% book_link "Honor of the Regiment" %}{% endcapture %}
{% capture bolo11 %}{% book_link "The Unconquerable" %}{% endcapture %}
{% capture bolo12 %}{% book_link "The Triumphant" %}{% endcapture %}
{% capture bolo13 %}{% book_link "Last Stand" %}{% endcapture %}
{% capture bolo14 %}{% book_link "Old Guard" %}{% endcapture %}
{% capture bolo15 %}{% book_link "Cold Steel" %}{% endcapture %}
