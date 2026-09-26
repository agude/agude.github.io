---
date: 2026-09-19 13:49:14 -0700
title: Platform Decay
book_authors: Martha Wells
series: The Murderbot Diaries
book_number: 8
is_anthology: false
rating: 3
image: /books/covers/platform_decay.jpg
wikidata_qid: Q136749524
isbn: 978-1-7050-4103-1
date_published: 2026-05-05
same_as_urls:
  - "https://www.wikidata.org/wiki/Q136749524"
  - "https://openlibrary.org/works/OL44660267W"
  - "https://www.isfdb.org/cgi-bin/title.cgi?3597228"
  - "https://www.librarything.com/work/29024865"
---

{% book_link page.title %}, by {% author_link page.book_authors link=false %}, is the eighth book in {% series_text page.series link=false %}.

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

{% capture banks %}{% author_link "Iain M. Banks" %}{% endcapture %}
{% capture bankss %}{% author_link "Iain M. Banks" possessive %}{% endcapture %}
{% capture banks_lastname %}{% author_link "Iain M. Banks" link_text="Banks" %}{% endcapture %}
{% capture bankss_lastname %}{% author_link "Iain M. Banks" link_text="Banks" possessive %}{% endcapture %}
{% capture use_of_weapons %}{% book_link "Use of Weapons" %}{% endcapture %}

{% capture taylor %}{% author_link "Dennis E. Taylor" %}{% endcapture %}
{% capture taylors %}{% author_link "Dennis E. Taylor" possessive %}{% endcapture %}
{% capture taylor_lastname %}{% author_link "Dennis E. Taylor" link_text="Taylor" %}{% endcapture %}
{% capture taylors_lastname %}{% author_link "Dennis E. Taylor" link_text="Taylor" possessive %}{% endcapture %}
{% capture bobiverse %}{% series_link "Bobiverse" %}{% endcapture %}
{% capture heaven_s_river %}{% book_link "Heaven's River" %}{% endcapture %}

{% capture simmons %}{% author_link "Dan Simmons" %}{% endcapture %}
{% capture simmonss %}{% author_link "Dan Simmons" possessive %}{% endcapture %}
{% capture simmons_lastname %}{% author_link "Dan Simmons" link_text="Simmons" %}{% endcapture %}
{% capture simmonss_lastname %}{% author_link "Dan Simmons" link_text="Simmons" possessive %}{% endcapture %}
{% capture the_fall_of_hyperion %}{% book_link "The Fall of Hyperion" %}{% endcapture %}
