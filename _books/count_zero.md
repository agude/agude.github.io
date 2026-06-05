---
date: 2026-06-05
title: Count Zero
book_authors: William Gibson
series: Sprawl
book_number: 2
is_anthology: false
rating: null
image: /books/covers/count_zero.jpg
wikidata_qid: Q2384854
isbn: 978-0-87795-793-7
date_published: 1986-03
same_as_urls:
  - "https://www.wikidata.org/wiki/Q2384854"
  - "https://en.wikipedia.org/wiki/Count_Zero"
  - "https://openlibrary.org/works/OL27256W"
  - "https://www.isfdb.org/cgi-bin/title.cgi?2195"
  - "https://www.britannica.com/topic/Count-Zero"
  - "https://www.librarything.com/work/2445"
  - "https://www.google.com/search?kgmid=/m/01z439"
---

{% book_link page.title %}, by {% author_link page.book_authors link=false %}, is the second book in {% series_text page.series link=false %}.

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