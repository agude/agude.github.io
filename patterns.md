---
layout: page
title: Python Patterns
description: >
  A list of articles written by Alex Gude about Python.
---

{% assign current_date = 'now' | date: '%Y' %}
{% assign years = current_date | minus: 2005 %}

Python is my favorite language, and I have been writing it professionally for
{{ years }} year. Even though I have used it for so long, I keep improving and
learning new tricks, both for Python and coding in general.

A share some of things I have learned in blog posts, shown below:

<div class="card-grid">
  {% for post in site.categories.python_patterns %}
    {% comment %} Article cards with an image and description. {% endcomment %}
    {% include article_card.html
      url=post.url
      image=post.image
      image_alt=post.image_alt
      title=post.title
      description=post.description
    %}
  {% endfor %}
</div>
