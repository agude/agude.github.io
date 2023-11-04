---
title: Book Reviews
layout: page
permalink: /books/by-series/
description: >
  Alexander Gude's (short) book reviews.
---

Below you'll find short reviews of the various books I've read, sorted by
series:

{% assign sorted_titles = "" %}

{% for book in site.books %}
  {% assign title = book.title | remove: "The " %}
  {% assign sorted_titles = sorted_titles | append: title | append: "|" %}
{% endfor %}

{% assign sorted_series = "" %}

{% for book in site.books %}
  {% assign sorted_series = sorted_series | append: book.series | append: "|" %}
{% endfor %}

{% assign sorted_series = sorted_series | split: "|" | uniq | sort %}

{% for sort_series in sorted_series %}
<h2 class="book-series-headline">{{ sort_series }}</h2>
  {% for book in site.books %}
    {% assign series = book.series %}
    {% if sort_series == series %}

      {% assign title = book.title %}

      {% comment %} Don't include this page in the list{% endcomment %}
      {% if title == page.title %}
        {% continue %}
      {% endif %}

<ul>
<li>
      {% include book_link.html title=book.title %}
<br>
<span clas="by-author">
by
<span clas="author-name">
    {{ book.author }}
</span>
</span>
      {% include book_rating.html rating=book.rating %}
</li>
</ul>

    {% endif %}
  {% endfor %}
{% endfor %}
