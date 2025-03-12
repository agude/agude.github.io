---
title: "Book Reviews: By Award"
short_title: By Award
layout: page
permalink: /books/by-award/
book_topbar_include: true
description: >
  Alexander Gude's (short) book reviews, grouped by awards the books have won.
---

Below you'll find short reviews of books I've read, grouped by the awards they've received.

{% include books_topbar.html %}

{% comment %} Gather all unique awards from all books {% endcomment %}
{% assign all_awards = "" %}
{% for book in site.books %}
  {% if book.awards %}
    {% for award in book.awards %}
      {% assign all_awards = all_awards | append: award | append: "|" %}
    {% endfor %}
  {% endif %}
{% endfor %}
{% assign sorted_awards = all_awards | split: "|" | uniq | sort %}

{% assign first_place = true %}

{% for award in sorted_awards %}
  {% if award == "" %}
    {% continue %}
  {% endif %}

  {% if first_place == false %}
</div>
  {% endif %}
  {% assign first_place = false %}

<h2 class="book-list-headline">{{ award | capitalize }} Award</h2>
<div class="card-grid">

  {% for book in site.books %}
    {% if book.awards contains award %}
      {% include auto_book_card_from_object.html book=book %}
    {% endif %}
  {% endfor %}
{% endfor %}
</div>
