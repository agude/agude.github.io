---
date: 2025-11-03
title: On Basilisk Station
book_authors: David Weber
series: Honorverse
book_number: 1
is_anthology: false
rating: 4
image: /books/covers/on_basilisk_station.jpg
---

<cite class="book-title">{{ page.title }}</cite>, by <span
class="author-name">{{ page.book_authors }}</span>, is the first book in the
<span class="book-series">{{ page.series }}</span> series.

{% capture this_book %}<cite class="book-title">{{ page.title }}</cite>{% endcapture %}
{% capture the_author %}<span class="author-name">{{ page.book_authors }}</span>{% endcapture %}
{% capture the_authors %}<span class="author-name">{{ page.book_authors }}</span>'s{% endcapture %}
{% capture author_last_name_text %}{{ page.book_authors | split: " " | last }}{% endcapture %}
{% capture the_authors_lastname %}<span class="author-name">{{ page.book_authors | split: " " | last }}</span>{% endcapture %}
{% capture the_authors_lastname_possessive %}<span class="author-name">{{ page.book_authors | split: " " | last }}</span>'s{% endcapture %}
{% capture the_author_link %}{% author_link page.book_authors %}{% endcapture %}
{% capture the_authors_link %}{% author_link page.book_authors possessive %}{% endcapture %}
{% capture the_authors_lastname_link %}{% author_link page.book_authors link_text=author_last_name_text %}{% endcapture %}
{% capture the_authors_lastname_possessive_link %}{% author_link page.book_authors link_text=author_last_name_text possessive %}{% endcapture %}
{% capture this_series %}{% series_text page.series %}{% endcapture %}
{% capture this_series_link %}{% series_link page.series %}{% endcapture %}

{% capture obrians %}{% author_link "Patrick O'Brian" link_text="O'Brian"  possessive %}{% endcapture %}
{% capture aubrey_maturin_series %}{% series_link "Aubrey--Maturin" %} series{% endcapture %}

{% capture foresters %}{% author_link "C. S. Forester" link_text="Forester" possessive %}{% endcapture %}
{% capture hornblower_saga %}{% series_link "Hornblower Saga" %}{% endcapture %}

{% capture bolo12 %}{% book_link "The Triumphant" %}{% endcapture %}
{% capture bolo13 %}{% book_link "Last Stand" %}{% endcapture %}

{% capture last_exile %}<cite class="movie-title">Last Exile</cite>{% endcapture %}

{% capture ds9 %}<cite class="movie-title">Star Trek: Deep Space Nine</cite>{% endcapture %}

{% capture alex %}{% author_link "A. N. Alex" %}{% endcapture %}
{% capture alexs %}{% author_link "A. N. Alex" possessive %}{% endcapture %}
{% capture mote_in_shadow %}{% book_link "A Mote in Shadow" %}{% endcapture %}

{% capture martines %}{% author_link "Arkady Martine" possessive %}{% endcapture %}
{% capture teixcalaan %}{% series_link "Teixcalaan" %}{% endcapture %}

{% capture hamiltons %}{% author_link "Peter F. Hamilton" possessive %}{% endcapture %}
{% capture commonwealth_saga %}{% series_link "Commonwealth Saga" %}{% endcapture %}

{% capture heinlein %}{% author_link "Robert A. Heinlein" %}{% endcapture %}
{% capture heinleins %}{% author_link "Robert A. Heinlein" possessive %}{% endcapture %}
{% capture moon_is_a_harsh_mistress %}{% book_link "The Moon Is a Harsh Mistress" %}{% endcapture %}
{% capture starship_troopers %}{% book_link "Starship Troopers" %}{% endcapture %}

{% capture williams %}{% author_link "Walter Jon Williams" %}{% endcapture %}
{% capture williamss %}{% author_link "Walter Jon Williams" possessive %}{% endcapture %}
{% capture city_on_fire %}{% book_link "City on Fire" %}{% endcapture %}

{% capture tchaikovskys %}{% author_link "Adrian Tchaikovsky" possessive %}{% endcapture %}
{% capture final_architecture %}{% series_link "The Final Architecture" %}{% endcapture %}

{{ the_authors }} {{ this_series_link }} is an age of sails adventure series
like {{ obrians }}  {{ aubrey_maturin_series }} or {{ foresters }} {{
hornblower_saga }}. It follows Honor Harrington as she climbs the ranks of the
Royal Manticoran Navy, which is essentially the Royal Navy with gravity sails,
plasma canons, and missiles.

I loved the parts of {{ this_book }} where Honor and her crew had to work
together to first figure out how to meet their impossible task, and then to
uncover the plot against their empire. It made me think about why I didn't
like the same sort of plot with the rag-tag crew in {{ tchaikovskys }} {{
final_architecture }} as much. In the end I think it comes down to duty,
sacrifice, and competence. Its the difference between military and civilian
sci-fi. <!-- Civilian feels like the wrong word --> I enjoy reading books
about people who work together to become more than they could be alone, or who
are hyper competent, which the crew of the {{ tchaikovskys }} _Vulture God_ do
not and are not.

I know from his short stories in {{ bolo12 }} and {{ bolo13 }} that {{
the_authors_lastname }} can write some fantastic, emotional action set pieces,
but they were absent in {{ on_basilisk_station }}. There was some action, of
course, but it was either quite short---as in the initial fleet trials---or
too long---as in the final desperate chase. In the end, Honor predicted her
enemy's exact plan, but still got her ship blown half to hell.

The Regan Democrat politics {{ the_authors_lastname }} includes in {{
this_book }} age it in the same way that {{ williamss }} [Third
Way][third_way] politics in {{ city_on_fire }} do. Manticore being a space
empire connected by wormholes is like {{ martines }} {{ teixcalaan }} series
and {{ hamiltons }} {{ commonwealth_saga }}. The armored marines bouncing
around blowing stuff up reminded me of {{ starship_troopers }}. The space
physics, especially the FTL exclusion zones around stares, reminded me of {{
mote_in_shadow }}. The interplay between Honor and her subordinates as a
military ship that has to deal with civilians a lot was like {{ ds9 }}.

[third_way]: https://en.wikipedia.org/wiki/Third_Way
