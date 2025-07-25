---
date: 2025-06-04
title: Shards of Earth
book_authors: Adrian Tchaikovsky
series: The Final Architecture
book_number: 1
rating: 3
image: /books/covers/shards_of_earth.jpg
---

<cite class="book-title">{{ page.title }}</cite>, by <span
class="author-name">{{ page.book_authors }}</span>, is the first book in the
<span class="book-series">{{ page.series }}</span> series. It follows Idris,
Solace, and the crew of the _Vulture God_ as the Architects return and restart
their genocidal campaign against humanity.

{% capture this_book %}<cite class="book-title">{{ page.title }}</cite>{% endcapture %}
{% capture the_author %}<span class="author-name">{{ page.book_authors }}</span>{% endcapture %}
{% capture the_authors_lastname %}<span class="author-name">{{ page.book_authors | split: " " | last }}</span>{% endcapture %}
{% capture the_authors %}{% author_link page.book_authors possessive %}{% endcapture %}
{% capture the_author_link %}{% author_link page.book_authors %}{% endcapture %}
{% capture this_series %}{% series_text page.series %}{% endcapture %}

{% capture fa2 %}{% book_link "Eyes of the Void" %}{% endcapture %}
{% capture fa3 %}{% book_link "Lords of Uncreation" %}{% endcapture %}

{% capture herberts %}{% author_link "Frank Herbert" possessive %}{% endcapture %}
{% capture dune %}{% book_link "Dune" %}{% endcapture %}
{% capture dune_messiah %}{% book_link "Dune Messiah" %}{% endcapture %}

{% capture reynoldss %}{% author_link "Alastair Reynolds" possessive %}{% endcapture %}
{% capture suns %}{% book_link "House of Suns" %}{% endcapture %}

{% capture wellss %}{% author_link "H. G. Wells" possessive %}{% endcapture %}
{% capture wotw %}{% book_link "The War of the Worlds" %}{% endcapture %}

{% capture culture_series %}{% series_link "Culture" %}{% endcapture %}

{% capture pandora %}{% book_link "Pandora's Star" %}{% endcapture %}
{% capture hamiltons %}{% author_link "Peter F. Hamilton" possessive %}{% endcapture %}

{% capture mb_series %}{% series_link "The Murderbot Diaries" %} series{% endcapture %}

{% capture wh40k %}<cite class="table-top-game-title">Warhammer 40,000</cite>{% endcapture %}
{% capture fortyk %}<cite class="table-top-game-title">40k</cite>{% endcapture %}
{% capture battletech %}<cite class="table-top-game-title">BattleTech</cite>{% endcapture %}

{% capture star_trek_4 %}<cite class="movie-title">Star Trek IV: The Voyage Home</cite>{% endcapture %}

{% capture mass_effect %}<cite class="video-game-title">Mass Effect</cite>{% endcapture %}
{% capture halo %}<cite class="video-game-title">Halo</cite>{% endcapture %}
{% capture disco_elysium %}{% book_link "Disco Elysium"%}{% endcapture %}

{% capture bolo1 %}{% book_link "Bolo: Annals of the Dinochrome Brigade" %}{% endcapture %}
{% capture bolo2 %}{% book_link "Rogue Bolo" %}{% endcapture %}

The plot centers on the ragtag crew of the _Vulture God_ as they get pulled
into a galaxy-spanning conspiracy. The Architects---moon-sized beings that
reshape worlds into fractals---have returned, and only psychic humans called
Intermediaries (Ints) can stop them. The _Vulture_ just happens to have Idris,
one of the last surviving Ints from the first war, so everyone is after them.
The ship and crew remind me a lot of Han and the crew of the _Millennium
Falcon_ or Mal and the crew of the _Firefly_: simple people dragged into
something much larger.

The best part of {{ this_book }} is the story---it kept me turning pages to see
what happened next, the same way {{ hamiltons }} writing did in {{ pandora }}.
The universe is interesting, but feels [derivative of earlier
works][influences]. And despite the scale of destruction---whole planets
annihilated by the Architects---the emotional impact is missing. Billions die,
but since no one we know is threatened, it doesn't have any weight. That shows
up elsewhere too: although the story has galactic scale, the conflict and
universe feel small. The crew hops from place to place, each stop just another
short-lived adventure (with twist after twist), before flying off again. In
fact, the twists became so routine they were predictable: the crew's in
inescapable trouble? They're about to get bailed out---sometimes multiple times
in a row!---by one of their pursuers.

[influences]: #influences

The worst part is the writing. It's workmanlike, and similar to but not nearly
as bad as {{ reynoldss }} {{ suns }}. The author just doesn't trust the reader
to pick up on things. Instead of subtle world-building, he lore-dumps. {{
the_authors_lastname }} repeats information so much I started wondering if I'd
accidentally flipped back a few pages. One especially bad example: {{
the_authors_lastname }} sets up a motif around spacer funerals, uses it again
for Idris before he heads out on a suicide mission, and _then_ immediately has
one of the characters explain the motif.

### Influences

{{ this_book }} draws heavily from earlier sci-fi:

Unspace is an alternate dimension for faster-than-light travel that is
essentially the Warp from {{ wh40k }}: a dangerous realm that drives people
insane, is home to a dark entity, and requires psychics to navigate. The Ints
required to do so are modeled on the Guild Navigators from {{ herberts }} {{
dune }}. The influence is even clearer with the Hegemony's whale-like Ogdru
navigators, matching the "fish-like" Guild Navigators as described in {{
dune_messiah }}.

The space physics feels familiar as well, with the way ships gain traction
against the boundary with Unspace similar to how {{ culture_series }} ships
maneuver using the Grid. And the idea that intelligence warps Unspace, much
like mass warps spacetime, suggests the Architects are destroying life to stop
its mental "pollution"; similar to how human thought creates the all-consuming
Pale in {{ disco_elysium }}.

The genetically engineered warrior women of the Parthenon are a blend of {{
dune }}'s Fish Speakers, the Adepta Sororitas from {{ fortyk }}, and the
tank-born Clans from {{ battletech }}. Solace's teardrop face tattoo mirrors the
Sororitas's fleur-de-lis.

The Architects are a mash-up of the whale probe from {{ star_trek_4 }} and the
Reapers from {{ mass_effect }}. {{ the_authors_lastname }} makes the homage
clear with a line about the Architects's signal being "...solitary and
singular as a whale song..."

The Essiel Hegemony is a lot like the Covenant from {{ halo }}---both are
multi-species empires, more advanced than humanity, with each species filling
a set role. The huge alien cast also gave me strong {{ mass_effect }} vibes.

The book also borrows from early 20th-century history. The dueling culture and
honorable scars come straight from [academic fencing][ds] in Germany and
Austria. The Boyar from Magdan are lifted from [Eastern European
nobility][boyars]. The Nativists and their extremist faction, The Betrayed,
are the [Nazis][nazis], complete with the ["stab-in-the-back" myth][sitb]. The
apocalyptic war, followed by shaky peace and then another war, is basically
[WWI][wwi] and [WWII][wwii].

[ds]: https://en.wikipedia.org/wiki/Dueling_scar
[boyars]: https://en.wikipedia.org/wiki/Boyar
[nazis]: https://en.wikipedia.org/wiki/Nazism
[sitb]: https://en.wikipedia.org/wiki/Stab-in-the-back_myth
[wwi]: https://en.wikipedia.org/wiki/World_War_I
[wwii]: https://en.wikipedia.org/wiki/World_War_II

And possibly a hint for how the series will turn out: {{ the_author }} names
one of the Parthenon ships the _Thunderchild_, a direct reference to the
battleship from {{ wellss }} {{ wotw }}, another story where a seemingly
invincible alien force is ultimately defeated by something small and
overlooked.

### Book Club

I read this for my book club, and I liked it enough that I'm going to read {{
fa2 }} and {{ fa3 }}. But I'm taking a break first to read {{ bolo1 }} and {{
bolo2 }}, and maybe a few more from the {{ mb_series }}.
