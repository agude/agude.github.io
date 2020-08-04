---
layout: page
title: Lab41 Posts
description: >
  All of the articles written by Alex Gude for Lab41's blog on Deep Learning,
  Machine Learning, and Data Science.
sidebar_include: false
---

I worked at Lab41 from 2015 and 2017. Part of my job was to write articles for
our blog, [**Gab41 blog**][gab41]. I covered some of the projects I worked on,
but my favorite and most popular posts were for the **reading group series**
where I reviewed some key papers in deep learning.

[gab41]: https://gab41.lab41.org/

Lab41 has kindly given me permission to host the articles here. You can find
them below:

<div class="card-grid">
  {% for post in site.categories.lab41 %}
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
