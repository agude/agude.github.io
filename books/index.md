---
title: "Book Reviews"
layout: page
permalink: /books/
description: >
  Alexander Gude's (short) book reviews.
---

[book_list]: {% link books/index.md %}
[book_list_by_author]: {% link books/by_author.md %}
[book_list_by_series]: {% link books/by_series.md %}
[book_list_by_rating]: {% link books/by_rating.md %}

Below you'll find short reviews books I've read, with the most recent reads at
the top.

([alphabetical][book_list], [author][book_list_by_author],
[rating][book_list_by_rating])

{% comment %}This sorted list is used to put the books in series order in each
<h2> heading.{% endcomment %}
{% assign sorted_books = site.books | sort: 'date' | reverse %}
{% assign this_year = null %}
{% assign last_year = null %}

{% comment %} We have to place a <div></div> pair between all the <h2>
headlines, but not before the first headline.{% endcomment %}
{% assign first_place = true %}

{% for book in sorted_books %}

  {% comment %}Get the year from the current book. If it is a new year put
  down a headline and assign last_year.{% endcomment %}

  {% assign this_year = book.date | date: "%Y" %}
  {% if this_year != last_year %}
    {% assign last_year = this_year %}

    {% comment %}Close the card-grid{% endcomment %}
    {% if first_place == false %}
</div>
    {% endif %}
    {% assign first_place = false %}

<h2 class="book-list-headline">{{ this_year }}</h2>
<div class="card-grid">

  {% endif %}

  {% include book_card.html
    url=book.url
    image=book.image
    title=book.title
    author=book.author
    rating=book.rating
    description=book.excerpt
  %}

{% endfor %}
{% comment %}Close the final card-grid{% endcomment %}
</div>
