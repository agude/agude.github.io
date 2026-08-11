---
date: 2026-08-04 17:58:19 -0700
title: The Event
book_authors: Henry Bean
series: null
book_number: 1
is_anthology: false
rating: 4
image: /books/covers/the_event.jpg
wikidata_qid: null
isbn: null
date_published: 2025-09
same_as_urls:
  - "https://jewishcurrents.org/the-event"
---

{% book_link page.title %}, by {% author_link page.book_authors link=false %}, is a short story.

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

{% capture fall %}{% author_link "Isabel Fall" %}{% endcapture %}
{% capture falls %}{% author_link "Isabel Fall" possessive %}{% endcapture %}
{% capture fall_lastname %}{% author_link "Isabel Fall" link_text="Fall" %}{% endcapture %}
{% capture falls_lastname %}{% author_link "Isabel Fall" link_text="Fall" possessive %}{% endcapture %}
{% capture i_sexually_identify_as_an_attack_helicopter %}{% book_link "I Sexually Identify as an Attack Helicopter" %}{% endcapture %}

{% capture arkady_strugatsky %}{% author_link "Arkady Strugatsky" %}{% endcapture %}
{% capture arkady_strugatskys %}{% author_link "Arkady Strugatsky" possessive %}{% endcapture %}
{% capture arkady_strugatsky_lastname %}{% author_link "Arkady Strugatsky" link_text="Strugatsky" %}{% endcapture %}
{% capture arkady_strugatskys_lastname %}{% author_link "Arkady Strugatsky" link_text="Strugatsky" possessive %}{% endcapture %}
{% capture boris_strugatsky %}{% author_link "Boris Strugatsky" %}{% endcapture %}
{% capture boris_strugatskys %}{% author_link "Boris Strugatsky" possessive %}{% endcapture %}
{% capture boris_strugatsky_lastname %}{% author_link "Boris Strugatsky" link_text="Strugatsky" %}{% endcapture %}
{% capture boris_strugatskys_lastname %}{% author_link "Boris Strugatsky" link_text="Strugatsky" possessive %}{% endcapture %}
{% capture arkady_and_boris %}{% author_link "Arkady Strugatsky" link_text="Arkady" %} and {% author_link "Boris Strugatsky" link_text="Boris" %}{% endcapture %}
{% capture arkady_and_boriss %}{% author_link "Arkady Strugatsky" link_text="Arkady" %} and {% author_link "Boris Strugatsky" link_text="Boris" possessive %}{% endcapture %}
{% capture roadside_picnic %}{% book_link "Roadside Picnic" %}{% endcapture %}
