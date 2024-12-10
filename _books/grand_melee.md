---
date: 2024-12-09
title: Grand Melee
book_author: Scott Warren
series: War Horses
book_number: 5
rating: 4
image: /books/covers/grand_melee.jpg
---

<cite class="book-title">{{ page.title }}</cite>, by <span
class="author-name">{{ page.book_author }}</span>, is the fifth book in the
<span class="book-series">{{ page.series }}</span> series.

{% capture this_book %}<cite class="book-title">{{ page.title }}</cite>{% endcapture %}
{% capture the_author %}<span class="author-name">{{ page.book_author }}</span>{% endcapture %}
{% capture series %}<span class="book-series">{{ page.series }}</span>{% endcapture %}

{% capture w1 %}{% include book_link.html title="Chevalier" %}{% endcapture %}
{% capture w2 %}{% include book_link.html title="Ymir" %}{% endcapture %}
{% capture w3 %}{% include book_link.html title="Serpent Valley" %}{% endcapture %}
{% capture w4 %}{% include book_link.html title="Dog Soldier" %}{% endcapture %}
