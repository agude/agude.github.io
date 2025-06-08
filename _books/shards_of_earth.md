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
<span class="book-series">{{ page.series }}</span>. It follows Idris, Solace,
and the crew of the _Vulture God_ as the Architects return and begin their
genocide of humanity again.

{% capture this_book %}<cite class="book-title">{{ page.title }}</cite>{% endcapture %}
{% capture the_author %}<span class="author-name">{{ page.book_authors }}</span>{% endcapture %}
{% capture the_authors_lastname %}<span class="author-name">{{ page.book_authors | split: " " | last }}</span>{% endcapture %}
{% capture the_authors %}{% author_link page.book_authors possessive %}{% endcapture %}
{% capture the_author_link %}{% author_link page.book_authors %}{% endcapture %}
{% capture this_series %}{% series_text page.series %}{% endcapture %}

{% capture fa1 %}{% book_link "Shards of Earth" %}{% endcapture %}
{% capture fa2 %}{% book_link "Eyes of the Void" %}{% endcapture %}
{% capture fa3 %}{% book_link "Lords of Uncreation" %}{% endcapture %}

{% capture herberts %}{% author_link "Frank Herbert" possessive %}{% endcapture %}
{% capture dune %}{% book_link "Dune" %}{% endcapture %}
{% capture dune_messiah %}{% book_link "Dune Messiah" %}{% endcapture %}

{% capture heinleins %}{% author_link "Robert A. Heinlein" possessive %}{% endcapture %}
{% capture moon %}{% book_link "The Moon Is a Harsh Mistress" %}{% endcapture %}

{% capture reynoldss %}{% author_link "Alastair Reynolds" possessive %}{% endcapture %}
{% capture suns %}{% book_link "House of Suns" %}{% endcapture %}

{% capture wellss %}{% author_link "H. G. Wells" possessive %}{% endcapture %}
{% capture wotw %}{% book_link "The War of the Worlds" %}{% endcapture %}

{% capture bankss %}{% author_link "Iain M. Banks" possessive %}{% endcapture %}
{% capture culture_series %}{% series_link "Culture" %} series{% endcapture %}
{% capture use_of_weapons %}{% book_link "Use of Weapons" %}{% endcapture %}
{% capture surface_detail %}{% book_link "Surface Detail" %}{% endcapture %}
{% capture matter %}{% book_link "Matter" %}{% endcapture %}

{% capture pandora %}{% book_link "Pandora's Star" %}{% endcapture %}
{% capture hamilton %}{% author_link "Peter F. Hamilton" %}{% endcapture %}
{% capture hamiltons %}{% author_link "Peter F. Hamilton" possessive %}{% endcapture %}
{% capture commonwealth_saga %}{% series_link "Commonwealth Saga" %}{% endcapture %}

{% capture martha_wellss %}{% author_link "Martha Wells" possessive %}{% endcapture %}
{% capture mb_series %}{% series_link "The Murderbot Diaries" %} series{% endcapture %}

{% capture wh40k %}<cite class="table-top-game-title">Warhammer 40,000</cite>{% endcapture %}
{% capture fortyk %}<cite class="table-top-game-title">40k</cite>{% endcapture %}
{% capture battletech %}<cite class="table-top-game-title">BattleTech</cite>{% endcapture %}

{% capture star_wars %}<cite class="movie-title">Star Wars</cite>{% endcapture %}
{% capture star_trek_4 %}<cite class="movie-title">Star Trek IV: The Voyage Home</cite>{% endcapture %}
{% capture firefly %}<cite class="tv-show-title">Firefly</cite>{% endcapture %}

{% capture mass_effect %}<cite class="video-game-title">Mass Effect</cite>{% endcapture %}
{% capture halo %}<cite class="video-game-title">Halo</cite>{% endcapture %}
{% capture disco_elysium %}<cite class="video-game-title">Disco Elysium</cite>{% endcapture %}

{% capture bolo1 %}{% book_link "Bolo: Annals of the Dinochrome Brigade" %}{% endcapture %}
{% capture bolo2 %}{% book_link "Rogue Bolo" %}{% endcapture %}

{{ this_book }} follows the ragtag crew of the _Vulture God_ as they get
pulled into a galaxy-spanning conspiracy---similar to Luke, Leia, Han, and
Chewie in the _Millennium Falcon_ or Mal and the crew of the _Firefly_. The
Architects---moon-sized beings that rip worlds into geometric shapes---have
returned and only psychic humans called Intermediaries (Ints) can stop them.
The _Vulture_ just happens to have Idris, one of the last surviving Ints from
the first war, so everyone is after them.

The best part of {{ this_book }} is the story, which kept me turning the pages
to find out what happened next, just like {{ hamilton }} at his best in {{
pandora }}. The universe is relatively interesting, but feels [derivative of
earlier works][influences]. It also feels small, because the heroes jump from
place to place, have a quick adventure (with twist after twist), before flying
off. In fact, the twists were so constant that they became predictable: The
crew is in inescapable trouble? They're about to be bailed out by one of the
other parties showing up out of nowhere!

[influences]: #influences

The worst part is the writing. {{ the_author }} doesn't trust the reader to
pick up what's going on, so instead of subtle world-building or motifs, he
lore-dumps. It is the same complaint I have about {{ reynoldss }} {{ suns }},
although that case is far worse. {{ the_authors_lastname }} repeats pieces of
information over and over until I wondered if I had accidentally gone back a
few pages. A particularly bad example is how {{ the_authors_lastname }} sets
up a motif of spacer funerals, then uses the same motif for Idris before he
heads out on a suicide mission, and _then_ has one of the characters explain
that's what the author is doing.

### Influences

{{ this_book }} was heavily influenced by the works that came before it:

Unspace is an alternate dimension that allows faster-than-light travel, but
drives people insane, requires psychics to navigate, and is the home of some
dark entity. This is essentially the Warp directly from {{ wh40k }}. The
psychic Ints needed to navigate Unspace are modeled on the Guild Navigators
from {{ herberts }} {{ Dune }}---which in turn are the source for {{ fortyk }}
psyker navigators. The Ogdru are whale-like navigators used by the Hegemony,
which is similar to the description of navigators in {{ dune_messiah }} as
"fish-like," swimming in their spice tanks. The way ships get "traction" on
the layer between space and unspace is similar to how {{ culture_series }}
ships get traction on the grid. The fact that intelligence seems to warp
Unspace---like mass does real space---feels akin to how thought creates the
Pale in {{ disco_elysium }}.

The genetically modified, warrior women of the Parthenon are modeled on the
Fish Speakers from {{ dune }}, the Adepta Sororitas from {{ fortyk }}, and the
Clans with their tank-grown warriors from {{ battletech }}. Solace has a
facial tattoo---a teardrop---like the Sororitas often have a fleur-de-lis.

The Architects---moon-sized creatures that destroy whole worlds to extinguish
life---are based on the whale-probe from {{ star_trek_4 }} and the Reapers
from {{ mass_effect }}. {{ the_authors_lastname }} makes the homage to the
whale-probe clear by writing that the Architects emit a signal "...solitary
and singular as a whale song...".

The Essiel Hegemony is similar to the Covenant from {{ halo }}. Both are
multi-species empires, technologically more advanced than the humans, and use
different species for very specific roles. The wide variety of aliens in {{
this_book }} felt a lot like {{ mass_effect }} as well.

The book also draws from the early 20th century. The dueling culture with
honorable scars is right out of German and Austrian [academic fencing][ds].
The Boyar from Magdan are [Eastern European nobility][boyars]. The anti-alien
Nativists, and their extremist faction The Betrayed, are the [Nazis][nazis],
complete with their ["stab-in-the-back"][sitb] philosophy of why humanity
failed to defeat the Architects. The apocalyptic war, followed by uneasy
peace, and a repeat of the same war is like [WWI][wwi] and [WWII][wwii].

[ds]: https://en.wikipedia.org/wiki/Dueling_scar
[boyars]: https://en.wikipedia.org/wiki/Boyar
[nazis]: https://en.wikipedia.org/wiki/Nazism
[sitb]: https://en.wikipedia.org/wiki/Stab-in-the-back_myth
[wwi]: https://en.wikipedia.org/wiki/World_War_I
[wwii]: https://en.wikipedia.org/wiki/World_War_II

### Book Club

I read this book for my book club, and I liked it enough that I'm going to
read {{ fa2 }} and {{ fa3 }}. But I'm going to take a break and read {{ bolo1
}} and {{ bolo2 }} first, and maybe some more {{ mb_series }}.
