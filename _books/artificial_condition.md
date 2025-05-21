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
<span class="book-series">{{ page.series }}</span>.

{% capture this_book %}<cite class="book-title">{{ page.title }}</cite>{% endcapture %}
{% capture the_author %}<span class="author-name">{{ page.book_author }}</span>{% endcapture %}
{% capture the_authors_lastname %}<span class="author-name">{{ page.book_author | split: " " | last }}</span>{% endcapture %}
{% capture the_authors %}{% author_link page.book_author possessive %}{% endcapture %}
{% capture the_author_link %}{% author_link page.book_author %}{% endcapture %}

{% capture mb1 %}{% book_link "All Systems Red" %}{% endcapture %}
{% capture mb2 %}{% book_link "Artificial Condition" %}{% endcapture %}
{% capture mb3 %}{% book_link "Rogue Protocol" %}{% endcapture %}
{% capture mb4 %}{% book_link "Exit Strategy" %}{% endcapture %}
{% capture mb5 %}{% book_link "Network Effect" %}{% endcapture %}
{% capture mb6 %}{% book_link "Fugitive Telemetry" %}{% endcapture %}
{% capture mb7 %}{% book_link "System Collapse" %}{% endcapture %}

{% capture ludlums %}{% author_link "Robert Ludlum" %}{% endcapture %}
{% capture bourne %}{% book_link "The Bourne Identity" %}{% endcapture %}

{{ this_book }} felt a lot faster, with a better blending of the action and
exposition. Murderbot arrives at a mining station, gets hired as a security
consultant by some researchers, saves their lives twice, investigates the
massacre it supposedly caused, saves the researchers again, and kills the bad
guys. And it makes friends with really smart and really bored asshole research
transport (ART).

goes to explore its past, meets some out-of-their-depth
researchers, and murders some badguys while saving the good guys. The slow
expansion of the setting, of Murderbot's history, and the introduction of new
characters helps keep the stories fresh.

One of the things I love in stories is watching competent characters operate
in their area of expertise, and {{ this_book }} excels there: Murderbot keeps
beating the bad guys because it is just better at security and violence than
they are. It's the same excitement I get from {{ ludlums }} {{ bourne }}.
