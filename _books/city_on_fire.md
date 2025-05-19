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
<span class="book-series">{{ page.series }}</span> series. It takes place
right as the smoke clears in Caraqui after the revolution, leaving Aiah and
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
{% capture drop %}{% book_link "A Drop of Corruption" %}{% endcapture %}

{% capture bankss %}{% author_link "Iain M. Banks" possessive %}{% endcapture %}
{% capture weapons %}{% book_link "Use of Weapons" %}{% endcapture %}

{% capture asoif %}{% series_text "A Song of Ice and Fire" %}{% endcapture %}
{% capture martins %}{% author_link "George R. R. Martin" possessive %}{% endcapture %}
{% capture crows %}{% book_link "A Feast for Crows" %}{% endcapture %}

{% capture martines %}{% author_link "Arkady Martine" possessive %}{% endcapture %}
{% capture empire %}{% book_link "A Memory Called Empire" %}{% endcapture %}

The first book, {{ m1 }}, was a standard fantasy story---the hero discovers
their inner talent and uses it to overthrow an evil ruler---with a unique
world. {{ this_book }}'s story is more unique. It focuses on what happens
after the revolution: when the heroes need to govern; form a coalition with
multiple, opposed interest groups; and compromise their morals to avoid
complete destruction. In this way, the book is similar to {{ sotl }}, which
focuses more on the process of actually keeping an empire running. How to go
from revolution to government should have been a more interesting story---it's
one more rarely explored!---but I just didn't enjoy following Aiah very much.

Aiah is a more complex character in this book, and one I enjoyed reading about
more. Her major flaw, that she is blinded by her devotion to Constantine, is
counterbalanced by her other "flaw", that she won't compromise her ideals for
power. Still, I found her romantic relationship with Constantine more annoying
than exciting. In some ways this book reminded me of a romance novel: the
young, inexperienced woman attracts the attention of a powerful and dangerous
man, who teachers her there is more to life than she imagined. And there are a
lot of sex scenes.

This book and {{ m1 }} before it---written almost thirty years ago---feel very
modern: the main characters are people of color, there are gay relationships
that are treated as perfectly normal, and there are women in male-dominated
roles. The theme of having to compromise you ideals to actually govern is
darkly appropriate in this time where the far right is ascendant.

But in other ways {{ this_series }} is solidly rooted in 90's [Third
Way][third_way] politics: the first thing Constantine does in Caraqui is sell
off the government industries to private parties to increase efficiency, lower
barriers to trade, and simplify the tax code. The entire revolution and the
mess that comes after echoes the waves of [humanitarian
intervention][human_intervention] during the same period. There is even a
scene about eating grapefruit to stay thin right out of the 90's.

[third_way]: https://en.wikipedia.org/wiki/Third_Way
[human_intervention]: https://en.wikipedia.org/wiki/Humanitarian_intervention

{{ this_book }} is the middle-book in an as-of-yet unwritten trilogy, with the
third book tentatively titled {{ m3 }}. As a middle book, it only resolves some
of the threads left open in {{ m1 }} while adding more. Taikoen is revealed
to, in some perverse way, be a friend and advisor to Constantine, and Aiah's
destruction of the hanged man is used to drive a wedge between herself and
Constantine. I wish the book had explored the Constantine--Taikoen
relationship more, but that's hard to do in a book told from Aiah's point of
view. The book did a good job of turning Sorya into an antagonist, but left
the resolution for the next book. A little was revealed about the shield, as
Aiah was able to briefly pierce it, but that too is clearly being left for
next time.

The book reminded me of a few other works:

- The way there are little shrines with devotion candles dedicated to the gods
  in the plasm stations was like <cite class="table-top-game-title">Warhammer
  40,000</cite>'s mix of technology and religion.
- The way large-scale military actions were sometimes described in a single
  sentence was like the end of {{ bankss }} {{ weapons }}.
- The way the narrative kept expanding without tying up all the loose ends
  reminded me of the later books in {{ martins }} {{ asoif }}, particularly {{
  crows }}.
- The Dreaming Sisters contemplate tarot-like archetypes called "Imagoes",
  the same word for the memory recording devices in {{ martines }} {{ empire
  }}, which is how I learned that it is a real word which means: "An idealised
  concept of a loved one, formed in childhood and retained unconsciously into
  adult life, the basis for the psychological formation of personality
  archetypes."

I hope {{ the_author }} finishes {{ m3 }} and ties up the loose ends, but
after three decades I'm not holding my breath.
