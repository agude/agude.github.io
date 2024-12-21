---
date: 2024-12-21
title: Mind of My Mind
book_author: Octavia E. Butler
series: Patternist
book_number: 2
rating: null
image: /books/covers/mind_of_my_mind.jpg
---

<cite class="book-title">{{ page.title }}</cite>, by <span
class="author-name">{{ page.book_author }}</span>, is the second book in the
<span class="book-series">{{ page.series }}</span> series.

{% capture this_book %}<cite class="book-title">{{ page.title }}</cite>{% endcapture %}
{% capture the_author %}<span class="author-name">{{ page.book_author }}</span>{% endcapture %}
{% capture series %}<span class="book-series">{{ page.series }}</span>{% endcapture %}

{% capture p1 %}{% include book_link.html title="Wild Seed" %}{% endcapture %}
{% capture p3 %}{% include book_link.html title="Clay's Ark" %}{% endcapture %}
{% capture this_authors %}{% include author_link.html name=page.book_author link_text="Butler" possessive=true %}{% endcapture %}
