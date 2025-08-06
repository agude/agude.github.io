---
date: 2025-08-04
title: Roadside Picnic
book_authors:
  - Arkady Strugatsky
  - Boris Strugatsky
series: null
book_number: 1
rating: 5
image: /books/covers/roadside_picnic.jpg
---

<cite class="book-title">{{ page.title }}</cite>, by brothers <span
class="author-name">{{ page.book_authors[0] | split: " " | first }}</span> and
<span class="author-name">{{ page.book_authors[1] }}</span>, is a Soviet
sci-fi novel. It's essentially four short stories, each presented as a
chapter, about the life of Redrick "Red" Schuhart, a "stalker" who illegally
enters an alien-contaminated zone to retrieve items for the black market.

{% capture this_book %}<cite class="book-title">{{ page.title }}</cite>{% endcapture %}
{% capture the_author %}<span class="author-name">{{ page.book_authors }}</span>{% endcapture %}
{% capture the_authors %}<span class="author-name">{{ page.book_authors }}</span>'s{% endcapture %}
{% capture author_last_name_text %}{{ page.book_authors | split: " " | last }}{% endcapture %}
{% capture the_authors_lastname %}<span class="author-name">{{ page.book_authors | split: " " | last }}</span>{% endcapture %}
{% capture the_authors_lastname_possessive %}<span class="author-name">{{ page.book_authors | split: " " | last }}</span>'s{% endcapture %}
{% capture the_author_link %}{% author_link page.book_authors %}{% endcapture %}
{% capture the_authors_link %}{% author_link page.book_authors possessive %}{% endcapture %}
{% capture the_authors_lastname_link %}{% author_link page.book_authors link_text=author_last_name_text %}{% endcapture %}
{% capture the_authors_lastname_possessive_link %}{% author_link page.book_authors link_text=author_last_name_text possessive %}{% endcapture %}
{% capture this_series %}{% series_text page.series %}{% endcapture %}

{% capture wellss %}{% author_link "H. G. Wells" possessive %}{% endcapture %}
{% capture war_of_the_worlds %}{% book_link "The War of the Worlds" %}{% endcapture %}
{% capture war %}{% book_link "The War of the Worlds" link_text="War" %}{% endcapture %}

{% capture qntm %}{% author_link "qntm" %}{% endcapture %}
{% capture antimemetics %}{% book_link "There Is No Antimemetics Division" %}{% endcapture %}

{% capture kurvitz %}{% author_link "Robert Kurvitz" %}{% endcapture %}
{% capture disco_elysium %}{% book_link "Disco Elysium" %}{% endcapture %}

{% capture banks %}{% author_link "Iain M. Banks" %}{% endcapture %}
{% capture cleaning_up %}{% book_link "Cleaning Up" %}{% endcapture %}

{% capture moore %}{% author_link "Alan Moore" %}{% endcapture %}
{% capture gibbons %}{% author_link "Dave Gibbons" %}{% endcapture %}
{% capture watchmen %}{% book_link "Watchmen" %}{% endcapture %}

It's great the authors had the courage to never tell you more than the
characters know, and the aliens never make an appearance, not even sort of.


{{ this_book }} pays homage to {{ wellss }} {{ war_of_the_worlds }}. Both {{
war }} and this book are alien invasion stories. A both aliens arrive on Earth
as if shot by a cannon. But the Aliens in {{ war }} are active, hostile,
intimately aware of humanity and the need to destroy us. The aliens of {{
this_book }} don't even appear in the book, they interact with the story and
the world only through the things they've left behind.

"all six Visit Zones are position on the surface of
the planet like bullet holes made by a gun located somewhere between Earth and
Deneb"
