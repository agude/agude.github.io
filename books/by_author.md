---
title: "Book Reviews: By Author"
short_title: Author
layout: page
permalink: /books/by-author/
book_topbar_include: true
description: >
  Alexander Gude's (short) book reviews.
---

Below you'll find short reviews of the books I've read, sorted by author.

{% include books_topbar.html %}

{% comment %}
We need to organize books under each author, first by series, and then by book number within the series.
We use three primary lists to handle the sorting: series, book numbers, and authors.
{% endcomment %}

{% comment %}
Create a list of unique series names. Books without a series will be represented as an empty string.
{% endcomment %}
{% assign sorted_series = "" %}
{% for book in site.books %}
  {% assign sorted_series = sorted_series | append: book.series | append: "|" %}
{% endfor %}
{% assign sorted_series = sorted_series | append: "" | append: "|" %}
{% assign sorted_series = sorted_series | split: "|" | uniq | sort %}

{% comment %}
Create a list of unique book numbers for proper sorting within a series.
{% endcomment %}
{% assign sorted_book_number = "" %}
{% for book in site.books %}
  {% assign sorted_book_number = sorted_book_number | append: book.book_number | append: "|" %}
{% endfor %}
{% assign sorted_book_number = sorted_book_number | split: "|" | uniq | sort %}

{% comment %}
Create a list of unique authors to display them in alphabetical order.
{% endcomment %}
{% assign sorted_authors = "" %}
{% for book in site.books %}
  {% assign sorted_authors = sorted_authors | append: book.book_author | append: "|" %}
{% endfor %}
{% assign sorted_authors = sorted_authors | split: "|" | uniq | sort %}

{% comment %}
Use the `first_place` flag to track if we are placing the first author heading.
We will manage the opening/closing of card grids based on this flag.
{% endcomment %}
{% assign first_place = true %}

{% comment %}
Iterate through the sorted authors to display them along with their books,
sorted by series and book number.
{% endcomment %}
{% for sort_author in sorted_authors %}
  {% if sort_author == null or sort_author == "" %}
    {% continue %}
  {% endif %}

  {% comment %}
  Close the previous card-grid if it's not the first author section.
  {% endcomment %}
  {% if first_place == false %}
</div>
  {% endif %}
  {% assign first_place = false %}

<h2 class="book-list-headline">{{ sort_author }}</h2>
<div class="card-grid">

  {% comment %}
  To display the books under the author's name, we loop through each series
  and each book number. The double-loop ensures books are shown in the correct order
  according to their series and number.
  {% endcomment %}
  {% for sort_series in sorted_series %}
    {% for sort_number in sorted_book_number %}
      {% for book in site.books %}

        {% comment %}
        Compare the series and book number to correctly order the books.
        Convert both series and book numbers to quoted strings to ensure consistent comparison.
        {% endcomment %}
        {% capture test_number %}'{{sort_number}}'{% endcapture %}
        {% capture book_number %}'{{book.book_number}}'{% endcapture %}

        {% if sort_author == book.book_author %}
          {% comment %}
          Handle books with no series. If the series is null, treat it as an empty string for comparison.
          {% endcomment %}
          {% if book.series == null %}
            {% assign book_series = '' %}
          {% else %}
            {% assign book_series = book.series %}
          {% endif %}

          {% comment %}
          If the current book matches the series and book number, include its card in the grid.
          {% endcomment %}
          {% if sort_series == book_series %}
            {% if test_number == book_number %}
              {% render_book_card book %}
            {% endif %}
          {% endif %}
        {% endif %}
      {% endfor %}
    {% endfor %}
  {% endfor %}
{% endfor %}

{% comment %}
Close the final card-grid after all authors and their books are displayed.
{% endcomment %}
</div>
