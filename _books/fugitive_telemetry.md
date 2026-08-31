---
date: 2026-08-30 13:26:24 -0700
title: Fugitive Telemetry
book_authors: Martha Wells
series: The Murderbot Diaries
book_number: 6
is_anthology: false
rating: 4
image: /books/covers/fugitive_telemetry.jpg
wikidata_qid: Q107123470
isbn: 978-1-250-76537-6
date_published: 2021-04-27
awards:
  - locus
same_as_urls:
  - "https://www.wikidata.org/wiki/Q107123470"
  - "https://openlibrary.org/works/OL20805971W"
  - "https://www.isfdb.org/cgi-bin/title.cgi?2844053"
  - "https://www.librarything.com/work/24641084"
---

{% book_link page.title %}, by {% author_link page.book_authors link=false %}, is the sixth book in {% series_text page.series link=false %}.

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
