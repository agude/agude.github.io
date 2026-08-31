---
date: 2026-08-30
title: System Collapse
book_authors: Martha Wells
series: The Murderbot Diaries
book_number: 7
is_anthology: false
rating: null
image: /books/covers/system_collapse.jpg
wikidata_qid: Q123521600
isbn: 978-1-7050-4102-4
date_published: 2023-11-13
awards:
  - locus
same_as_urls:
  - "https://www.wikidata.org/wiki/Q123521600"
  - "https://openlibrary.org/works/OL33402895W"
  - "https://www.isfdb.org/cgi-bin/title.cgi?3229607"
  - "https://www.librarything.com/work/26774411"
---

{% book_link page.title %}, by {% author_link page.book_authors link=false %}, is the seventh book in {% series_text page.series link=false %}.

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
