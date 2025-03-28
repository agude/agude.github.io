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

{% assign sorted_books = site.books | sort: "book_number" %}
{% assign sorted_books_by_title = site.books | sort: "title" %}

{% comment %} Generate global series list {% endcomment %}
{% assign sorted_series = "" %}
{% for book in site.books %}
  {% assign sorted_series = sorted_series | append: book.series | append: "|" %}
{% endfor %}
{% assign sorted_series = sorted_series | split: "|" | uniq | sort %}

{% include standalone_books.html books=sorted_books_by_title %}
{% include series_sections.html sorted_series=sorted_series books=sorted_books %}
