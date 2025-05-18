---
date: 2025-05-16
title: City on Fire
book_author: Walter Jon Williams
series: Metropolitan
book_number: 2
rating: 4
image: /books/covers/city_on_fire.jpg
---

<cite class="book-title">{{ page.title }}</cite>, by <span
class="author-name">{{ page.book_author }}</span>, is the second book in the
<span class="book-series">{{ page.series }}</span> series.

{% capture this_book %}<cite class="book-title">{{ page.title }}</cite>{% endcapture %}
{% capture the_author %}<span class="author-name">{{ page.book_author }}</span>{% endcapture %}
{% capture the_authors_lastname %}<span class="author-name">{{ page.book_author | split: " " | last }}</span>{% endcapture %}
{% capture the_authors %}{% author_link page.book_author possessive %}{% endcapture %}
{% capture the_author_link %}{% author_link page.book_author %}{% endcapture %}
{% capture this_series %}{% series_text page.series %}{% endcapture %}

{% capture m1 %}{% book_link "Metropolitan" %}{% endcapture %}
{% capture m3 %}{% book_link "Heaven in Flames" %}{% endcapture %}

{% capture drop %}{% book_link "A Drop of Corruption" %}{% endcapture %}

{{ this_book }} is the middle-book in an as-of-yet unwritten trilogy.

The strongest part of {{ this_series }} is the world building, the giant city,
the tech-like-magic. And so like {{ drop }}, this book suffers a bit compared
the first book in the series because you can only step into a brand-new world
once.

In someways this book and {{ m1 }} before it---written almost 30 years
ago---feel very modern: the main charters are people of color, there are gay
characters who are, and there are women in roles
normally reserved for men. The focus of the books, on how systems---the
companies, governments, and the shield itself---

The halfworlds.
...


But in other ways they {{ this_series }} is solidly rooted in a 90's
neoliberalism and interventionism. The first reform Constantine applies in
Caraqui is selling off the government run industries to make them more
efficient, lowering barriers to trade, and simplifying the tax code as if he
had just taken over a former soviet state in Eastern Europe. The way to
achieve freedom and keep it is violence and making hard-choices.
