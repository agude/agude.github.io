---
title: "Book Reviews: By Title"
short_title: By Title
layout: page
permalink: /books/by-title/
book_topbar_include: true
description: >
  Alexander Gude's (short) book reviews.
---

Below you'll find short reviews of the books I've read, sorted by title.

{% include books_topbar.html %}

{% comment %}
We create a list of "normalized-title||original-title" entries.
Normalized title is the book title with "The " and "A " removed for more natural sorting.
This allows us to sort by normalized title, but still use the original title to find and display the correct book.
{% endcomment %}
{% assign title_keys = "" | split: "" %}

{% for book in site.books %}
  {% assign normalized_title = book.title | remove: "The " | remove: "A " %}
  {% assign key = normalized_title | append: "||" | append: book.title %}
  {% assign title_keys = title_keys | push: key %}
{% endfor %}

{% comment %}
Sort the combined "normalized||original" title list alphabetically.
This will determine the final display order.
{% endcomment %}
{% assign sorted_keys = title_keys | sort %}

{% comment %}
prev_letter tracks the current first letter of the title group.
first_place helps us avoid rendering a </div> before the first card group.
{% endcomment %}
{% assign prev_letter = "" %}
{% assign first_place = true %}

{% for key in sorted_keys %}
  {% assign parts = key | split: "||" %}
  {% assign sort_title = parts[0] %}
  {% assign original_title = parts[1] %}
  {% assign first_letter = sort_title | slice: 0 %}

  {% comment %}
  If we've reached a new first letter, close the previous grid (unless it's the first),
  render a new header, and open a new card grid container.
  {% endcomment %}
  {% if prev_letter != first_letter %}
    {% unless first_place %}
</div>
    {% endunless %}
    {% assign first_place = false %}

<h2 class="book-list-headline">{{ first_letter }}</h2>
<div class="card-grid">
    {% assign prev_letter = first_letter %}
  {% endif %}

  {% comment %}
  Find the book with the original title and render its card.
  We break after the first match to avoid duplicates or unnecessary looping.
  {% endcomment %}
  {% for book in site.books %}
    {% if book.title == original_title %}
      {% include auto_book_card_from_object.html book=book %}
      {% break %}
    {% endif %}
  {% endfor %}
{% endfor %}

{% comment %}Close the final card-grid{% endcomment %}
</div>
