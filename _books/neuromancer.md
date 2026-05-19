---
date: 2026-05-18 10:46:00 -0700
title: Neuromancer
book_authors: William Gibson
series: Sprawl
book_number: 1
is_anthology: false
rating: 5
image: /books/covers/neuromancer.jpg
wikidata_qid: Q662029
isbn: 978-0-441-56956-4
date_published: 1984-07-01
awards:
  - hugo
  - nebula
same_as_urls:
  - "https://www.wikidata.org/wiki/Q662029"
  - "https://en.wikipedia.org/wiki/Neuromancer"
  - "https://openlibrary.org/works/OL27258W"
  - "https://www.isfdb.org/cgi-bin/title.cgi?1475"
  - "https://www.britannica.com/topic/Neuromancer"
  - "https://www.librarything.com/work/609"
  - "https://www.google.com/search?kgmid=/m/05g5q"
---

{% book_link page.title %}, by {% author_link page.book_authors link=false %}, is the first book in {% series_text page.series link=false %}.

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
