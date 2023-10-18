---
title: Book Reviews
sidebar_include: true
layout: page
permalink: /books/
description: >
  Alexander Gude's (short) book reviews.
---
{% assign sorted_titles = "" %}

{% for book in site.books %}
  {% assign title = book.title | remove: "The " %}
  {% assign sorted_titles = sorted_titles | append: title | append: "|" %}
{% endfor %}

{% assign sorted_titles = sorted_titles | split: "|" | sort %}

{% for sort_title in sorted_titles %}
  {% for book in site.books %}
    {% assign mod_title = book.title | remove: "The " %}
    {% if mod_title == sort_title %}

      {% assign title = book.title %}
      {% assign first_letter = sort_title | slice: 0 %}

      {% comment %} Don't include this page in the list{% endcomment %}
      {% if title == page.title %}
      {% continue %}
      {% endif %}

      {% if prev_letter != first_letter %}
        {% comment %}
        In order to keep HTML indented, we have to capture and output it.
        Otherwise it has to be shoved up against the left margin.
        {% endcomment %}

<h2 class="book-letter-headline">{{ first_letter }}</h2>

      {% assign prev_letter = first_letter %}
      {% endif %}

<ul>
<li>
      {% include book_link.html title=book.title %}
<br>by {{ book.author }}
      {% include book_rating.html rating=book.rating %}
</li>
</ul>

    {% endif %}
  {% endfor %}
{% endfor %}
