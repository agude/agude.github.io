---
title: "Book Reviews: By Award"
short_title: Award
layout: page
permalink: /books/by-award/
book_topbar_include: true
description: >
  Alexander Gude's (short) book reviews, grouped by awards the books have won.
---

Below you'll find short reviews of the books I've read, grouped by the awards
they've received.

{% include books_topbar.html %}

{% comment %} Gather all unique awards from books {% endcomment %}
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

  {% comment %} Gather books for this award {% endcomment %}
  {% assign award_books = "" | split: "" %}
  {% assign title_map = "" | split: "" %}

  {% for book in site.books %}
    {% if book.awards contains award %}
      {% assign stripped_title = book.title | remove: "The " | remove: "A " | remove: "An " %}
      {% assign key = stripped_title | append: "||" | append: book.title %}
      {% assign title_map = title_map | push: key %}
      {% assign award_books = award_books | push: book %}
    {% endif %}
  {% endfor %}

  {% if award_books == empty %}
    {% continue %}
  {% endif %}

  {% assign sorted_keys = title_map | sort %}

  {% unless first_place %}
</div>
  {% endunless %}
  {% assign first_place = false %}

<h2 class="book-list-headline">{{ award | capitalize }} Award</h2>
<div class="card-grid">

  {% for key in sorted_keys %}
    {% assign parts = key | split: "||" %}
    {% assign original_title = parts[1] %}

    {% for book in award_books %}
      {% if book.title == original_title %}
        {% include book_card.html
          url=book.url
          image=book.image
          title=book.title
          author=book.book_author
          rating=book.rating
          description=book.excerpt
        %}
        {% break %}
      {% endif %}
    {% endfor %}
  {% endfor %}
{% endfor %}
</div>
