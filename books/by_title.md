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

{% comment %}This sorted list will be used in a double for loop to insure that
books are sorted in their sections{% endcomment %}
{% assign sorted_titles = "" %}

{% for book in site.books %}
  {% assign title = book.title | remove: "The " %}
  {% assign sorted_titles = sorted_titles | append: title | append: "|" %}
{% endfor %}

{% assign sorted_titles = sorted_titles | split: "|" | sort %}

{% comment %} We have to place a <div></div> pair between all the <h2>
headlines, but not before the first headline.{% endcomment %}
{% assign first_place = true %}

{% for sort_title in sorted_titles %}
  {% for book in site.books %}
    {% assign mod_title = book.title | remove: "The " %}
    {% if mod_title == sort_title %}

      {% assign title = book.title %}
      {% assign first_letter = sort_title | slice: 0 %}

      {% if prev_letter != first_letter %}

        {% comment %}Close the card-grid{% endcomment %}
        {% if first_place == false %}
  </div>
        {% endif %}
        {% assign first_place = false %}

<h2 class="book-list-headline">{{ first_letter }}</h2>
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
{% comment %}Close the final card-grid{% endcomment %}
</div>
