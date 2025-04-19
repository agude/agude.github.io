---
date: 2025-04-18
title: Martin the Warrior
book_author: Brian Jacques
series: Redwall
book_number: 6
rating: 4
image: /books/covers/martin_the_warrior.jpg
---

<cite class="book-title">{{ page.title }}</cite> is the sixth book in the
<span class="book-series">{{ page.series }}</span> series.

{% capture this_book %}<cite class="book-title">{{ page.title }}</cite>{% endcapture %}
{% capture the_author %}<span class="author-name">{{ page.book_author }}</span>{% endcapture %}
{% capture series %}<span class="book-series">{{ page.series }}</span> series{% endcapture %}

{% capture mattimeo %}{% include book_link.html title="Mattimeo"%}{% endcapture %}
{% capture mariel %}{% include book_link.html title="Mariel of Redwall"%}{% endcapture %}

{% capture redwall_series %}{% include series_link.html series="Redwall" %}{% endcapture %}
