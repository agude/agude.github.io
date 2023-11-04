---
title: "Book Reviews: By Rating"
layout: page
permalink: /books/by-rating/
description: >
  Alexander Gude's (short) book reviews.
---

[book_list]: {% link books/index.md %}
[book_list_by_author]: {% link books/by_author.md %}
[book_list_by_series]: {% link books/by_series.md %}
[book_list_by_rating]: {% link books/by_rating.md %}

Below you'll find short reviews of the various books I've read, sorted by
series ([alphabetical][book_list], [author][book_list_by_author],
[series][book_list_by_series]):

{% comment %}This sorted list will be used in a double for loop to insure that
books are sorted in their sections{% endcomment %}
{% assign sorted_titles = "" %}

{% for book in site.books %}
  {% assign title = book.title | remove: "The " %}
  {% assign sorted_titles = sorted_titles | append: title | append: "|" %}
{% endfor %}

{% comment %}This sorted list is used to put the <h2> sections in the right
order.{% endcomment %}
{% assign sorted_ratings = "" %}

{% for book in site.books %}
  {% assign sorted_ratings = sorted_ratings | append: book.rating | append: "|" %}
{% endfor %}

{% assign sorted_ratings = sorted_ratings | split: "|" | uniq | sort | reverse %}

{% comment %} We have to place a <div></div> pair between all the <h2>
headlines, but not before the first headline.{% endcomment %}
{% assign first_place = true %}

{% for sort_rating in sorted_ratings %}
  {% if sort_rating == null or sort_rating == ''%}
    {% continue %}
  {% endif %}

  {% comment %}Close the card-grid{% endcomment %}
  {% if first_place == false %}
</div>
  {% endif %}
  {% assign first_place = false %}

  <h2 class="book-list-headline">{% include book_rating.html rating=sort_rating %}</h2>
<div class="card-grid">

  {% for book in site.books %}
    {% comment %}Convert both ratings to quoted strings so they are the same
    type, otherwise the `book.rating` is an int, and the `sort_rating` is an
    unquoted string.{% endcomment %}
    {% capture book_rating %}'{{book.rating}}'{% endcapture %}
    {% capture test_rating %}'{{sort_rating}}'{% endcapture %}

    {% if test_rating == book_rating %}

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
