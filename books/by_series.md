---
title: "Book Reviews: By Series"
layout: page
permalink: /books/by-series/
description: >
  Alexander Gude's (short) book reviews.
---

[book_list]: {% link books/index.md %}
[book_list_by_author]: {% link books/by_author.md %}
[book_list_by_series]: {% link books/by_series.md %}
[book_list_by_rating]: {% link books/by_rating.md %}

Below you'll find short reviews of the various books I've read, sorted by
series ([alphabetical][book_list], [author][book_list_by_author],
[rating][book_list_by_rating]):

{% comment %}This sorted list will be used in a double for loop to insure that
books are sorted in their sections{% endcomment %}
{% assign sorted_titles = "" %}

{% for book in site.books %}
  {% assign title = book.title | remove: "The " %}
  {% assign sorted_titles = sorted_titles | append: title | append: "|" %}
{% endfor %}

{% comment %}This sorted list is used to put the <h2> sections in the right
order.{% endcomment %}
{% assign sorted_series = "" %}

{% for book in site.books %}
  {% assign sorted_series = sorted_series | append: book.series | append: "|" %}
{% endfor %}

{% assign sorted_series = sorted_series | split: "|" | uniq | sort %}

{% comment %} We have to place a <div></div> pair between all the <h2>
headlines, but not before the first headline.{% endcomment %}
{% assign first_place = true %}

{% for sort_series in sorted_series %}
  {% if sort_series == null or sort_series == ''%}
    {% continue %}
  {% endif %}

  {% comment %}Close the card-grid{% endcomment %}
  {% if first_place == false %}
</div>
  {% endif %}
  {% assign first_place = false %}

<h2 class="book-list-headline">{{ sort_series }}</h2>
<div class="card-grid">

  {% for book in site.books %}
    {% assign series = book.series %}
    {% if sort_series == series %}

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
