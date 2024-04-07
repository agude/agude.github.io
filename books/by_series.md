---
title: "Book Reviews: By Series"
short_title: By Series
layout: page
permalink: /books/by-series/
book_topbar_include: true
description: >
  Alexander Gude's (short) book reviews.
---

Below you'll find short reviews of the books I've read, sorted by series.

{% include books_topbar.html %}

{% comment %}This sorted list is used to put the books in series order in each
<h2> heading.{% endcomment %}
{% assign sorted_books = site.books | sort: 'book_number' %}
{% assign sorted_books_by_title = site.books | sort: 'title' %}

{% comment %}This sorted list is used to put the <h2> sections in the right
order.{% endcomment %}
{% assign sorted_series = "" %}

{% for book in site.books %}
  {% assign sorted_series = sorted_series | append: book.series | append: "|" %}
{% endfor %}

{% assign sorted_series = sorted_series | split: "|" | uniq | sort %}

{% comment %} We have to place a <div></div> pair between all the <h2>
headlines, but not before the first headline.{% endcomment %}
{% assign placed_first_header = false %}

{% comment %}Set a first section for books without series.{% endcomment %}
{% for book in sorted_books_by_title %}
  {% if book.series == empty or book.series == null %}
    {% if placed_first_header == false %}
      {% assign placed_first_header = true %}

<h2 class="book-list-headline">Standalone Books</h2>
<div class="card-grid">

    {% endif %}

    {% include book_card.html
      url=book.url
      image=book.image
      title=book.title
      author=book.book_author
      rating=book.rating
      description=book.excerpt
    %}

  {% endif %}
{% endfor %}

{% for sort_series in sorted_series %}
  {% if sort_series == null or sort_series == empty%}
    {% continue %}
  {% endif %}

  {% comment %}Close the previous card-grid{% endcomment %}
  {% if placed_first_header == true %}
</div>
  {% endif %}
  {% assign placed_first_header = true %}

<h2 class="book-list-headline">{{ sort_series }}</h2>
<div class="card-grid">

  {% for book in sorted_books %}
    {% assign series = book.series %}
    {% if sort_series == series %}

      {% include book_card.html
        url=book.url
        image=book.image
        title=book.title
        author=book.book_author
        rating=book.rating
        description=book.excerpt
      %}

    {% endif %}
  {% endfor %}
{% endfor %}
{% comment %}Close the final card-grid{% endcomment %}
</div>
