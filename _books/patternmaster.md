---
date: 2025-01-16
title: Patternmaster
book_author: Octavia E. Butler
series: Patternist
book_number: 4
rating: 4
image: /books/covers/patternmaster.jpg
---

<cite class="book-title">{{ page.title }}</cite>, by <span
class="author-name">{{ page.book_author }}</span>, is the third book in the
<span class="book-series">{{ page.series }}</span> series.

{% capture this_book %}<cite class="book-title">{{ page.title }}</cite>{% endcapture %}
{% capture the_author %}<span class="author-name">{{ page.book_author }}</span>{% endcapture %}
{% capture series %}<span class="book-series">{{ page.series }}</span>{% endcapture %}

{% capture p1 %}{% include book_link.html title="Wild Seed" %}{% endcapture %}
{% capture p2 %}{% include book_link.html title="Mind of My Mind" %}{% endcapture %}
{% capture p3 %}{% include book_link.html title="Clay's Ark" %}{% endcapture %}
