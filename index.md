---
layout: default
title: Home
---

{% assign twitter-name = site.author.twitter %}
{% assign github-name = site.author.github %}

# Hi there!

I'm **Alex Gude**, a data scientist with a passion for plots and algorithms,
but also cycling and photography. I'm an [Insight Data Science
alumni](http://insightdatascience.com) and it was through them that I found my
current job at [Lab41](http://lab41.org), an awesome Silicon Valley challenge
lab! In my previous life I was a high energy particle physicist at CERN, and a
cosmologist at Lawrence Berkeley Labs.

I write about whatever catches my attention [here on this site](/blog), and I
write about data science, machine learning, deep learning, and development on
my company's blog, [Gab41](https://gab41.lab41.org/). If you're interested in
my thoughts in real time, follow me on Twitter:
[@{{ twitter-name }}](https://twitter.com/{{ twitter-name }})

The code that I write lives on my [Github page](https://github.com/{{
github-name }}); check it out! Bug reports and pull requests welcome!

## Recent Posts

<ul>
{% for post in site.posts limit:5 %}
    <li><a href="{{ post.url }}">{{ post.title }}</a></li>
{% endfor %}
</ul>
