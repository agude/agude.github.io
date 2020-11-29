---
layout: page-not-on-sidebar
title: Topics
description: >
  Alex Gude's writings organized by topic.
---

I write on a variety of topics, which can be found below. Click a topic to see
all my articles on it.

<ul>
{% assign sorted_categories = site.categories | sort %}
{% assign categories_list = sorted_categories %}
  {% for category in categories_list %}
    <li><a href="#{{ category[0] }}">{{ category[0] }} ({{ category[1].size }})</a></li>
  {% endfor %}
{% assign categories_list = nil %}
</ul>

## Individual Topics

{% for tag in sorted_categories %}
  <h3 id="{{ tag[0] }}">
    <a href="/topics/{{ tag[0] }}/">{{ tag[0] }}</a>
  </h3>
  <div class="card-grid">
    {% assign pages_list = tag[1] %}
    {% for post in pages_list %}
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
  {% assign pages_list = nil %}
{% endfor %}
