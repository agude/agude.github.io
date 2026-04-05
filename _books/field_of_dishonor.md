---
date: 2026-04-05 12:23:59 -0700
title: Field of Dishonor
book_authors: David Weber
series: Honor Harrington
book_number: 4
is_anthology: false
rating: 4
image: /books/covers/field_of_dishonor.jpg
wikidata_qid: Q2870331
isbn: 978-0-671-87624-0
date_published: 1994-10
same_as_urls:
  - "https://www.wikidata.org/wiki/Q2870331"
  - "https://en.wikipedia.org/wiki/Field_of_Dishonor"
  - "https://openlibrary.org/works/OL8259656W"
  - "https://www.isfdb.org/cgi-bin/title.cgi?5861"
  - "https://www.librarything.com/work/34898"
  - "https://www.google.com/search?kgmid=/m/04xs38"
---

{% book_link page.title %}, by {% author_link page.book_authors link=false %},
is the fourth book in {% series_text page.series link=false %}.

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
