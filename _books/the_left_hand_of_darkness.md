---
date: 2024-11-14
title: The Left Hand of Darkness
book_author: Ursula K. Le Guin
series: Hainish Cycle
book_number: 4
rating: 5
image: /books/covers/the_left_hand_of_darkness.jpg
---

<cite class="book-title">{{ page.title }}</cite>, by <span
class="author-name">{{ page.book_author }}</span>, is part of the <span
class="book-series">{{ page.series }}</span>. It follows Genly Ai, an envoy
from the Ekumen, as he attempts to bring the androgynous world of Winter into
an interstellar civilization, exploring themes of gender, politics, and human
connection through his relationship with the enigmatic Gethenian, Estraven.

{% capture this_book %}<cite class="book-title">{{ page.title }}</cite>{% endcapture %}
{% capture the_author %}<span class="author-name">{{ page.book_author }}</span>{% endcapture %}
{% capture series %}<span class="book-series">{{ page.series }}</span>{% endcapture %}

{% capture the_authors %}{% include author_link.html name=page.book_author possessive=true %}{% endcapture %}
{% capture this_series %}{% include series_link.html series=page.series %} series{% endcapture %}
