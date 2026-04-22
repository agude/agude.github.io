---
date: 2026-04-22
title: Ubik
book_authors: Philip K. Dick
series: null
book_number: 1
is_anthology: false
rating: null
image: /books/covers/ubik.jpg
wikidata_qid: Q617357
isbn: 978-0440092001
date_published: 1969-05-01
same_as_urls:
  - "https://www.wikidata.org/wiki/Q617357"
  - "https://en.wikipedia.org/wiki/Ubik"
  - "https://openlibrary.org/works/OL2172454W"
  - "https://www.isfdb.org/cgi-bin/title.cgi?948"
  - "https://www.librarything.com/work/16572"
  - "https://www.google.com/search?kgmid=/m/05ssr"
---

{% book_link page.title %}, by {% author_link page.book_authors link=false %}, is a 1969 science fiction novel.

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
