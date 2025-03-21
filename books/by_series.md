---
title: "Book Reviews: By Series"
short_title: Series
layout: page
permalink: /books/by-series/
book_topbar_include: true
description: >
  Alexander Gude's (short) book reviews.
---

Below you'll find short reviews of the books I've read, sorted by series.

{% include books_topbar.html %}

{% comment %}
Sort books by book_number (to keep series books in proper order),
and by title (used for standalones, to ensure a consistent order).
{% endcomment %}
{% assign sorted_books = site.books | sort: 'book_number' %}
{% assign sorted_books_by_title = site.books | sort: 'title' %}

{% comment %}
Build a sorted, unique list of all series names.
Books without a series will be handled separately.
{% endcomment %}
{% assign sorted_series = "" %}

{% for book in site.books %}
  {% assign sorted_series = sorted_series | append: book.series | append: "|" %}
{% endfor %}

{% assign sorted_series = sorted_series | split: "|" | uniq | sort %}

{% comment %}
Flag to know when we've placed our first header, so we don't close a div prematurely.
{% endcomment %}
{% assign placed_first_header = false %}

{% comment %}
First, display all standalone books (books without a series),
grouped under a "Standalone Books" section.
{% endcomment %}
{% for book in sorted_books_by_title %}
  {% if book.series == empty or book.series == null %}
    {% if placed_first_header == false %}
      {% assign placed_first_header = true %}

<h2 class="book-list-headline">Standalone Books</h2>
<div class="card-grid">
    {% endif %}

    {% include auto_book_card_from_object.html book=book %}
  {% endif %}
{% endfor %}

{% comment %}
Now display all books that are part of a series, grouped by series name.
Each group will have a header and a card grid.
{% endcomment %}
{% for sort_series in sorted_series %}
  {% if sort_series == null or sort_series == empty %}
    {% continue %}
  {% endif %}

  {% comment %}
  Close the previous card-grid, if one was opened.
  This includes closing the standalone books section.
  {% endcomment %}
  {% if placed_first_header %}
</div>
  {% endif %}
  {% assign placed_first_header = true %}

<h2 class="book-list-headline">{{ sort_series }}</h2>
<div class="card-grid">

  {% comment %}
  Loop over all books and include the ones that match the current series.
  {% endcomment %}
  {% for book in sorted_books %}
    {% if book.series == sort_series %}
      {% include auto_book_card_from_object.html book=book %}
    {% endif %}
  {% endfor %}
{% endfor %}

{% comment %}Close the final card-grid{% endcomment %}
</div>
