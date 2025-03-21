---
title: "Book Reviews: By Rating"
short_title: By Rating
layout: page
permalink: /books/by-rating/
book_topbar_include: true
description: >
  Alexander Gude's (short) book reviews.
---

Below you'll find short reviews of the books I've read, sorted by rating.

{% include books_topbar.html %}

{% comment %}
Build sorted list of unique ratings, highest to lowest.
{% endcomment %}
{% assign all_ratings = "" %}
{% for book in site.books %}
  {% assign all_ratings = all_ratings | append: book.rating | append: "|" %}
{% endfor %}
{% assign sorted_ratings = all_ratings | split: "|" | uniq | sort | reverse %}

{% assign first_place = true %}

{% for sort_rating in sorted_ratings %}
  {% if sort_rating == null or sort_rating == "" %}
    {% continue %}
  {% endif %}

  {% comment %}
  Get books that match this rating.
  {% endcomment %}
  {% assign rating_books = "" | split: "" %}
  {% assign title_keys = "" | split: "" %}

  {% for book in site.books %}
    {% capture book_rating %}{{ book.rating }}{% endcapture %}
    {% capture expected_rating %}{{ sort_rating }}{% endcapture %}
    {% if book_rating == expected_rating %}
      {% assign rating_books = rating_books | push: book %}
      {% assign normalized = book.title | remove: "The " | remove: "A " %}
      {% assign key = normalized | append: "||" | append: book.title %}
      {% assign title_keys = title_keys | push: key %}
    {% endif %}
  {% endfor %}

  {% if rating_books == empty %}
    {% continue %}
  {% endif %}

  {% assign sorted_keys = title_keys | sort %}

  {% unless first_place %}
  </div>
  {% endunless %}
  {% assign first_place = false %}

  <h2 class="book-list-headline">{% include book_rating.html rating=sort_rating %}</h2>
  <div class="card-grid">

  {% for key in sorted_keys %}
    {% assign parts = key | split: "||" %}
    {% assign original_title = parts[1] %}

    {% for book in rating_books %}
      {% if book.title == original_title %}
        {% include auto_book_card_from_object.html book=book %}
        {% break %}
      {% endif %}
    {% endfor %}
  {% endfor %}
{% endfor %}
</div>
