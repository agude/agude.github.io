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
is the third book in {% series_text page.series link=false %}.

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

{% capture neuromancer %}{% book_link "Neuromancer" %}{% endcapture %}
{% capture count_zero %}{% book_link "Count Zero" %}{% endcapture %}

{% capture simmons %}{% author_link "Dan Simmons" %}{% endcapture %}
{% capture simmonss %}{% author_link "Dan Simmons" possessive %}{% endcapture %}
{% capture simmons_lastname %}{% author_link "Dan Simmons" link_text="Simmons" %}{% endcapture %}
{% capture simmonss_lastname %}{% author_link "Dan Simmons" link_text="Simmons" possessive %}{% endcapture %}
{% capture hyperion_cantos %}{% series_link "Hyperion Cantos" %}{% endcapture %}
{% capture hyperion %}{% book_link "Hyperion" %}{% endcapture %}
{% capture the_fall_of_hyperion %}{% book_link "The Fall of Hyperion" %}{% endcapture %}

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

### What Remains

The first two books of {{ this_series }} felt cohesive: they're both thrillers
about surviving in a post-human world of AI and mega-corporations. But each is
subtly different: {{ neuromancer }} is about bad-asses in space; {{ count_zero
}} is about more normal people encountering the seemingly divine. {{ this_book
}} brings the two plots together---3Jane and Tessier-Ashpool in their quest
for immortality at Villa Straylight; Bobby, Angela, and the newly released Loa
in the Matrix.

Each books asks a different question: {{ neuromancer }}: what do you lose when
you become more than human. It is about the body: Case hates his, Molly has
transformed hers, Linda loses hers but is saved within the Neuromancer AI. {{
count_zero }}: what does inhuman power looks like from below. It asks how
humans understand transhuman beings; its answer is "religion". {{ this_book
}}: what remains of you when your humanity is gone. It is the synthesis of the
other two: it is about memory, or, fitting with the religious parallels, soul.

This theme start in {{ neuromancer }} with Dixie Flatline, the mindstate of a
dead hacker's stored in ROM, and with the Tessier and her Neuromancer AI which
was designed to store human consciousnesses. In {{ this_book }}, memory is
everywhere. The Finn is now a construct like Flatline, but mixed with the
religion of {{ count_zero }}: the locals treat him as an oracle and leave
Vodou offerings. Slick, the ex-con, has short term memory loss inflicted on
him as part of his punishment. The Yakuza keep their former bosses'
consciousnesses in cubes to ask questions of.
