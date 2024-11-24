---
date: 2024-11-29
title: Surface Detail
book_author: Iain M. Banks
series: Culture
book_number: 9
rating: null
image: /books/covers/surface_detail.jpg
---

<cite class="book-title">{{ page.title }}</cite>, by <span
class="author-name">{{ page.book_author }}</span>, is the ninth <span
class="book-series">{{ page.series }}</span> book. 

{% capture this_book %}<cite class="book-title">{{ page.title }}</cite>{% endcapture %}
{% capture the_author %}<span class="author-name">{{ page.book_author }}</span>{% endcapture %}
{% capture series %}<span class="book-series">{{ page.series }}</span>{% endcapture %}
{% capture the_authors %}{% include author_link.html name=page.book_author possessive=true %}{% endcapture %}
{% capture this_series %}{% include series_link.html series=page.series %} series{% endcapture %}

{% capture c1 %}{% include book_link.html title="Consider Phlebas" %}{% endcapture %}
{% capture c2 %}{% include book_link.html title="The Player of Games" %}{% endcapture %}
{% capture c3 %}{% include book_link.html title="Use of Weapons" %}{% endcapture %}
{% capture c5 %}{% include book_link.html title="Excession" %}{% endcapture %}
{% capture c6 %}{% include book_link.html title="Inversions" %}{% endcapture %}
{% capture c7 %}{% include book_link.html title="Look to Windward" %}{% endcapture %}
{% capture c8 %}{% include book_link.html title="Matter" %}{% endcapture %}

{% capture virtual_heaven %}{% include book_link.html title="The Diamond Age" %}{% endcapture %}
{% capture the_inferno %}{% include book_link.html title="Inferno" %}{% endcapture %}
{% capture justice %}{% include book_link.html title="The Dispossessed" %}{% endcapture %}
