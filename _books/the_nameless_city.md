---
date: 2024-11-16
title: The Nameless City
book_author: H. P. Lovecraft
series: null
book_number: 1
rating: 3
image: /books/covers/the_nameless_city.jpg
---

<cite class="book-title">{{ page.title }}</cite> is a short story by <span
class="author-name">{{ page.book_author }}</span> set in the Cthulu Mythos. In
it, an unnamed narrator finds a nameless city and descends into the earth.

{% capture this_book %}<cite class="book-title">{{ page.title }}</cite>{% endcapture %}
{% capture the_author %}<span class="author-name">{{ page.book_author }}</span>{% endcapture %}
{% capture series %}<span class="book-series">{{ page.series }}</span> series{% endcapture %}

{% capture the_authors %}{% include author_link.html name=page.book_author possessive=true %}{% endcapture %}
{% capture the_authors_short %}{% include author_link.html name=page.book_author possessive=true link_text="Lovecraft" %}{% endcapture %}

{% capture torturer %}{% include book_link.html title="The Shadow of the Torturer" %}{% endcapture %}
{% capture wolfe %}{% include author_link.html name="Gene Wolfe" %}{% endcapture %}

{% capture matter %}{% include book_link.html title="Matter" %}{% endcapture %}
{% capture banks %}{% include author_link.html name="Iain M. Banks" %}{% endcapture %}
{% capture banks_short %}{% include author_link.html name="Iain M. Banks" possessive=true link_text="Banks" %}{% endcapture %}

{% capture this_city %}{{ the_authors_short }} city{% endcapture %}
{% capture that_city %}{{ banks_short }} city{% endcapture %}

{{ this_book }} reminded me of {{ torturer }}. {{ wolfe }} used archaic
English to give his world a real but old feeling, and {{ the_author }} used a
mix of real history and places with his own fictional one for a similar
effect.

I wrote in my review of {{ matter }} that the Nameless City in that book was
inspired by {{ this_book }} by {{ the_author }}. There are many similarities,
specifically:

- Both cities are buried underground and survive a "deluge"; {{ this_city }}
  being literally [antediluvian][antediluvian_wiki] and {{ that_city }} being
  uncovered by the Hyeng-zhar waterfall.

- Both cities contain sarcophagi buried within them, holding an ancient evil
  that still lingers after uncountable eons.

- Both books focus on the insignificance of humanity and the protagonists in
  the face of this ancient race.

[antediluvian_wiki]: https://en.wikipedia.org/wiki/Antediluvian

A quick read from a genre outside my normal tastes. {{ the_authors }} Cthulu
Mythos is so influential that I'll probably read a few more to round out my
knowledge.
