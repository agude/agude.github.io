---
date: 2026-03-16
title: The Short Victorious War
book_authors: David Weber
series: Honor Harrington
book_number: 3
is_anthology: false
rating: null
image: /books/covers/the_short_victorious_war.jpg
wikidata_qid: Q3549538
isbn: 978-0-671-87596-1
date_published: 1994-04
same_as_urls:
  - "https://www.wikidata.org/wiki/Q3549538"
  - "https://en.wikipedia.org/wiki/The_Short_Victorious_War"
  - "https://openlibrary.org/works/OL15401158W"
  - "https://www.isfdb.org/cgi-bin/title.cgi?5860"
  - "https://www.librarything.com/work/34930"
  - "https://www.google.com/search?kgmid=/m/04xllk"
---

{% book_link page.title %}, by {% author_link page.book_authors link=false %},
is the third book in {% series_text page.series link=false %}.

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
