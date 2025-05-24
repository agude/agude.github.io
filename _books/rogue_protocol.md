---
date: 2025-05-21
title: Rogue Protocol
book_author: Martha Wells
series: The Murderbot Diaries
book_number: 3
rating: 5
image: /books/covers/rogue_protocol.jpg
---

<cite class="book-title">{{ page.title }}</cite>, by <span
class="author-name">{{ page.book_author }}</span>, is the third book in the
<span class="book-series">{{ page.series }}</span>. It follows Murderbot as it
investigates a GrayCris terraforming station and, you guessed it, ends up
saving a group of humans.

{% capture this_book %}<cite class="book-title">{{ page.title }}</cite>{% endcapture %}
{% capture the_author %}<span class="author-name">{{ page.book_author }}</span>{% endcapture %}
{% capture the_authors_lastname %}<span class="author-name">{{ page.book_author | split: " " | last }}</span>{% endcapture %}
{% capture the_authors %}{% author_link page.book_author possessive %}{% endcapture %}
{% capture the_author_link %}{% author_link page.book_author %}{% endcapture %}
{% capture this_series %}{% series_text page.series %}{% endcapture %}

{% capture mb2 %}{% book_link "Artificial Condition" %}{% endcapture %}
{% capture mb4 %}{% book_link "Exit Strategy" %}{% endcapture %}

{% capture wattss %}{% author_link "Peter Watts" possessive %}{% endcapture %}
{% capture blindsight %}{% book_link "Blindsight" %}{% endcapture %}

Like {{ mb2 }}, {{ this_book }} strikes a great balance between action and
exposition. Murderbot stows away aboard a ship carrying a salvage team to the
GrayCris station, only to find out they've brought along their own human
security. The SecUnit has to hide from them while trying to dig up proof that
the station is actually an illegal alien-relic mining site.

The primary theme of this story is Murderbot's evolving relationship with
humans, and what it actually wants from those interactions. This plays out
through Miki---the "pet" robot that accompanies the group---and Murderbot's mix of
horror and jealousy at how the humans treat Miki as a friend and colleague. It
also comes through in how Murderbot has to work with the human security
consultants, who are less competent at basically everything.

{{ this_book }} feels like a pop version of {{ wattss }} {{ blindsight }}. The
floating, abandoned station in the clouds is like Rorschach above Big Ben:
both apparently empty, but full of non-sentient threats. Both stories tackle
themes around the self and the mind. But {{ blindsight }} is much darker and
digs much deeper into consciousness, while this book keeps things light and
packed with action.

I once again enjoyed watching the hyper-competent Murderbot navigate danger
and save the humans. Onward to {{ mb4 }}.
