---
date: 2026-03-07
title: The Honor of the Queen
book_authors: David Weber
series: Honor Harrington
book_number: 2
is_anthology: false
rating: null
image: /books/covers/the_honor_of_the_queen.jpg
wikidata_qid: Q3400447
isbn: 978-0-671-72172-5
date_published: 1993-06
same_as_urls:
  - "https://www.wikidata.org/wiki/Q3400447"
  - "https://en.wikipedia.org/wiki/The_Honor_of_the_Queen"
  - "https://openlibrary.org/works/OL15401157W"
  - "https://www.isfdb.org/cgi-bin/title.cgi?5859"
  - "https://www.librarything.com/work/34924"
  - "https://www.google.com/search?kgmid=/m/04xm_3"
---

{% book_link page.title %}, by {% author_link page.book_authors link=false %},
is the second book in {% series_text page.series link=false %}.

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
