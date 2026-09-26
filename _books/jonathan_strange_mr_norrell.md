---
date: 2026-09-26
title: "Jonathan Strange & Mr Norrell"
book_authors: Susanna Clarke
series: "Strange & Norrell"
book_number: 1
is_anthology: false
rating: null
image: /books/covers/jonathan_strange_mr_norrell.jpg
wikidata_qid: Q1474920
isbn: 978-0-7475-7055-4
date_published: 2004-09-08
awards:
  - hugo
  - locus
  - nebula
same_as_urls:
  - "https://www.wikidata.org/wiki/Q1474920"
  - "https://en.wikipedia.org/wiki/Jonathan_Strange_%26_Mr_Norrell"
  - "https://www.goodreads.com/work/editions/3921305"
  - "https://openlibrary.org/works/OL5703428W"
  - "https://openlibrary.org/works/OL5703422W"
  - "https://www.isfdb.org/cgi-bin/title.cgi?153332"
  - "https://www.librarything.com/work/1060"
  - "https://www.google.com/search?kgmid=/m/040t6s"
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
