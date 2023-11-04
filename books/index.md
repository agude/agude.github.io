---
title: Book Reviews
sidebar_include: true
layout: page
permalink: /books/
description: >
  Alexander Gude's (short) book reviews.
---

Below you'll find short reviews of the various books I've read, sorted by
title:

{% assign sorted_titles = "" %}

{% for book in site.books %}
  {% assign title = book.title | remove: "The " %}
  {% assign sorted_titles = sorted_titles | append: title | append: "|" %}
{% endfor %}

{% assign sorted_titles = sorted_titles | split: "|" | sort %}

{% assign first_place = true %}

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

        {% if first_place == false %}
  </div>
        {% endif %}
        {% assign first_place = false %}
        

<h2 class="book-letter-headline">{{ first_letter }}</h2>
<div class="card-grid">
      {% assign prev_letter = first_letter %}
      {% endif %}

{% include book_card.html
  url=book.url
  image=book.image
  title=book.title
  author=book.author
  rating=book.rating
  description=book.excerpt
%}

    {% endif %}
  {% endfor %}
{% endfor %}
</div>
