---
date: 2024-11-16
title: The Nameless City
book_author: H. P. Lovecraft
series: Cthulhu Mythos
book_number: 1
rating: 3
image: /books/covers/the_nameless_city.jpg
---

<cite class="book-title">{{ page.title }}</cite> is a short story by <span
class="author-name">{{ page.book_author }}</span> set in the <span
class="book-series">{{ page.series }}</span>. It follows an unnamed narrator
who discovers a mysterious ancient city and ventures deep beneath its surface.

{% capture this_book %}<cite class="book-title">{{ page.title }}</cite>{% endcapture %}
{% capture the_author %}<span class="author-name">{{ page.book_author }}</span>{% endcapture %}
{% capture series %}<span class="book-series">{{ page.series }}</span>{% endcapture %}

{% capture the_authors %}{% include author_link.html name=page.book_author possessive=true %}{% endcapture %}
{% capture the_authors_short %}{% include author_link.html name=page.book_author possessive=true link_text="Lovecraft" %}{% endcapture %}

{% capture torturer %}{% include book_link.html title="The Shadow of the Torturer" %}{% endcapture %}
{% capture wolfe %}{% include author_link.html name="Gene Wolfe" %}{% endcapture %}

{% capture matter %}{% include book_link.html title="Matter" %}{% endcapture %}
{% capture banks %}{% include author_link.html name="Iain M. Banks" %}{% endcapture %}
{% capture banks_short %}{% include author_link.html name="Iain M. Banks" possessive=true link_text="Banks" %}{% endcapture %}

{% capture this_city %}{{ the_authors_short }} city{% endcapture %}
{% capture that_city %}{{ banks_short }} city{% endcapture %}

{{ this_book }} reminded me of {{ torturer }}. {{ the_author }} used a blend
of real historical elements with fictional ones to build a convincing world,
just as {{ wolfe }} does with his archaic English and real-world locations.

When I reviewed {{ matter }}, I noted that its Nameless City was likely
inspired by {{ this_book }}. The similarities are:

- Both cities lie buried underground and survived a "deluge"---{{ this_city }}
  being literally [antediluvian][antediluvian_wiki], while {{ that_city }} was
  unearthed beneath the Hyeng-zhar waterfall.

- Both contain ancient sarcophagi housing primeval evils that lingers across
  uncountable eons.

- Both stories emphasize humanity's insignificance when confronted with these 
  ancient civilizations.

[antediluvian_wiki]: https://en.wikipedia.org/wiki/Antediluvian

This was an interesting short story, even though horror is not one of my
favorite genres. Given {{ the_authors }} massive influence on speculative
fiction of all genres, I plan to read more stories from the {{ series }} to
better understand his impact on the field.
