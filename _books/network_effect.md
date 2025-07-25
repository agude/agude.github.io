---
date: 2025-07-17
title: Network Effect
book_authors: Martha Wells
series: The Murderbot Diaries
book_number: 5
rating: 5
image: /books/covers/network_effect.jpg
---

<cite class="book-title">{{ page.title }}</cite>, by <span
class="author-name">{{ page.book_authors }}</span>, is the fifth book in the
<span class="book-series">{{ page.series }}</span>. It's the first full-length
novel in the series, and features Murderbot getting Kidnapped by ART to rescue
its crew.

{% capture this_book %}<cite class="book-title">{{ page.title }}</cite>{% endcapture %}
{% capture the_author %}<span class="author-name">{{ page.book_authors }}</span>{% endcapture %}
{% capture the_authors_lastname %}<span class="author-name">{{ page.book_authors | split: " " | last }}</span>{% endcapture %}
{% capture the_authors %}{% author_link page.book_authors possessive %}{% endcapture %}
{% capture the_author_link %}{% author_link page.book_authors %}{% endcapture %}
{% capture this_series %}{% series_text page.series %}{% endcapture %}

{% capture mb1 %}{% book_link "All Systems Red" %}{% endcapture %}
{% capture mb2 %}{% book_link "Artificial Condition" %}{% endcapture %}
{% capture mb3 %}{% book_link "Rogue Protocol" %}{% endcapture %}
{% capture mb4 %}{% book_link "Exit Strategy" %}{% endcapture %}
{% capture mb4_5 %}{% book_link "Home: Habitat, Range, Niche, Territory" %}{% endcapture %}
{% capture mb5 %}{% book_link "Network Effect" %}{% endcapture %}
{% capture mb6 %}{% book_link "Fugitive Telemetry" %}{% endcapture %}
{% capture mb7 %}{% book_link "System Collapse" %}{% endcapture %}

{% capture brunner %}{% author_link "John Brunner" %}{% endcapture %}
{% capture zanzibar %}{% book_link "Stand on Zanzibar" %}{% endcapture %}

{% capture hamilton %}{% author_link "Peter F. Hamilton" %}{% endcapture %}
{% capture pandora %}{% book_link "Pandora's Star" %}{% endcapture %}

{% capture martine %}{% author_link "Arkady Martine" %}{% endcapture %}
{% capture empire %}{% book_link "A Memory Called Empire" %}{% endcapture %}

{% capture forward %}{% author_link "Robert L. Forward" %}{% endcapture %}
{% capture dragons_egg %}{% book_link "Dragon's Egg" %}{% endcapture %}

{% capture vinge %}{% author_link "Vernor Vinge" %}{% endcapture %}
{% capture fire_deep %}{% book_link "A Fire Upon the Deep" %}{% endcapture %}

{% capture close_to_critical %}{% book_link "Close to Critical" %}{% endcapture %}

{% capture soldier_movie %}[<cite class="movie-title">Soldier</cite>][soldier]{% endcapture %}

[soldier]: https://en.wikipedia.org/wiki/Soldier_(1998_American_film)

{% capture taylor %}{% author_link "Dennis E. Taylor" %}{% endcapture %}
{% capture bobiverse %}{% series_link "Bobiverse" %}{% endcapture %}
{% capture bobiverse_one %}{% book_link "We Are Legion (We Are Bob)" %}{% endcapture %}

{% capture banks %}{% author_link "Iain M. Banks" %}{% endcapture %}
{% capture culture %}{% series_link "Culture" %}{% endcapture %}
{% capture matter %}{% book_link "Matter" %}{% endcapture %}

{{ this_book }} brings back the best non-Murderbot character from the GrayCris
story: ART, the asshole research transport, first seen in {{ mb2 }}. The power
fantasy is toned-down a little---instead of being able to deal with anything,
ART has been taken over and needs help.

- The `HelpMe.file` used to tell a parallel story reminds me of how {{
  brunner }} builds the world with various in-world media in {{ zanzibar }}.

- Discussions of whether a copy of your mind is "you" reminded me of the same
  question being debated in {{ pandora }} and {{ bobiverse_one }}. The answer
  "no" based on the fact that the copy has different memories and neural
  pathways is the same answer as in {{ empire }}.

- The alien-infected humans fighting a war between themselves while taking
  human hostages reminded me of {{ close_to_critical }} and {{
  dragons_egg }}.

- An alien virus taking over people's mind reminded me of the Blight from {{
  fire_deep }}.

- Murderbot's greatest fear being abandoned on a planet reminded me of {{
  soldier_movie }}, which also explorers the theme of a former weapon
  developing emotions and community.
