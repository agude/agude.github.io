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
<span class="book-series">{{ page.series }}</span> series. It picks up right
as the smoke clears in Caraqui after the revolution, leaving Aiah and
Constantine to figure out how to govern.

{% capture this_book %}<cite class="book-title">{{ page.title }}</cite>{% endcapture %}
{% capture the_author %}<span class="author-name">{{ page.book_author }}</span>{% endcapture %}
{% capture the_authors_lastname %}<span class="author-name">{{ page.book_author | split: " " | last }}</span>{% endcapture %}
{% capture the_authors %}{% author_link page.book_author possessive %}{% endcapture %}
{% capture the_author_link %}{% author_link page.book_author %}{% endcapture %}
{% capture this_series %}{% series_text page.series %}{% endcapture %}

{% capture m1 %}{% book_link "Metropolitan" %}{% endcapture %}
{% capture m3 %}{% book_link "Heaven in Flames" %}{% endcapture %}

{% capture sotl %}{% series_text "Shadow of the Leviathan" %}{% endcapture %}
{% capture tainted %}{% book_link "The Tainted Cup" %}{% endcapture %}

{% capture bankss %}{% author_link "Iain M. Banks" possessive %}{% endcapture %}
{% capture weapons %}{% book_link "Use of Weapons" %}{% endcapture %}

{% capture asoif %}{% series_text "A Song of Ice and Fire" %}{% endcapture %}
{% capture martins %}{% author_link "George R. R. Martin" possessive %}{% endcapture %}
{% capture crows %}{% book_link "A Feast for Crows" %}{% endcapture %}

{% capture martines %}{% author_link "Arkady Martine" possessive %}{% endcapture %}
{% capture empire %}{% book_link "A Memory Called Empire" %}{% endcapture %}

The first book, {{ m1 }}, was a standard fantasy story---the hero discovers
their inner talent and uses it to overthrow an evil ruler---set in a unique
world. {{ this_book }}'s story is more original. It focuses on what happens
after the revolution: when the heroes have to govern, form a coalition among
opposing factions, and compromise their morals to avoid collapse. In this way,
it's similar to {{ tainted }} from {{ sotl }}, which is also more concerned
with what is required to keep an empire running. The transition from
revolution to government _should_ have been more interesting---it's a rarely
explored part of these kinds of stories---but I just didn't enjoy following
Aiah very much.

Aiah is a more complex character in this book, and I enjoyed reading about her
more than in {{ m1 }}, though that's still not saying much. Her main flaw,
that she's blinded by her devotion to Constantine, is somewhat counterbalanced
by her other "flaw": she refuses to compromise her ideals for power. This
plays out most clearly in her affair with Constantine, but the relationship
just did not interest me. I did not care if they stayed together, nor how it
changed them. In some ways, the book reminded me of a romance novel: the
young, inexperienced woman catches the attention of a powerful and dangerous
man, who shows her that there's more to life than she imagined. And there are
a **lot** of sex scenes.

This book and {{ m1 }}---written nearly thirty years ago---feel very modern:
the main characters are people of color, there are gay relationships treated
as completely normal, and women occupy roles usually reserved for men. The
theme of having to compromise your ideals in order to govern hits especially
hard in a time when the far right is ascendant as the opposition parties fail
to overcome their differences and rally together.

But in other ways, {{ this_series }} is rooted in 90s [Third Way][third_way]
politics: the first thing Constantine does in Caraqui is sell off government
industries to private buyers, lower trade barriers, and simplify the tax code.
The entire revolution and its messy aftermath echo the waves of [humanitarian
intervention][human_intervention] from the same period. There's even a scene
about eating grapefruit to stay thin, which feels straight out of the 90s
anorexia panic.

[third_way]: https://en.wikipedia.org/wiki/Third_Way [human_intervention]:
https://en.wikipedia.org/wiki/Humanitarian_intervention

{{ this_book }} is the middle volume of a still-unfinished trilogy, with the
third book tentatively titled {{ m3 }}. As a middle book, it resolves some of
{{ m1 }}'s open threads while introducing more. Taikoen is revealed to be, in
some perverse way, a friend and advisor to Constantine, and Aiah's destruction
of the hanged man becomes a wedge between her and Constantine. I wish the book
had spent more time on the Constantine--Taikoen relationship because it is not
well foreshadowed, but that's hard to do when everything is seen from Aiah's
point of view. Sorya becomes a clear antagonist, but the resolution is left
for the next book. We get a bit more about the shield, as Aiah briefly pierces
it, but that too is being saved for later.

The book reminded me of a few other works:

- The little shrines with devotion candles in the plasm stations felt straight
  out of <cite class="table-top-game-title">Warhammer 40,000</cite>, with its
  mix of technology and religion.
- The way major military actions are sometimes covered in just a sentence felt
  like the end of {{ bankss }} {{ weapons }}.
- The ever-expanding narrative, full of unresolved threads, recalled the later
  books in {{ martins }} {{ asoif }}, especially {{ crows }}.
- The Dreaming Sisters' tarot-like archetypes called "Imagoes" share a name
  with the memory devices in {{ martines }} {{ empire }}---which is how I
  learned it's a real word meaning: "An idealized concept of a loved one,
  formed in childhood and retained unconsciously into adult life, the basis
  for the psychological formation of personality archetypes."

I hope {{ the_author }} finishes {{ m3 }} and ties up the loose ends, but
after three decades, I'm not holding my breath.
