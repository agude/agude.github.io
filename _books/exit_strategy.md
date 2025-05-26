---
date: 2025-05-23 14:56:00 -0700
title: Exit Strategy
book_author: Martha Wells
series: The Murderbot Diaries
book_number: 4
rating: 5
image: /books/covers/exit_strategy.jpg
---

<cite class="book-title">{{ page.title }}</cite>, by <span
class="author-name">{{ page.book_author }}</span>, is the forth book in the
<span class="book-series">{{ page.series }}</span>. It closes out the GrayCris
storyline as Murderbot returns to rescue its friends.

{% capture this_book %}<cite class="book-title">{{ page.title }}</cite>{% endcapture %}
{% capture the_author %}<span class="author-name">{{ page.book_author }}</span>{% endcapture %}
{% capture the_authors_lastname %}<span class="author-name">{{ page.book_author | split: " " | last }}</span>{% endcapture %}
{% capture the_authors %}{% author_link page.book_author possessive %}{% endcapture %}
{% capture the_author_link %}{% author_link page.book_author %}{% endcapture %}
{% capture this_series %}{% series_text page.series %}{% endcapture %}

{% capture mb1 %}{% book_link "All Systems Red" %}{% endcapture %}
{% capture mb2 %}{% book_link "Artificial Condition" %}{% endcapture %}
{% capture mb3 %}{% book_link "Rogue Protocol" %}{% endcapture %}
{% capture mb4_5 %}{% book_link "Home: Habitat, Range, Niche, Territory" %}{% endcapture %}

{% capture smiths %}{% author_link "L. Neil Smith" possessive %}{% endcapture %}
{% capture probability_broach %}{% book_link "The Probability Broach" %}{% endcapture %}

{% capture surface %}{% book_link "Surface Detail" %}{% endcapture %}
{% capture fall %}{% book_link "The Fall of Hyperion" %}{% endcapture %}

{% capture tchaikovskys %}{% author_link "Adrian Tchaikovsky" possessive %}{% endcapture %}
{% capture shards %}{% book_link "Shards of Earth" %}{% endcapture %}
{% capture architecture %}{% series_text "The Final Architecture" %}{% endcapture %}

{{ this_book }} is the climax of the first four books in {{ this_series }},
where Murderbot has the most to lose. It concludes the GrayCris storyline that
began in {{ mb1 }}, when Dr. Ayda Mensah and her team were saved by Murderbot
and then set it free.

In this book, Murderbot learns that Mensah has been kidnapped by GrayCris and
imprisoned at their corporate headquarters. It quickly realizes that its
exploration of the alien-artifact mining station spooked GrayCris and pushed
them to take desperate action. Murderbot returns to the Corporation Rim,
rescues its old team, and extracts with Mensah. Along the way, it confronts
its own deathwish while fighting a combat SecUnit, and learns that sometimes
you have to run. There's a lot of satisfying action as Murderbot saves its
friends again and again.

The theme of Murderbot's relationship with humans and humanity continues from
{{ mb3 }}. It has conflicted emotions after learning that SecUnits used to be
more human and had closer relationships with their clients. And it's finally
starting to accept that its need to protect people is a core part of who it is
---not just leftover programming.

The detailed view of the "libertarian paradise" that is the Corporation Rim
reminded me of {{ smiths }} (horrible) {{ probability_broach }}, which paints
an idealized version of what a libertarian world would look like---so extreme
it almost reads as satire. {{ the_authors_lastname }}'s version feels closer
to reality. The hacking-as-combat parts, where code has a "physical" presence
in the world, reminded me of similar scenes in {{ surface }} and {{ fall }}.

Next up is the short story {{ mb4_5 }} before starting {{ tchaikovskys }} {{
architecture }} with {{ shards }}.
