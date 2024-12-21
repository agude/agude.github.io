---
date: 2024-12-20
title: Wild Seed
book_author: Octavia E. Butler
series: Patternist
book_number: 1
rating: 4
image: /books/covers/wild_seed.jpg
---

<cite class="book-title">{{ page.title }}</cite>, by <span
class="author-name">{{ page.book_author }}</span>, is the first book
chronologically in the <span class="book-series">{{ page.series }}</span>
series, though it was the fourth to be published.

{% capture this_book %}<cite class="book-title">{{ page.title }}</cite>{% endcapture %}
{% capture the_author %}<span class="author-name">{{ page.book_author }}</span>{% endcapture %}
{% capture series %}<span class="book-series">{{ page.series }}</span>{% endcapture %}

{% capture p2 %}{% include book_link.html title="Mind of My Mind" %}{% endcapture %}
{% capture p3 %}{% include book_link.html title="Clay's Ark" %}{% endcapture %}
{% capture p4 %}{% include book_link.html title="Patternmaster" %}{% endcapture %}
{% capture survivor %}{% include book_link.html title="Survivor" %}{% endcapture %}
