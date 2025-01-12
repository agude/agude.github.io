---
date: 2025-01-12
title: Clay's Ark
book_author: Octavia E. Butler
series: Patternist
book_number: 3
rating: 3
image: /books/covers/clays_ark.jpg
---

<cite class="book-title">{{ page.title }}</cite>, by <span
class="author-name">{{ page.book_author }}</span>, is the third book in the
<span class="book-series">{{ page.series }}</span> series. It tells the origin
story of the Patternists.

{% capture this_book %}<cite class="book-title">{{ page.title }}</cite>{% endcapture %}
{% capture the_author %}<span class="author-name">{{ page.book_author }}</span>{% endcapture %}
{% capture series %}<span class="book-series">{{ page.series }}</span>{% endcapture %}

{% capture p1 %}{% include book_link.html title="Wild Seed" %}{% endcapture %}
{% capture p2 %}{% include book_link.html title="Mind of My Mind" %}{% endcapture %}
{% capture p4 %}{% include book_link.html title="Patternmaster" %}{% endcapture %}
