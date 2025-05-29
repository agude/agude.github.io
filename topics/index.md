---
layout: page-not-on-sidebar
title: Topics
hide_lead_image: True
description: >
  Alex Gude's writings organized by topic.
---

I write on a variety of topics, which can be found below. Click a topic to see
all my articles on it.

{% assign sorted_categories = site.categories | sort %}

<ul>
{% for category_pair in sorted_categories %}
  {% assign category_name = category_pair[0] %}
  {% assign posts_in_category = category_pair[1] %}

  {% comment %}
    Only list category in TOC if it actually has posts.
    `site.categories[category_name].size` should reflect published posts by default.
  {% endcomment %}

  {% if posts_in_category.size > 0 %}
  <li><a href="#{{ category_name | slugify }}"><span class="post-tag">#{{ category_name }}</span> ({{ posts_in_category.size }})</a></li>
  {% endif %}
{% endfor %}
</ul>

## Individual Topics

{% for category_pair in sorted_categories %}
  {% assign category_name = category_pair[0] %}
  {% assign posts_in_category = category_pair[1] %}

  {% comment %}
    Only display the category section if it has posts.
    The display_category_posts tag will internally handle cases
    where a category might exist but have no published posts after its own filtering.
    However, it's good practice to only generate the H3 if there's a likelihood of content.
    The `posts_in_category.size > 0` check here is based on Jekyll's default population
    of site.categories, which should be published posts.
  {% endcomment %}

  {% if posts_in_category.size > 0 %}
  <h3 id="{{ category_name | slugify }}">
    <a href="/topics/{{ category_name | slugify }}/">
      <span class="post-tag">#{{ category_name }}</span>
    </a>
  </h3>
  {% display_category_posts topic=category_name %}
  {% endif %}
{% endfor %}
