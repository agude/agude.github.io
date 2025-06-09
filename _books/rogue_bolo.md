---
date: 2025-06-08
title: "Rogue Bolo"
book_authors: Keith Laumer
series: Bolo
book_number: 2
rating: 3
image: /books/covers/rogue_bolo.jpg
---

<cite class="book-title">{{ page.title }}</cite>, by <span
class="author-name">{{ page.book_authors }}</span>, is the second book in the
<span class="book-series">{{ page.series }}</span> series. It is a collection
of two novellas featuring the sentient tanks.

{% capture this_book %}<cite class="book-title">{{ page.title }}</cite>{% endcapture %}
{% capture the_author %}<span class="author-name">{{ page.book_authors }}</span>{% endcapture %}
{% capture the_authors_lastname %}<span class="author-name">{{ page.book_authors | split: " " | last }}</span>{% endcapture %}
{% capture the_authors %}{% author_link page.book_authors possessive %}{% endcapture %}
{% capture the_author_link %}{% author_link page.book_authors %}{% endcapture %}
{% capture this_series %}{% series_text page.series %}{% endcapture %}

{% capture bolo3 %}{% book_link "The Stars Must Wait" %}{% endcapture %}
{% capture bolo4 %}{% book_link "Bolo Brigade" %}{% endcapture %}
{% capture bolo5 %}{% book_link "Bolo Rising" %}{% endcapture %}
{% capture bolo6 %}{% book_link "Bolo Strike" %}{% endcapture %}
{% capture bolo7 %}{% book_link "The Road to Damascus" %}{% endcapture %}
{% capture bolo8 %}{% book_link "Bolo!" %}{% endcapture %}
{% capture bolo9 %}{% book_link "Old Soldiers" %}{% endcapture %}
{% capture bolo10 %}{% book_link "Honor of the Regiment" %}{% endcapture %}
{% capture bolo11 %}{% book_link "The Unconquerable" %}{% endcapture %}
{% capture bolo12 %}{% book_link "The Triumphant" %}{% endcapture %}
{% capture bolo13 %}{% book_link "Last Stand" %}{% endcapture %}
{% capture bolo14 %}{% book_link "Old Guard" %}{% endcapture %}
{% capture bolo15 %}{% book_link "Cold Steel" %}{% endcapture %}

{% capture bolo1 %}{% book_link "Bolo: Annals of the Dinochrome Brigade" %}{% endcapture %}
{% capture history_from_bolo1 %}<a href="/books/bolo_annals_of_the_dinochrome_brigade/#a-short-history-of-the-bolo-fighting-machines"><cite class="short-story-title">A Short History of the Bolo Fighting Machines</cite></a>{% endcapture %}
{% capture trolls_from_bolo1 %}<a href="/books/bolo_annals_of_the_dinochrome_brigade/#the-night-of-the-trolls"><cite class="short-story-title">The Night of the Trolls</cite></a>{% endcapture %}
{% capture courier_from_bolo1 %}<a href="/books/bolo_annals_of_the_dinochrome_brigade/#courier"><cite class="short-story-title">Courier</cite></a>{% endcapture %}
{% capture field_test_from_bolo1 %}<a href="/books/bolo_annals_of_the_dinochrome_brigade/#field-test"><cite class="short-story-title">Field Test</cite></a>{% endcapture %}
{% capture last_command_from_bolo1 %}<a href="/books/bolo_annals_of_the_dinochrome_brigade/#the-last-command"><cite class="short-story-title">The Last Command</cite></a>{% endcapture %}
{% capture relic_from_bolo1 %}<a href="/books/bolo_annals_of_the_dinochrome_brigade/#a-relic-of-war"><cite class="short-story-title">A Relic of War</cite></a>{% endcapture %}
{% capture combat_unit_from_bolo1 %}<a href="/books/bolo_annals_of_the_dinochrome_brigade/#combat-unit"><cite class="short-story-title">Combat Unit</cite></a>{% endcapture %}

{% capture dragons_banker %}{% book_link "The Dragon's Banker" %}{% endcapture %}
{% capture warren %}{% author_link "Scott Warren" %}{% endcapture %}
{% capture warrens %}{% author_link "Scott Warren" possessive %}{% endcapture %}

{{ this_book }} actually has three stories, if you count the re-inclusion of {{
history_from_bolo1 }}, which I don't. Both novellas in the book are essentially
expansions of the short-stories from {{ bolo1 }}.

### <cite class="short-story-title">Rogue Bolo</cite>
{% rating_stars 4 %}

<cite class="short-story-title">Rogue Bolo</cite> expansion of the concept and
structure used in {{ field_test_from_bolo1 }}. It uses the same
paragraph-length chapters (200 of them!) to tell the story of the Bolo CSR,
who was created on an authoritarian Earth, and given immense processing power
and the freedom to take whatever action necessary to protect the empire.

One thing I realized half-way through this story is that it **is** the dragon
story I wished {{ warrens }} {{ dragons_banker }} was. The Bolo is infinitely
strong, cunning, and patient; just like a dragon! When the Bolo realizes that
Earth will soon be attacked, it doesn't launch itself into the fray, instead
it starts buying up land, water rights, and factories so that it can build up
the manufacturing base needed to synthesize the element that is a deadly
poison to the crystal-based lifeforms. In the end, the Bolo uses trickery and
planning to win the war without firing a single shot.

### <cite class="short-story-title">Final Mission</cite>
{% rating_stars 3 %}

A deactivated Bolo in a museum in a town of 300 people on a backwater planet
wakes up when some children break-in and approach it. Good timing, because
right then the alien Deng return, the same aliens the Bolo repulsed 200 years
ago.

Almost but not really a fix-up, it's a mix of {{ last_command_from_bolo1 }},
{{ relic_from_bolo1 }}, and {{ combat_unit_from_bolo1 }}. That should be great
because those are the best stories from {{ bolo1 }}, but the story feels too
long and also cramped, set as it is in essentially one street of a tiny town.
Additionally, the "space hicks" who live in the town speak with an accent that
{{ the_author }} spells out phonetically, which makes reading slow, and I
often lost my place when I looked up.
