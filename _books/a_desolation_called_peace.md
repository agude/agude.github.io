---
date: 2025-04-05
title: A Desolation Called Peace
book_author: Arkady Martine
series: Teixcalaan
book_number: 2
rating: 5
image: /books/covers/a_desolation_called_peace.jpg
awards:
  - hugo
---

<cite class="book-title">{{ page.title }}</cite>, by <span
class="author-name">{{ page.book_author }}</span>, is the second book in the
<span class="book-series">{{ page.series }}</span> series.

{% capture this_book %}<cite class="book-title">{{ page.title }}</cite>{% endcapture %}
{% capture the_author %}<span class="author-name">{{ page.book_author }}</span>{% endcapture %}
{% capture the_authors %}{% include author_link.html name=page.book_author possessive=true %}{% endcapture %}
{% capture this_series %}{% include series_link.html series=page.series %} series{% endcapture %}
{% capture the_author_link %}{% include author_link.html name=page.book_author %}{% endcapture %}

{% capture teix1 %}{% include book_link.html title="A Memory Called Empire" %}{% endcapture %}
