---
title: "Book Reviews: By Author"
short_title: By Author
layout: page
permalink: /books/by-author/
book_topbar_include: true
description: >
  Alexander Gude's (short) book reviews.
---

Below you'll find short reviews of the books I've read, sorted by author.

{% include books_topbar.html %}

{% comment %} These two sorting are so that books under and author headline
are ordered by series, and then book order within the series. Yes it is
horrible. {% endcomment %}
{% assign sorted_series = "" %}
{% for book in site.books %}
  {% assign sorted_series = sorted_series | append: book.series | append: "|" %}
{% endfor %}
{% comment %}Add a blank series to cover books without series (we convert
their null to '' below).{% endcomment %}
{% assign sorted_series = sorted_series | append: '' | append: "|" %}
{% assign sorted_series = sorted_series | split: "|" | uniq | sort %}

{% assign sorted_book_number = "" %}
{% for book in site.books %}
  {% assign sorted_book_number = sorted_book_number | append: book.book_number | append: "|" %}
{% endfor %}
{% assign sorted_book_number = sorted_book_number | split: "|" | uniq | sort %}

{% comment %}This sorted list is used to put the <h2> sections in the right
order.{% endcomment %}
{% assign sorted_authors = "" %}
{% for book in site.books %}
  {% assign sorted_authors = sorted_authors | append: book.book_author | append: "|" %}
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
  {% for sort_series in sorted_series %}
    {% for sort_number in sorted_book_number %}
      {% for book in site.books %}

        {% comment %}Convert both to quoted strings so they are the same
        type.{% endcomment %}
        {% capture test_number %}'{{sort_number}}'{% endcapture %}
        {% capture book_number %}'{{book.book_number}}'{% endcapture %}

        {% if sort_author == book.book_author %}
          {% comment %}Books without series will have null, which we convert
          to '' to match the '' we inserted in the series list above.{% endcomment %}
          {% if book.series == null %}
            {% assign book_series = '' %}
          {% else %}
            {% assign book_series = book.series %}
          {% endif %}
          {% if sort_series == book_series %}
            {% if test_number == book_number %}

              {% include book_card.html
                url=book.url
                image=book.image
                title=book.title
                author=book.book_author
                rating=book.rating
                description=book.excerpt
              %}

            {% endif %}
          {% endif %}
        {% endif %}
      {% endfor %}
    {% endfor %}
  {% endfor %}
{% endfor %}
{% comment %}Close the final card-grid{% endcomment %}
</div>
