---
date: 2026-07-02
title: Mona Lisa Overdrive
book_authors: William Gibson
series: Sprawl
book_number: 3
is_anthology: false
rating: null
image: /books/covers/mona_lisa_overdrive.jpg
wikidata_qid: Q663215
isbn: 978-0-553-05250-3
date_published: 1988-10
same_as_urls:
  - "https://www.wikidata.org/wiki/Q663215"
  - "https://en.wikipedia.org/wiki/Mona_Lisa_Overdrive"
  - "https://openlibrary.org/works/OL27253W"
  - "https://www.isfdb.org/cgi-bin/title.cgi?1505"
  - "https://www.britannica.com/topic/Mona-Lisa-Overdrive"
  - "https://www.librarything.com/work/608"
  - "https://www.google.com/search?kgmid=/m/01z43p"
---

{% book_link page.title %}, by {% author_link page.book_authors link=false %}, is the third book in {% series_text page.series link=false %}.

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