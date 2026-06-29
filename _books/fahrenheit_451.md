---
date: 2026-06-29
title: Fahrenheit 451
book_authors: Ray Bradbury
series: null
book_number: 1
is_anthology: false
rating: 3
image: /books/covers/fahrenheit_451.jpg
wikidata_qid: Q202009
isbn: 978-0-7432-4722-1
date_published: 1953-10
awards:
  - hugo
same_as_urls:
  - "https://www.wikidata.org/wiki/Q202009"
  - "https://en.wikipedia.org/wiki/Fahrenheit_451"
  - "https://openlibrary.org/works/OL103200W"
  - "https://www.isfdb.org/cgi-bin/title.cgi?1972"
  - "https://www.britannica.com/topic/Fahrenheit-451-novel-by-Bradbury"
  - "https://www.librarything.com/work/4248"
  - "https://www.google.com/search?kgmid=/m/02yqq"
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
