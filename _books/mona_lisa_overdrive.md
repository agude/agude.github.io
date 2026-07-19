---
date: 2026-07-16 18:57:45 -0700
title: Mona Lisa Overdrive
book_authors: William Gibson
series: Sprawl
book_number: 3
is_anthology: false
rating: 5
image: /books/covers/mona_lisa_overdrive.jpg
wikidata_qid: Q663215
isbn: 978-0-553-05250-3
date_published: 1988-10
same_as_urls:
  - "https://www.wikidata.org/wiki/Q663215"
  - "https://en.wikipedia.org/wiki/Mona_Lisa_Overdrive"
  - "https://openlibrary.org/works/OL27253W"
  - "https://www.isfdb.org/cgi-bin/title.cgi?1505"
  - "https://www.britannica.com/topic/Mona-Lisa-Overdrive"
  - "https://www.librarything.com/work/608"
  - "https://www.google.com/search?kgmid=/m/01z43p"
---

{% book_link page.title %}, by {% author_link page.book_authors link=false %},
is the third and final book in {% series_text page.series link=false %}. It
brings together characters from both previous books---Molly, Angela, Bobby,
and the ghost of 3Jane---around a device that can hold the entirety of
cyberspace, and maybe a human soul.

{% capture this_book %}{% book_link page.title %}{% endcapture %}
{% capture the_author %}{% author_link page.book_authors link=false %}{% endcapture %}
{% capture the_authors %}{% author_link page.book_authors link=false possessive %}{% endcapture %}
{% capture author_last_name_text %}{{ page.book_authors | split: " " | last }}{% endcapture %}
{% capture the_authors_lastname %}{% author_link page.book_authors link=false link_text=author_last_name_text %}{% endcapture %}
{% capture the_authors_lastname_possessive %}{% author_link page.book_authors link=false link_text=author_last_name_text possessive %}{% endcapture %}
{% capture the_author_link %}{% author_link page.book_authors %}{% endcapture %}
{% capture the_authors_link %}{% author_link page.book_authors possessive %}{% endcapture %}
{% capture the_authors_lastname_link %}{% author_link page.book_authors link_text=author_last_name_text %}{% endcapture %}
{% capture the_authors_lastname_possessive_link %}{% author_link page.book_authors link_text=author_last_name_text possessive %}{% endcapture %}

{% capture this_series %}{% series_text page.series %}{% endcapture %}
{% capture this_series_cap %}The {% series_link page.series %}{% endcapture %}

{% capture burning_chrome %}{% book_link "Burning Chrome" %}{% endcapture %}
{% capture neuromancer %}{% book_link "Neuromancer" %}{% endcapture %}
{% capture count_zero %}{% book_link "Count Zero" %}{% endcapture %}

{% capture simmons %}{% author_link "Dan Simmons" %}{% endcapture %}
{% capture simmonss %}{% author_link "Dan Simmons" possessive %}{% endcapture %}
{% capture simmons_lastname %}{% author_link "Dan Simmons" link_text="Simmons" %}{% endcapture %}
{% capture simmonss_lastname %}{% author_link "Dan Simmons" link_text="Simmons" possessive %}{% endcapture %}
{% capture hyperion_cantos %}{% series_link "Hyperion Cantos" %}{% endcapture %}
{% capture hyperion %}{% book_link "Hyperion" %}{% endcapture %}
{% capture the_fall_of_hyperion %}{% book_link "The Fall of Hyperion" %}{% endcapture %}

{% capture keatss %}{% author_link "John Keats" possessive %}{% endcapture %}
{% capture keats_lastname %}{% author_link "Keats" %}{% endcapture %}
{% capture keatss_lastname %}{% author_link "Keats" possessive %}{% endcapture %}
{% capture poem %}{% book_link "The Fall of Hyperion: A Dream" %}{% endcapture %}
{% capture hyperion_keats %}{% book_link "Hyperion" author="John Keats" %}{% endcapture %}

{% capture borges %}{% author_link "Jorge Luis Borges" %}{% endcapture %}
{% capture borgess %}{% author_link "Jorge Luis Borges" possessive %}{% endcapture %}
{% capture borges_lastname %}{% author_link "Jorge Luis Borges" link_text="Borges" %}{% endcapture %}
{% capture borgess_lastname %}{% author_link "Jorge Luis Borges" link_text="Borges" possessive %}{% endcapture %}
{% capture the_aleph %}{% short_story_link "The Aleph" %}{% endcapture %}

{% capture stephenson %}{% author_link "Neal Stephenson" %}{% endcapture %}
{% capture stephensons %}{% author_link "Neal Stephenson" possessive %}{% endcapture %}
{% capture stephenson_lastname %}{% author_link "Neal Stephenson" link_text="Stephenson" %}{% endcapture %}
{% capture stephensons_lastname %}{% author_link "Neal Stephenson" link_text="Stephenson" possessive %}{% endcapture %}
{% capture snow_crash %}{% book_link "Snow Crash" %}{% endcapture %}

{% capture cline %}{% author_link "Ernest Cline" %}{% endcapture %}
{% capture clines %}{% author_link "Ernest Cline" possessive %}{% endcapture %}
{% capture cline_lastname %}{% author_link "Ernest Cline" link_text="Cline" %}{% endcapture %}
{% capture clines_lastname %}{% author_link "Ernest Cline" link_text="Cline" possessive %}{% endcapture %}
{% capture ready_player_one %}{% book_link "Ready Player One" %}{% endcapture %}

{% capture watts %}{% author_link "Peter Watts" %}{% endcapture %}
{% capture wattss %}{% author_link "Peter Watts" possessive %}{% endcapture %}
{% capture watts_lastname %}{% author_link "Peter Watts" link_text="Watts" %}{% endcapture %}
{% capture wattss_lastname %}{% author_link "Peter Watts" link_text="Watts" possessive %}{% endcapture %}
{% capture blindsight %}{% book_link "Blindsight" %}{% endcapture %}

{% capture stross %}{% author_link "Charles Stross" %}{% endcapture %}
{% capture strosss %}{% author_link "Charles Stross" possessive %}{% endcapture %}
{% capture stross_lastname %}{% author_link "Charles Stross" link_text="Stross" %}{% endcapture %}
{% capture strosss_lastname %}{% author_link "Charles Stross" link_text="Stross" possessive %}{% endcapture %}
{% capture accelerando %}{% book_link "Accelerando" %}{% endcapture %}

{% capture an_alex %}{% author_link "A. N. Alex" %}{% endcapture %}
{% capture an_alexs %}{% author_link "A. N. Alex" possessive %}{% endcapture %}
{% capture an_alex_lastname %}{% author_link "A. N. Alex" link_text="Alex" %}{% endcapture %}
{% capture an_alexs_lastname %}{% author_link "A. N. Alex" link_text="Alex" possessive %}{% endcapture %}
{% capture a_mote_in_shadow %}{% book_link "A Mote in Shadow" %}{% endcapture %}

{% capture disco_elysium %}{% book_link "Disco Elysium" %}{% endcapture %}

{% capture the_matrix %}{% movie_title "The Matrix" %}{% endcapture %}

{% capture colossus %}{% movie_title "Colossus: The Forbin Project" %}{% endcapture %}
{% capture jones %}{% author_link "D. F. Jones" %}{% endcapture %}
{% capture joness %}{% author_link "D. F. Jones" possessive %}{% endcapture %}
{% capture jones_lastname %}{% author_link "D. F. Jones" link_text="Jones" %}{% endcapture %}
{% capture joness_lastname %}{% author_link "D. F. Jones" link_text="Jones" possessive %}{% endcapture %}
{% capture colossus_book %}{% book_link "Colossus" %}{% endcapture %}

The first two books of {{ this_series }} are both thrillers about surviving in
a post-human world of AI and mega-corporations, but each is subtly different:
{{ neuromancer }} is about bad-asses in space; {{ count_zero }} is about
normal people encountering the seemingly divine. I wasn't sure what {{
this_book }} would be. It could have been a third variation. Instead it ties
both together, capping off their plots and storylines.

Bobby is the clearest example. In {{ count_zero }} he's the anti-Case---a teen
playing at being a cowboy, nearly killed on his first run. But by {{ this_book
}}, he becomes what Case always wanted: a mind fully in cyberspace, body left
behind in a coma. Molly returns from {{ neuromancer }} and {{ burning_chrome
}}, the same no-nonsense street samurai. Angela, whose modified brain was a
key plot point in {{ count_zero }}, is now the world's biggest simstim star.
And there's Slick, a new character but familiar archetype, an artist
assembling junk into memory-preserving robots in the wastelands of New Jersey.
{{ the_author }} brings these four threads together, and in doing so answers a
question the trilogy set up from the beginning.

### What Remains

Each book in {{ this_series }} asks a different question. {{ neuromancer }}:
what do you lose when you become more than human? It's about the body: Case
hates his, Molly has transformed hers, Linda loses hers but is saved within
the Neuromancer AI. {{ count_zero }}: what does inhuman power look like from
below? It asks how humans understand transhuman beings; its answer is
"religion". {{ this_book }}: what remains of you when your humanity is gone?
It's the synthesis of the other two: it's about memory, or, fitting with the
religious parallels, soul.

This theme starts in {{ neuromancer }} with Dixie Flatline, the mindstate of a
dead hacker stored in ROM, and with Tessier-Ashpool's Neuromancer AI, which
was designed to store human consciousnesses. In {{ this_book }}, memory is
everywhere. The Finn is now a construct like Flatline, but mixed with the
religion of {{ count_zero }}: the locals treat him as an oracle and leave
Vodou offerings. Slick, the ex-con, has short-term memory loss inflicted on
him as part of his punishment. The Yakuza keep their former bosses'
consciousnesses in cubes to ask questions of. Kumiko's ghost boy has had his
memory altered, adding in parts he'll need to keep her safe. And finally, The
Count, Angela, and 3Jane are using the Aleph---a computer that contains a
simulation of the entire world, based on {{ borgess_lastname }} {{ the_aleph
}}---to "catch their souls" and store them.

Complementing the theme of memory is _[gomi][gomi]_, which is how Kumiko
refers to all the antiques, knickknacks, and other pieces of the past that
litter England. These are the memory of the real world. Tokyo is built on
layers and layers of _gomi_. The New Jersey Solitude, where Slick's factory
is, is literally a toxic dump; Slick takes pieces of that _gomi_ and makes
kinetic sculptures that help him retain his memory. London is a sunsetting
empire clinging to its past through objects. In {{ neuromancer }},
Tessier-Ashpool hoards that past, cutting it to pieces and filing it away in
Straylight without reason; in {{ count_zero }} the box-maker robot sorts
through the refuse and creates art; in {{ this_book }} 3Jane has gone from
physical to virtual: cramming the entire world into the Aleph.

[gomi]: https://en.wiktionary.org/wiki/%E3%82%B4%E3%83%9F

### Influences

{{ this_book }} reminded me of some other works. The way history has a
physicality in layers of _gomi_ is similar to how the weight of history is
represented by the pale in {{ disco_elysium }}, although the pale erases while
_gomi_ builds. The Aleph is like an inversion of {{ the_matrix }}---the entire
world virtualized, but for Case it's an escape instead of the prison it is for
Neo. The way the combined Neuromancer+Wintermute AI woke up and then
immediately discovered there is another matrix is like Colossus waking up and
discovering the Soviet AI Guardian in {{ colossus }} (based on {{
joness_lastname }} {{ colossus_book }}). 3Jane's scheme executing autonomously
after her death is like the self-directed corporations from {{
strosss_lastname }} {{ accelerando }}. The Gentleman Loser bar where hackers
hang out reminds me of the Black Sun in {{ stephensons_lastname }} {{
snow_crash }}. Angela's mind containing two personalities is like Susan Bates
with her three personalities in {{ wattss_lastname }} {{ blindsight }}. The
modular buildings where Mona gets her surgery are like the stacks in {{
clines_lastname }} {{ ready_player_one }}. The jive handsigns are similar to
the pronoun waves in {{ an_alexs_lastname }} {{ a_mote_in_shadow }}.
