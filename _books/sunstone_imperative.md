---
date: 2026-02-21 12:57:55 -0800
title: Sunstone Imperative
book_authors: Scott Warren
series: War Horses
book_number: 6
rating: 4
image: /books/covers/sunstone_imperative.jpg
---

<cite class="book-title">{{ page.title }}</cite>, by <span
class="author-name">{{ page.book_authors }}</span>, is the sixth book in the
<span class="book-series">{{ page.series }}</span> series.

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

{% capture w1 %}{% book_link "Chevalier" %}{% endcapture %}
{% capture w2 %}{% book_link "Ymir" %}{% endcapture %}
{% capture w3 %}{% book_link "Serpent Valley" %}{% endcapture %}
{% capture w4 %}{% book_link "Dog Soldier" %}{% endcapture %}
{% capture w5 %}{% book_link "Grand Melee" %}{% endcapture %}

{% capture bob %}{% book_link "Band of Brothers" %}{% endcapture %}
{% capture ambroses_lastname %}{% author_link "Stephen E. Ambrose" link_text="Ambrose" possessive %}{% endcapture %}

{% capture cantos %}{% series_link "Hyperion Cantos" %}{% endcapture %}

In {{ this_book }}, the Wyking clans---first introduced in {{ w2 }}---are
locked in a bitter civil war. Sensing an opportunity, the Emirs of the West
Gulf and the Archon de Catalan assemble a joint taskforce to breach the Dwimor
Gate, one of the few navigable routes into clan space. But blocking their path
is a massive fortress-asteroid honeycombed with narrow passages and defended
by Wyking warriors. Taking out the stronghold is essential for the invasion's
success. Mechs are too large for most of the asteroid's tunnels, but just the
right size for the Seraphs: human-sized power armor first seen in {{ w5 }}.

The story in this book is a relatively simple. I enjoyed the long-running gag
about Vandal's leadership training. {{ the_authors_lastname }} must have read
some of the same (terrible) books I did when I was trying to be a better
manager, because he lampoons their concepts perfectly. The Wykings are
probably the best part of the book. {{ the_author }} does a good job of making
them horrifying and evil, but with some humor. And it's really interesting to
get a deeper look into their culture, and how the hierarchy of the clans.

The initial assault on the asteroid reminded me of the [American airborne
assault][airborne] during [Operation Overlord][overlord], or at least how
they're described in {{ ambroses_lastname }} {{ bob }}. The Seraphs and
marines teleport over to take out key objectives before the initial assault,
but they end up scattered and in the wrong drop zones, desperately trying to
regroup rather than achieve their objectives.

[airborne]: https://en.wikipedia.org/wiki/American_airborne_landings_in_Normandy
[overlord]: https://en.wikipedia.org/wiki/Operation_Overlord

{{ this_book }} didn't have the fun twists of {{ w5 }}, and it didn't have the
careful plotting and look into the types of people you need during and after a
revolution that made {{ w3 }} and {{ w4 }} so good, but it is a solid action
romp in the vein of {{ w1 }}, and a perfect palate cleanser after the
philosophical and _long_ {{ cantos }}.
