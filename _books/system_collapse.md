---
date: 2026-09-12 09:20:22 -0700
title: System Collapse
book_authors: Martha Wells
series: The Murderbot Diaries
book_number: 7
is_anthology: false
rating: 3
image: /books/covers/system_collapse.jpg
wikidata_qid: Q123521600
isbn: 978-1-7050-4102-4
date_published: 2023-11-13
awards:
  - locus
same_as_urls:
  - "https://www.wikidata.org/wiki/Q123521600"
  - "https://openlibrary.org/works/OL33402895W"
  - "https://www.isfdb.org/cgi-bin/title.cgi?3229607"
  - "https://www.librarything.com/work/26774411"
---

{% book_link page.title %}, by {% author_link page.book_authors link=false %}, is the seventh book in {% series_text page.series link=false %}.

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

{% capture mb1 %}{% book_link "All Systems Red" %}{% endcapture %}
{% capture mb2 %}{% book_link "Artificial Condition" %}{% endcapture %}
{% capture mb3 %}{% book_link "Rogue Protocol" %}{% endcapture %}
{% capture mb4 %}{% book_link "Exit Strategy" %}{% endcapture %}
{% capture mb5 %}{% book_link "Network Effect" %}{% endcapture %}
{% capture mb6 %}{% book_link "Fugitive Telemetry" %}{% endcapture %}
{% capture mb7 %}{% book_link "System Collapse" %}{% endcapture %}

{% capture vinge %}{% author_link "Vernor Vinge" %}{% endcapture %}
{% capture vinges %}{% author_link "Vernor Vinge" possessive %}{% endcapture %}
{% capture vinge_lastname %}{% author_link "Vernor Vinge" link_text="Vinge" %}{% endcapture %}
{% capture vinges_lastname %}{% author_link "Vernor Vinge" link_text="Vinge" possessive %}{% endcapture %}
{% capture a_fire_upon_the_deep %}{% book_link "A Fire Upon The Deep" %}{% endcapture %}

{% capture arkady %}{% author_link "Arkady Strugatsky" %}{% endcapture %}
{% capture arkadys %}{% author_link "Arkady Strugatsky" possessive %}{% endcapture %}
{% capture arkady_lastname %}{% author_link "Arkady Strugatsky" link_text="Strugatsky" %}{% endcapture %}
{% capture arkadys_lastname %}{% author_link "Arkady Strugatsky" link_text="Strugatsky" possessive %}{% endcapture %}
{% capture boris %}{% author_link "Boris Strugatsky" %}{% endcapture %}
{% capture boriss %}{% author_link "Boris Strugatsky" possessive %}{% endcapture %}
{% capture boris_lastname %}{% author_link "Boris Strugatsky" link_text="Strugatsky" %}{% endcapture %}
{% capture boriss_lastname %}{% author_link "Boris Strugatsky" link_text="Strugatsky" possessive %}{% endcapture %}
{% capture arkady_and_boris %}{% author_link "Arkady Strugatsky" %} and {% author_link "Boris Strugatsky" %}{% endcapture %}
{% capture arkady_and_boriss %}{% author_link "Arkady Strugatsky" %} and {% author_link "Boris Strugatsky" possessive %}{% endcapture %}
{% capture roadside_picnic %}{% book_link "Roadside Picnic" %}{% endcapture %}

{% capture banks %}{% author_link "Iain M. Banks" %}{% endcapture %}
{% capture bankss %}{% author_link "Iain M. Banks" possessive %}{% endcapture %}
{% capture banks_lastname %}{% author_link "Iain M. Banks" link_text="Banks" %}{% endcapture %}
{% capture bankss_lastname %}{% author_link "Iain M. Banks" link_text="Banks" possessive %}{% endcapture %}
{% capture matter %}{% book_link "Matter" %}{% endcapture %}

{% capture alex %}{% author_link "A. N. Alex" %}{% endcapture %}
{% capture alexs %}{% author_link "A. N. Alex" possessive %}{% endcapture %}
{% capture alex_lastname %}{% author_link "A. N. Alex" link_text="Alex" %}{% endcapture %}
{% capture alexs_lastname %}{% author_link "A. N. Alex" link_text="Alex" possessive %}{% endcapture %}
{% capture a_mote_in_shadow %}{% book_link "A Mote in Shadow" %}{% endcapture %}
