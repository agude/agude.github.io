---
date: 2026-09-13
title: The Algebraist
book_authors: Iain M. Banks
series: null
book_number: 1
is_anthology: false
rating: null
image: /books/covers/the_algebraist.jpg
wikidata_qid: Q901913
isbn: 978-1-84149-155-4
date_published: 2004-10
same_as_urls:
  - "https://www.wikidata.org/wiki/Q901913"
  - "https://en.wikipedia.org/wiki/The_Algebraist"
  - "https://openlibrary.org/works/OL8368450W"
  - "https://www.isfdb.org/cgi-bin/title.cgi?171135"
  - "https://www.librarything.com/work/12930"
  - "https://www.google.com/search?kgmid=/m/02z6vx"
---

{% book_link page.title %}, by {% author_link page.book_authors link=false %}, is a standalone novel.

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
