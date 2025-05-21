---
date: 2025-05-18
title: Artificial Condition
book_author: Martha Wells
series: The Murderbot Diaries
book_number: 2
rating: 5
image: /books/covers/artificial_condition.jpg
---

<cite class="book-title">{{ page.title }}</cite>, by <span
class="author-name">{{ page.book_author }}</span>, is the second book in the
<span class="book-series">{{ page.series }}</span>. It follows Murderbot as it
explores its past and saves some more scientists.

{% capture this_book %}<cite class="book-title">{{ page.title }}</cite>{% endcapture %}
{% capture the_author %}<span class="author-name">{{ page.book_author }}</span>{% endcapture %}
{% capture the_authors_lastname %}<span class="author-name">{{ page.book_author | split: " " | last }}</span>{% endcapture %}
{% capture the_authors %}{% author_link page.book_author possessive %}{% endcapture %}
{% capture the_author_link %}{% author_link page.book_author %}{% endcapture %}
{% capture this_series %}{% series_text page.series %}{% endcapture %}

{% capture mb1 %}{% book_link "All Systems Red" %}{% endcapture %}
{% capture mb3 %}{% book_link "Rogue Protocol" %}{% endcapture %}

{% capture drop %}{% book_link "A Drop of Corruption" %}{% endcapture %}

{% capture city %}{% book_link "City on Fire" %}{% endcapture %}

{% capture ludlums %}{% author_link "Robert Ludlum" %}{% endcapture %}
{% capture bourne %}{% book_link "The Bourne Identity" %}{% endcapture %}

{{ this_book }} felt like the story moved a lot fast, with a better blending
of the action and exposition. In it, Murderbot arrives at a mining station,
gets hired as a security consultant by some researchers, saves their lives
twice, investigates the massacre it supposedly caused, saves the researchers
again, and kills the bad guys. And it makes friends with really smart and
really bored asshole research transport (ART).

I appreciate how {{ the_authors_lastname }} is slowly expanding the universe
of {{ this_series }}. It allows her to balance world building with plot and
helps avoid some the problem where exploring the setting is so exciting in the
first book but tapers off in the sequel, a problem {{ drop }} and {{ city }}
ran into.

One of the things I love in stories is watching competent characters operate
in their area of expertise, and {{ this_book }} excels there: Murderbot keeps
beating the bad guys because it is just better at security and violence than
they are. It's the same excitement I get from {{ ludlums }} {{ bourne }}. ART
likewise fills this role, being extremely good at hacking and research, and
acts as a good foil for Murderbot.

I really loved {{ this_book }}, more then {{ mb1 }} because of the better
pacing and new characters. I'm starting {{ mb3 }} right away!
