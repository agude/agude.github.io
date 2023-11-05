---
title: Book Reviews
sidebar_include: true
layout: page
permalink: /books/
description: >
  Alexander Gude's (short) book reviews.
---

[book_list]: {% link books/index.md %}
[book_list_by_author]: {% link books/by_author.md %}
[book_list_by_series]: {% link books/by_series.md %}
[book_list_by_rating]: {% link books/by_rating.md %}

Below you'll find short reviews of the various books I've read, sorted by
title ([author][book_list_by_author], [rating][book_list_by_rating],
[series][book_list_by_series]):

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
