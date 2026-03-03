---
date: 2026-03-01 20:34:56 -0800
title: Red Rising
book_authors: Pierce Brown
series: Red Rising Trilogy
book_number: 1
is_anthology: false
rating: 3
image: /books/covers/red_rising.jpg
wikidata_qid: Q18393778
isbn: 978-0-345-53978-6
date_published: 2014-01-28
same_as_urls:
  - "https://www.wikidata.org/wiki/Q18393778"
  - "https://en.wikipedia.org/wiki/Red_Rising"
  - "https://openlibrary.org/works/OL17076473W"
  - "https://www.isfdb.org/cgi-bin/title.cgi?1664916"
  - "https://www.librarything.com/work/13865214"
  - "https://www.google.com/search?kgmid=/m/0_kqnv7"
---

{% book_link page.title %}, by {% author_link page.book_authors link=false %},
is the first book in {% series_text page.series link=false %}.

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
