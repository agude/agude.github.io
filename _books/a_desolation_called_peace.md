---
date: 2025-04-05
title: A Desolation Called Peace
book_author: Arkady Martine
series: Teixcalaan
book_number: 2
rating: 5
image: /books/covers/a_desolation_called_peace.jpg
awards:
  - hugo
---

<cite class="book-title">{{ page.title }}</cite>, by <span
class="author-name">{{ page.book_author }}</span>, is the second book in the
<span class="book-series">{{ page.series }}</span> series.

{% capture this_book %}<cite class="book-title">{{ page.title }}</cite>{% endcapture %}
{% capture the_author %}<span class="author-name">{{ page.book_author }}</span>{% endcapture %}
{% capture the_authors %}{% include author_link.html name=page.book_author possessive=true %}{% endcapture %}
{% capture this_series %}{% include series_link.html series=page.series %} series{% endcapture %}
{% capture the_author_link %}{% include author_link.html name=page.book_author %}{% endcapture %}

{% capture teix1 %}{% include book_link.html title="A Memory Called Empire" %}{% endcapture %}

{% capture hamiltons %}{% include author_link.html name="Peter F. Hamilton" possessive=true %}{% endcapture %}
{% capture pandoras_star %}{% include book_link.html title="Pandora's Star" %}{% endcapture %}
{% capture jusdas_unchained %}{% include book_link.html title="Judas Unchained" %}{% endcapture %}

{% capture enders_game %}{% include book_link.html title="Ender's Game" %}{% endcapture %}

{% capture grrms %}{% include author_link.html name="George R. R. Martin" possessive=true %}{% endcapture %}
{% capture game_of_thrones %}{% include book_link.html title="A Game of Thrones" %}{% endcapture %}

{% capture sagans %}{% include author_link.html name="Carl Sagan" possessive=true %}{% endcapture %}
{% capture contact %}{% include book_link.html title="Contact" %}{% endcapture %}

{{ this_book }} continues right where {{ teix1 }} left off:


{{ this_book }} reminded me of others pieces of science fiction:

- The aliens call their ships starflyers, like the alien in {{ hamiltons }} {{
  pandoras_star }} and {{ jusdas_unchained }}. The aliens in both books are
  hive minds, and in both the humans consider a genocide against the aliens
  and are conflicted about it.

- The hive mind aliens are like the buggers from {{ enders_game }}. Ender
  commits genocide by destroying the buggers' homeworld and regrets it, while
  in {{ this_book }} the genocide is averted.

- The throne of spear is a bit like the iron throne made of swords in {{ grrms
  }} {{ game_of_thrones }}.

- The furry pets that have taken over the _Weight for the Wheel_'s air vents is a
  homage to the Tribbles from <span class="tv-show-title">Star Trek</span>.

- The Teixcalaan empire sent a poet to establish first contact with the
  Ebrektia and regretted it because the poet sent back no scientific
  observations, leading to them saying: "We sent a poet where we ought to have
  sent a team of _ixplanatl_ researchers", a reference to the movie <span
  class="movie-title">Contact</span>, based on {{ sagans }} {{ contact }}.
