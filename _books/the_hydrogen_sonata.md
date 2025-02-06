---
date: 2025-02-06
title: The Hydrogen Sonata
book_author: Iain M. Banks
series: Culture
book_number: 10
rating: null
image: /books/covers/the_hydrogen_sonata.jpg
---

<cite class="book-title">{{ page.title }}</cite>, by <span
class="author-name">{{ page.book_author }}</span>, is the tenth and final <span
class="book-series">{{ page.series }}</span> book.

{% capture this_book %}<cite class="book-title">{{ page.title }}</cite>{% endcapture %}
{% capture the_author %}<span class="author-name">{{ page.book_author }}</span>{% endcapture %}
{% capture series %}<span class="book-series">{{ page.series }}</span>{% endcapture %}
{% capture the_authors %}{% include author_link.html name=page.book_author possessive=true %}{% endcapture %}
{% capture this_series %}{% include series_link.html series=page.series %} series{% endcapture %}
{% capture culture %}{% include series_link.html series=page.series %}{% endcapture %}
{% capture banks %}<span class="author-name">Banks</span>{% endcapture %}

{% capture c1 %}{% include book_link.html title="Consider Phlebas" %}{% endcapture %}
{% capture c2 %}{% include book_link.html title="The Player of Games" %}{% endcapture %}
{% capture c3 %}{% include book_link.html title="Use of Weapons" %}{% endcapture %}
{% capture c4 %}{% include book_link.html title="The State of the Art" %}{% endcapture %}
{% capture c5 %}{% include book_link.html title="Excession" %}{% endcapture %}
{% capture c6 %}{% include book_link.html title="Inversions" %}{% endcapture %}
{% capture c7 %}{% include book_link.html title="Look to Windward" %}{% endcapture %}
{% capture c8 %}{% include book_link.html title="Matter" %}{% endcapture %}
{% capture c9 %}{% include book_link.html title="Surface Detail" %}{% endcapture %}
