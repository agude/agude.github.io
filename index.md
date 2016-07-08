---
layout: default
title: Home
---

# Hi there!

I'm **Alex Gude**, a data scientist with a passion for plots and algorithms,
but also cycling and photography. I'm an [Insight Data Science
alumni](http://insightdatascience.com) and it was through them that I found my
current job at [Lab41](https://lab41.org), an awesome Silicon Valley challenge
lab! In my previous life I was a high energy particle physicist at CERN, and a
cosmologist at Lawrence Berkeley Labs.

I write about whatever catches my attention [here on this site](/blog), and I
write about data science, machine learning, deep learning, and development on
my company's blog, [Gab41](https://gab41.lab41.org/). If you're interested in
my thoughts in real time, follow me on Twitter:
[@Alex_Gude](https://twitter.com/alex_gude).

The code that I write lives on my [Github page](https://github.com/agude);
check it out! Bug reports and pull requests welcome!

## Recent Posts

<ul>
{% for post in site.posts limit:5 %}
    <li><a href="{{ post.url }}">{{ post.title }}</a>
{% endfor %}
</ul>
