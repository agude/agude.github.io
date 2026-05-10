---
date: 2026-05-10
title: Snow Crash
book_authors: Neal Stephenson
series: null
book_number: 1
is_anthology: false
rating: null
image: /books/covers/snow_crash.jpg
wikidata_qid: Q768389
isbn: 978-0-553-08853-3
date_published: 1992-06
same_as_urls:
  - "https://www.wikidata.org/wiki/Q768389"
  - "https://en.wikipedia.org/wiki/Snow_Crash"
  - "https://openlibrary.org/works/OL38485W"
  - "https://www.isfdb.org/cgi-bin/title.cgi?1182"
  - "https://www.librarything.com/work/1000167"
  - "https://www.google.com/search?kgmid=/m/0j__z"
---

{% book_link page.title %}, by {% author_link page.book_authors link=false %},
is a 1992 science fiction novel.

{% capture this_book %}{% book_link page.title %}{% endcapture %}
{% capture the_author %}{% author_link page.book_authors link=false %}{% endcapture %}
{% capture author_last_name_text %}{{ page.book_authors | split: " " | last }}{% endcapture %}
{% capture the_authors_lastname %}{% author_link page.book_authors link=false link_text=author_last_name_text %}{% endcapture %}
{% capture the_authors_lastname_possessive %}{% author_link page.book_authors link=false link_text=author_last_name_text possessive %}{% endcapture %}
