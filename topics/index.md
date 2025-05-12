---
layout: page-not-on-sidebar
title: Topics
hide_lead_image: True
description: >
  Alex Gude's writings organized by topic.
---

I write on a variety of topics, which can be found below. Click a topic to see
all my articles on it.

<ul>
{% assign sorted_categories = site.categories | sort %}
{% assign categories_list = sorted_categories %}
  {% for category in categories_list %}
    <li><a href="#{{ category[0] }}"><span class="post-tag">#{{category[0]}}</span> ({{ category[1].size }})</a></li>
  {% endfor %}
{% assign categories_list = nil %}
</ul>

## Individual Topics

{% for tag in sorted_categories %}
  <h3 id="{{ tag[0] }}">
    <a href="/topics/{{ tag[0] }}/">
      <span class="post-tag">#{{ tag[0] }}</span>
    </a>
  </h3>
  <div class="card-grid">
    {% assign pages_list = tag[1] %}
    {% for post in pages_list %}
      {% comment %} Article cards with an image and description. {% endcomment %}
      {% render_article_card post %}
    {% endfor %}
  </div>
  {% assign pages_list = nil %}
{% endfor %}
