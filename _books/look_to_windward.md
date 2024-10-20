---
date: 2024-10-16
title: Look To Windward
book_author: Iain M. Banks
series: Culture
book_number: 7
rating: 5
image: /books/covers/look_to_windward.jpg
---

<cite class="book-title">{{ page.title }}</cite>, by <span
class="author-name">{{ page.book_author }}</span>, is the seventh <span
class="book-series">{{ page.series }}</span> book.

{% capture this_book %}<cite class="book-title">{{ page.title }}</cite>{% endcapture %}
{% capture the_author %}<span class="author-name">{{ page.book_author }}</span>{% endcapture %}
{% capture series %}<span class="book-series">{{ page.series }}</span>{% endcapture %}
{% capture the_authors %}{% include author_link.html name=page.book_author possessive=true %}{% endcapture %}
{% capture this_series %}{% include series_link.html series=page.series %} series{% endcapture %}

{% capture c1 %}{% include book_link.html title="Consider Phlebas" %}{% endcapture %}
{% capture c2 %}{% include book_link.html title="The Player of Games" %}{% endcapture %}
{% capture c3 %}{% include book_link.html title="Use of Weapons" %}{% endcapture %}
{% capture c5 %}{% include book_link.html title="Excession" %}{% endcapture %}
{% capture c6 %}{% include book_link.html title="Inversions" %}{% endcapture %}
{% capture c8 %}{% include book_link.html title="Matter" %}{% endcapture %}

{% capture elliots %}{% include author_link.html name="T. S. Eliot" possessive=true %}{% endcapture %}
{% capture the_wasteland %}{% include book_link.html title="The Waste Land" %}{% endcapture %}

{{ this_book }}'s title---like {{ c1 }}---is a reference to {{ elliots }} poem
{{ the_wasteland }}. The poem's theme of death and rebirth are reflected in {{
this_book }}, and many of the lines from the poem are the inspiration for
characters in {{ the_authors }} novel: Masaq' Hub literally _"turn[s] the
wheel and look[s] to windward"_; Uagen Zlepe's fate mirrors that of Phlebas in
the poem, died on a voyage in trapped in the whirlpool of the galaxy; and the
eDust assassin is _"[...]fear in a handful of dust."_

{{ this_book }} is considered a sequel to {{ c1 }}, but in many respects I
actually think it is a rewrite. Both books deal with the smallness of man
against the galaxy and the culture at war with an alien empire. Of course the
characters in {{ this_book }} are far better.
