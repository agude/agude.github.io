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
  Collect and sort book titles for this rating.
  {% endcomment %}
  {% assign rating_titles = "" | split: "" %}
  {% for book in site.books %}
    {% capture r1 %}{{ book.rating }}{% endcapture %}
    {% capture r2 %}{{ sort_rating }}{% endcapture %}
    {% if r1 == r2 %}
      {% assign normalized = book.title | remove: "The " | remove: "A " %}
      {% assign key = normalized | append: "||" | append: book.title %}
      {% assign rating_titles = rating_titles | push: key %}
    {% endif %}
  {% endfor %}

  {% if rating_titles == empty %}
    {% continue %}
  {% endif %}

  {% assign sorted_keys = rating_titles | sort %}

  {% unless first_place %}
</div>
  {% endunless %}
  {% assign first_place = false %}

<h2 class="book-list-headline">{% include book_rating.html rating=sort_rating %}</h2>
<div class="card-grid">

  {% for key in sorted_keys %}
    {% assign parts = key | split: "||" %}
    {% assign original_title = parts[1] %}
    {% include auto_book_card.html title=original_title %}
  {% endfor %}
{% endfor %}
</div>
