---
layout: default
title: Home
---

# Hi there!

I'm **Alex Gude**, a data scientist with a passion for plots, but also cycling
and photography. I'm an [Insight Data Science
alumni](http://insightdatascience.com) through whom I found my current job at
an awesome Silicon Valley challenge lab. In my previous
life I was a high energy particle physicist at CERN, and a cosmologist at
Lawrence Berkeley Labs.

You can find my thoughts about random subjects [here on my blog](/blog). The
code that I write lives on my [Github page](https://github.com/agude).

## Recent Posts

<ul>
{% for post in site.posts limit:5 %}
    <li><a href="{{ post.url }}">{{ post.title }}</a>
{% endfor %}
</ul>
