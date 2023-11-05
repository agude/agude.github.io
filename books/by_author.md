---
title: "Book Reviews: By Author"
layout: page
permalink: /books/by-author/
description: >
  Alexander Gude's (short) book reviews.
---

[book_list]: {% link books/index.md %}
[book_list_by_author]: {% link books/by_author.md %}
[book_list_by_series]: {% link books/by_series.md %}
[book_list_by_rating]: {% link books/by_rating.md %}

Below you'll find short reviews of the various books I've read, sorted by
author ([alphabetical][book_list], [rating][book_list_by_rating],
[series][book_list_by_series]):

{% assign sorted_titles = "" %}

{% for book in site.books %}
  {% assign title = book.title | remove: "The " %}
  {% assign sorted_titles = sorted_titles | append: title | append: "|" %}
{% endfor %}
{% assign sorted_titles = sorted_titles | split: "|" | sort %}

{% comment %}This sorted list is used to put the <h2> sections in the right
order.{% endcomment %}
{% assign sorted_authors = "" %}

{% for book in site.books %}
  {% assign sorted_authors = sorted_authors | append: book.author | append: "|" %}
{% endfor %}

{% assign sorted_authors = sorted_authors | split: "|" | uniq | sort %}

{% comment %} We have to place a <div></div> pair between all the <h2>
headlines, but not before the first headline.{% endcomment %}
{% assign first_place = true %}

{% for sort_author in sorted_authors %}
  {% if sort_author == null or sort_author == ''%}
    {% continue %}
  {% endif %}

  {% comment %}Close the card-grid{% endcomment %}
  {% if first_place == false %}
</div>
  {% endif %}
  {% assign first_place = false %}

<h2 class="book-list-headline">{{ sort_author }}</h2>
<div class="card-grid">

  {% comment %}To get each section to show up in alphabetical order, we have
  to do a double for loop. We could probably get away with sorting site.books
  if we weren't dropping "The " from the title.{% endcomment %}
  {% for sort_title in sorted_titles %}
    {% for book in site.books %}
      {% assign mod_title = book.title | remove: "The " %}
      {% assign author = book.author %}

      {% if sort_author == author and sort_title == mode_title %}

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
