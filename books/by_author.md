---
title: Book Reviews
layout: page
permalink: /books/by-author/
description: >
  Alexander Gude's (short) book reviews.
---

Below you'll find short reviews of the various books I've read, sorted by
author:

{% assign sorted_titles = "" %}

{% for book in site.books %}
  {% assign title = book.title | remove: "The " %}
  {% assign sorted_titles = sorted_titles | append: title | append: "|" %}
{% endfor %}

{% assign sorted_authors = "" %}

{% for book in site.books %}
  {% assign sorted_authors = sorted_authors | append: book.author | append: "|" %}
{% endfor %}

{% assign sorted_authors = sorted_authors | split: "|" | uniq | sort %}

{% for sort_author in sorted_authors %}
  {% if sort_author == null or sort_author == ''%}
    {% continue %}
  {% endif %}

  {% if first_place == false %}
</div>
  {% endif %}
  {% assign first_place = false %}

<h2 class="book-author-headline">{{ sort_author }}</h2>
<div class="card-grid">

  {% for book in site.books %}
    {% assign author = book.author %}

    {% if sort_author == author %}

      {% assign title = book.title %}

      {% comment %} Don't include this page in the list{% endcomment %}
      {% if title == page.title %}
        {% continue %}
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
