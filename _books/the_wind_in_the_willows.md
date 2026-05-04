---
date: 2026-05-03
title: The Wind in the Willows
book_authors: Kenneth Grahame
series: null
book_number: 1
is_anthology: false
rating: null
image: /books/covers/the_wind_in_the_willows.jpg
wikidata_qid: Q936276
isbn: 978-0-14-303909-9
date_published: 1908-10-08
same_as_urls:
  - "https://www.wikidata.org/wiki/Q936276"
  - "https://en.wikipedia.org/wiki/The_Wind_in_the_Willows"
  - "https://openlibrary.org/works/OL28570037W/The_Wind_in_the_Willows"
  - "https://www.isfdb.org/cgi-bin/title.cgi?835"
  - "https://www.britannica.com/topic/The-Wind-in-the-Willows"
  - "https://www.librarything.com/work/1534"
  - "https://www.google.com/search?kgmid=/m/0c8sb"
  - "https://standardebooks.org/ebooks/kenneth-grahame/the-wind-in-the-willows"
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
