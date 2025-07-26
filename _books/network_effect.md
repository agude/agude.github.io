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
novel in the series, and features Murderbot getting kidnapped by ART to rescue
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
storyline: ART, the asshole research transport first seen in {{ mb2 }}. The
power fantasy is toned down a bit---ART has been taken over and needs help, so
it kidnaps Murderbot to come bail it out.

The book goes deeper into Murderbot's personality and feelings. It doesn't
like logos because it's been branded. It hates pretending to be a SecUnit
because it reminds it of being enslaved. It likes being cared for. ART is its
friend. We also see more of the horrors of the Corporation Rim, where colonies
and their people are left to die if they're not profitable.

Control is a major theme of {{ this_book }}. Murderbot and other SecUnits are
controlled through their governor modules. The employees of the Corporation
Rim are essentially owned by their employers. ART gets taken over by a virus,
and the people of the colony are mind-controlled by an alien remnant. There's
even a bit of "caring for someone gives you power over them" included when the
humans risk their lives to rescue Murderbot.

{{ this_book }} introduces some new characters. Murderbot 2.0 is a copy of
Murderbot's mind used as a virus, a trick it learned in {{ mb4 }}. The book
lightly touches on whether the copy is still Murderbot, a question that shows
up in other sci-fi like {{ pandora }} and {{ bobiverse_one }}. {{ this_book }}
reaches roughly the same conclusion as {{ empire }}: the copy isn't really
you, because your nervous system is part of who you are, and that is not
duplicated.

SecUnit 3 is another unit that Murderbot convinces to help out by sharing
memories. Three acts as a mirror for Murderbot, letting it see how it behaved
and felt right after it first gained freedom.

{{ this_book }} reminded me of some other works:

- The `HelpMe.file` used to tell a parallel story reminds me of how {{
  brunner }} builds his world through in-universe media in {{ zanzibar }}.

- The alien-infected humans fighting a war amongst themselves while taking
  human hostages was similar to {{ close_to_critical }} and {{ dragons_egg }}.

- The alien virus taking over people's minds was like the Blight from {{
  fire_deep }}.

- Murderbot's greatest fear---being abandoned on a planet---reminded me of {{
  soldier_movie }}, which also explores the theme of a former weapon
  developing emotions and finding community.

This book lives up to the rest of the series, with a great mix of emotion,
action, and worldbuilding. I can't wait to read {{ mb6 }}.
