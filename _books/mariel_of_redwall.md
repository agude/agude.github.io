---
date: 2024-08-16
title: Mariel of Redwall
book_author: Brian Jacques
series: Redwall
book_number: 4
rating: null
image: /books/covers/mariel_of_redwall.jpg
---

<cite class="book-title">{{ page.title }}</cite> is the forth book in the
<span class="book-series">{{ page.series }}</span> series.

{% capture this_book %}<cite class="book-title">{{ page.title }}</cite>{% endcapture %}
{% capture the_author %}<span class="author-name">{{ page.book_author }}</span>{% endcapture %}
{% capture series %}<span class="book-series">{{ page.series }}</span> series{% endcapture %}
{% capture redwall %}{% include book_link.html title="Redwall"%}{% endcapture %}
{% capture mossflower %}{% include book_link.html title="Mossflower"%}{% endcapture %}
{% capture mattimeo %}{% include book_link.html title="Mattimeo"%}{% endcapture %}
{% capture redwall_series %}{% include series_link.html series="Redwall" %}{% endcapture %}
