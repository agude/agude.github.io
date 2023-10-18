---
title: Book Reviews
sidebar_include: true
layout: page
permalink: /books/
description: >
  Alexander Gude's (short) book reviews.
---
{% assign books = site.books | sort: 'title' %}

{% for book in books %}
  {% assign title = book.title | remove: 'The ' %}
  {% assign first_letter = title | slice: 0 %}

  {% comment %} Don't include this page in the list{% endcomment %}
  {% if title == page.title %}
    {% continue %}
  {% endif %}

  {% comment %}
  We need to consume the spaces before the H2 using `-`, otherwise the HTML
  will be indented and Jekyll will interpret it as a raw block.
  {% endcomment %}
  {% if prev_letter != first_letter -%}
    <h2>{{ first_letter }}</h2>
    {% assign prev_letter = first_letter %}
  {% endif %}

  <ul>
    <li>
      {% include book_link.html title=book.title %}
      <br>by {{ book.author }}
      {% include book_rating.html rating=book.rating %}
    </li>
  </ul>

{% endfor %}
