---
date: 2026-04-05
title: Accelerando
book_authors: Charles Stross
series: null
book_number: 1
is_anthology: false
rating: null
image: /books/covers/accelerando.jpg
wikidata_qid: Q2300209
isbn: 978-0-441-01284-8
date_published: 2005-07-05
same_as_urls:
  - "https://www.wikidata.org/wiki/Q2300209"
  - "https://en.wikipedia.org/wiki/Accelerando"
  - "https://openlibrary.org/works/OL2465670W"
  - "https://www.isfdb.org/cgi-bin/title.cgi?158237"
  - "https://www.librarything.com/work/17613"
  - "https://www.google.com/search?kgmid=/m/06xzmz"
---

{% book_link page.title %}, by {% author_link page.book_authors link=false %},
is in progress.

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
