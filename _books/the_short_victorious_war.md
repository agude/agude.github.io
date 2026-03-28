---
date: 2026-03-25 21:45:04 -0700
title: The Short Victorious War
book_authors: David Weber
series: Honor Harrington
book_number: 3
is_anthology: false
rating: 4
image: /books/covers/the_short_victorious_war_first_edition.jpg
wikidata_qid: Q3549538
isbn: 978-0-671-87596-1
date_published: 1994-04
same_as_urls:
  - "https://www.wikidata.org/wiki/Q3549538"
  - "https://en.wikipedia.org/wiki/The_Short_Victorious_War"
  - "https://openlibrary.org/works/OL15401158W"
  - "https://www.isfdb.org/cgi-bin/title.cgi?5860"
  - "https://www.librarything.com/work/34930"
  - "https://www.google.com/search?kgmid=/m/04xllk"
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

{% capture hh1 %}{% book_link "On Basilisk Station" %}{% endcapture %}
{% capture hh2 %}{% book_link "The Honor of the Queen" %}{% endcapture %}
{% capture hh3 %}{% book_link "The Short Victorious War" %}{% endcapture %}
{% capture hh4 %}{% book_link "Field of Dishonor" %}{% endcapture %}

{% capture orwell %}{% author_link "George Orwell" %}{% endcapture %}
{% capture orwells %}{% author_link "George Orwell" possessive %}{% endcapture %}
{% capture orwell_lastname %}{% author_link "George Orwell" link_text="Orwell" %}{% endcapture %}
{% capture orwells_lastname %}{% author_link "George Orwell" link_text="Orwell" possessive %}{% endcapture %}
{% capture nineteen_eighty_four %}{% book_link "1984" %}{% endcapture %}

{% capture benford %}{% author_link "Gregory Benford" %}{% endcapture %}
{% capture benfords %}{% author_link "Gregory Benford" possessive %}{% endcapture %}
{% capture benford_lastname %}{% author_link "Gregory Benford" link_text="Benford" %}{% endcapture %}
{% capture benfords_lastname %}{% author_link "Gregory Benford" link_text="Benford" possessive %}{% endcapture %}
{% capture eater %}{% book_link "Eater" %}{% endcapture %}

{% capture williams %}{% author_link "Walter Jon Williams" %}{% endcapture %}
{% capture williamss %}{% author_link "Walter Jon Williams" possessive %}{% endcapture %}
{% capture williams_lastname %}{% author_link "Walter Jon Williams" link_text="Williams" %}{% endcapture %}
{% capture williamss_lastname %}{% author_link "Walter Jon Williams" link_text="Williams" possessive %}{% endcapture %}
{% capture metropolitan_series %}{% series_link "Metropolitan" %}{% endcapture %}
{% capture city_on_fire %}{% book_link "City on Fire" %}{% endcapture %}

{% capture tchaikovsky %}{% author_link "Adrian Tchaikovsky" %}{% endcapture %}
{% capture tchaikovskys %}{% author_link "Adrian Tchaikovsky" possessive %}{% endcapture %}
{% capture tchaikovsky_lastname %}{% author_link "Adrian Tchaikovsky" link_text="Tchaikovsky" %}{% endcapture %}
{% capture tchaikovskys_lastname %}{% author_link "Adrian Tchaikovsky" link_text="Tchaikovsky" possessive %}{% endcapture %}
{% capture the_final_architecture %}{% series_link "The Final Architecture" %}{% endcapture %}

{% capture clancy %}{% author_link "Tom Clancy" %}{% endcapture %}
{% capture clancys %}{% author_link "Tom Clancy" possessive %}{% endcapture %}
{% capture clancy_lastname %}{% author_link "Tom Clancy" link_text="Clancy" %}{% endcapture %}
{% capture clancys_lastname %}{% author_link "Tom Clancy" link_text="Clancy" possessive %}{% endcapture %}

{% capture homer %}{% author_link "Homer" %}{% endcapture %}
{% capture homers %}{% author_link "Homer" possessive %}{% endcapture %}
{% capture the_iliad %}{% book_link "The Iliad" %}{% endcapture %}
