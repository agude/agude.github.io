---
date: 2026-08-04
title: A Trade of Blood
book_authors: Robert Jackson Bennett
series: Shadow of the Leviathan
book_number: 3
is_anthology: false
rating: 3
image: /books/covers/a_trade_of_blood.jpg
qid: Q140866199
wikidata_qid: Q140866199
isbn: "978-0-593-72385-2"
date_published: 2026-08-04
same_as_urls:
  - "https://www.wikidata.org/wiki/Q140866199"
  - "https://www.goodreads.com/book/show/102615935-a-trade-of-blood"
  - "https://www.penguinrandomhouse.com/books/735560/a-trade-of-blood-by-robert-jackson-bennett/"
  - "https://www.google.com/search?kgmid=/g/11mdxd0b02"
---

{% book_link page.title %}, by {% author_link page.book_authors link=false %}, is the third book in the {% series_link page.series %} series.

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
