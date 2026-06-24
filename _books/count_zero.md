---
date: 2026-06-22 21:47:57 -0700
title: Count Zero
book_authors: William Gibson
series: Sprawl
book_number: 2
is_anthology: false
rating: 5
image: /books/covers/count_zero.jpg
wikidata_qid: Q2384854
isbn: 978-0-87795-793-7
date_published: 1986-03
same_as_urls:
  - "https://www.wikidata.org/wiki/Q2384854"
  - "https://en.wikipedia.org/wiki/Count_Zero"
  - "https://openlibrary.org/works/OL27256W"
  - "https://www.isfdb.org/cgi-bin/title.cgi?2195"
  - "https://www.britannica.com/topic/Count-Zero"
  - "https://www.librarything.com/work/2445"
  - "https://www.google.com/search?kgmid=/m/01z439"
---

{% book_link page.title %}, by {% author_link page.book_authors link=false %}, is the second book in {% series_text page.series link=false %}.

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

{% capture neuromancer %}{% book_link "Neuromancer" %}{% endcapture %}
{% capture mona_lisa_overdrive %}{% book_link "Mona Lisa Overdrive" %}{% endcapture %}

{% capture stross %}{% author_link "Charles Stross" %}{% endcapture %}
{% capture strosss %}{% author_link "Charles Stross" possessive %}{% endcapture %}
{% capture stross_lastname %}{% author_link "Charles Stross" link_text="Stross" %}{% endcapture %}
{% capture strosss_lastname %}{% author_link "Charles Stross" link_text="Stross" possessive %}{% endcapture %}
{% capture accelerando %}{% book_link "Accelerando" %}{% endcapture %}

{% capture stephenson %}{% author_link "Neal Stephenson" %}{% endcapture %}
{% capture stephensons %}{% author_link "Neal Stephenson" possessive %}{% endcapture %}
{% capture stephenson_lastname %}{% author_link "Neal Stephenson" link_text="Stephenson" %}{% endcapture %}
{% capture stephensons_lastname %}{% author_link "Neal Stephenson" link_text="Stephenson" possessive %}{% endcapture %}
{% capture snow_crash %}{% book_link "Snow Crash" %}{% endcapture %}

{% capture williams %}{% author_link "Walter Jon Williams" %}{% endcapture %}
{% capture williamss %}{% author_link "Walter Jon Williams" possessive %}{% endcapture %}
{% capture williams_lastname %}{% author_link "Walter Jon Williams" link_text="Williams" %}{% endcapture %}
{% capture williamss_lastname %}{% author_link "Walter Jon Williams" link_text="Williams" possessive %}{% endcapture %}
{% capture metropolitan_series %}{% series_link "Metropolitan" %}{% endcapture %}
{% capture city_on_fire %}{% book_link "City on Fire" %}{% endcapture %}

{% capture simmons %}{% author_link "Dan Simmons" %}{% endcapture %}
{% capture simmonss %}{% author_link "Dan Simmons" possessive %}{% endcapture %}
{% capture simmons_lastname %}{% author_link "Dan Simmons" link_text="Simmons" %}{% endcapture %}
{% capture simmonss_lastname %}{% author_link "Dan Simmons" link_text="Simmons" possessive %}{% endcapture %}
{% capture cantos %}{% series_link "Hyperion Cantos" %}{% endcapture %}
{% capture hyperion %}{% book_link "Hyperion" %}{% endcapture %}

{% capture wolfe %}{% author_link "Gene Wolfe" %}{% endcapture %}
{% capture wolfes %}{% author_link "Gene Wolfe" possessive %}{% endcapture %}
{% capture wolfe_lastname %}{% author_link "Gene Wolfe" link_text="Wolfe" %}{% endcapture %}
{% capture wolfes_lastname %}{% author_link "Gene Wolfe" link_text="Wolfe" possessive %}{% endcapture %}
{% capture botns %}{% series_link "The Book of the New Sun" %}{% endcapture %}
{% capture the_shadow_of_the_torturer %}{% book_link "The Shadow of the Torturer" %}{% endcapture %}

{% capture watts %}{% author_link "Peter Watts" %}{% endcapture %}
{% capture wattss %}{% author_link "Peter Watts" possessive %}{% endcapture %}
{% capture watts_lastname %}{% author_link "Peter Watts" link_text="Watts" %}{% endcapture %}
{% capture wattss_lastname %}{% author_link "Peter Watts" link_text="Watts" possessive %}{% endcapture %}
{% capture firefall %}{% series_link "Firefall" %}{% endcapture %}
{% capture echopraxia %}{% book_link "Echopraxia" %}{% endcapture %}

{% capture black_mirror %}{% tv_show_title "Black Mirror" %}{% endcapture %}
{% capture ds9 %}{% tv_show_title "Deep Space Nine" %}{% endcapture %}
{% capture soylent_green %}{% movie_title "Soylent Green" %}{% endcapture %}
{% capture the_matrix %}{% movie_title "The Matrix" %}{% endcapture %}

I've been on a bit of a cyberpunk kick recently, reading {{ neuromancer }}
(which I loved!) in order to prepare myself to re-read {{ snow_crash }}. In
doing so, I realized {{ accelerando }} is more punk than I'd given it credit
for.
