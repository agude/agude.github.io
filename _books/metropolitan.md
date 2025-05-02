---
date: 2025-04-28
title: Metropolitan
book_author: Walter Jon Williams
series: Metropolitan
book_number: 1
rating: 4
image: /books/covers/metropolitan.jpg
---

<cite class="book-title">{{ page.title }}</cite>, by <span
class="author-name">{{ page.book_author }}</span>, is the first <span
class="book-series">{{ page.series }}</span> book.


{% capture this_book %}<cite class="book-title">{{ page.title }}</cite>{% endcapture %}
{% capture the_author %}<span class="author-name">{{ page.book_author }}</span>{% endcapture %}
{% capture the_authors_lastname %}<span class="author-name">{{ page.book_author | split: " " | last }}</span>{% endcapture %}
{% capture the_authors %}{% author_link page.book_author possessive %}{% endcapture %}
{% capture the_author_link %}{% author_link page.book_author %}{% endcapture %}

{% capture jacksons %}{% author_link "Robert Jackson Bennett" possessive %}{% endcapture %}
{% capture tainted %}{% book_link "The Tainted Cup" %}{% endcapture %}

{% capture wolfes %}{% author_link "Gene Wolfe" possessive %}{% endcapture %}
{% capture wolfes_short %}{% author_link "Gene Wolfe" possessive link_text="Wolfe" %}{% endcapture %}
{% capture torturer %}{% book_link "The Shadow of the Torturer" %}{% endcapture %}

{% capture brunners %}{% author_link "John Brunner" possessive %}{% endcapture %}
{% capture stand_on_zanzibar %}{% book_link "Stand on Zanzibar" %}{% endcapture %}

{{ this_book }} is an urban fantasy book, set on a city that covers the Earth.
The structure, geometric layout, and mass of the city naturally generates
plasm, an electricity-like substance that mages need to cast spells. It is set
in the far far future, like {{ wolfes }} {{ torturer }}, although unlike {{
wolfes_short }} work the world still has modern-ish technology like
skyscrapers, subways, computers, and cars and magic is not mystical but
systematized like a technology.

The story is a familiar one: Aiah, her family, and her people are refugees from
the destruction of their own metropolis. They are people of color living as
second class citizens in a white world.

They are taken advantage of by both the government and organized crime. It's a
story that would fit right in in 1980s Brooklyn or LA.

Aiah got a scholarship and was able to precariously climb into the
middle class, with a white collar office job. She is resented by both society
as a minority, who is succeeding, and by her family and people because she's
escaped their cycle of poverty.  She is also a mage.

The best thing about {{ this_book }} is the subtle world building scattered
cleverly throughout the story, much like {{ jacksons }} {{ tainted }}.

{{ this_book }} reminded me of some books I've read recently:

- The separation of the books subsections with in-world advertisements is
  like the various in-world chapters that separated the narrative chapters in
  {{ brunners }} {{ stand_on_zanzibar }}.
