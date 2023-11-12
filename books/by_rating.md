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

{% assign sorted_titles = "" %}

{% for book in site.books %}
  {% assign title = book.title | remove: "The " %}
  {% assign sorted_titles = sorted_titles | append: title | append: "|" %}
{% endfor %}
{% assign sorted_titles = sorted_titles | split: "|" | sort %}

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

  {% comment %}To get each section to show up in alphabetical order, we have
  to do a double for loop. We could probably get away with sorting site.books
  if we weren't dropping "The " from the title.{% endcomment %}
  {% for sort_title in sorted_titles %}
    {% for book in site.books %}
      {% assign mod_title = book.title | remove: "The " %}

      {% comment %}Convert both ratings to quoted strings so they are the same
      type, otherwise the `book.rating` is an int, and the `sort_rating` is an
      unquoted string.{% endcomment %}
      {% capture book_rating %}'{{book.rating}}'{% endcapture %}
      {% capture test_rating %}'{{sort_rating}}'{% endcapture %}

      {% if test_rating == book_rating and mod_title == sort_title %}

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
{% endfor %}
{% comment %}Close the final card-grid{% endcomment %}
</div>
