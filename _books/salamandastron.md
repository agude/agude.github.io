---
date: 2024-10-27
title: Salamandastron
book_author: Brian Jacques
series: Redwall
book_number: 5
rating: null
image: /books/covers/salamandastron.jpg
---

<cite class="book-title">{{ page.title }}</cite> is the fifth book in the
<span class="book-series">{{ page.series }}</span> series.

{% capture this_book %}<cite class="book-title">{{ page.title }}</cite>{% endcapture %}
{% capture the_author %}<span class="author-name">{{ page.book_author }}</span>{% endcapture %}
{% capture series %}<span class="book-series">{{ page.series }}</span> series{% endcapture %}
{% capture bellmaker %}{% include book_link.html title="The Bellmaker"%}{% endcapture %}
{% capture salamandstron %}{% include book_link.html title="Salamandastron"%}{% endcapture %}
{% capture redwall %}{% include book_link.html title="Redwall"%}{% endcapture %}
{% capture redwall_series %}{% include series_link.html series="Redwall" %}{% endcapture %}
