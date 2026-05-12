---
date: 2026-05-07 21:46:47 -0700
title: The Wind in the Willows
book_authors: Kenneth Grahame
series: null
book_number: 1
is_anthology: false
rating: 4
image: /books/covers/the_wind_in_the_willows.jpg
wikidata_qid: Q936276
isbn: 978-0-14-303909-9
date_published: 1908-10-08
same_as_urls:
  - "https://www.wikidata.org/wiki/Q936276"
  - "https://en.wikipedia.org/wiki/The_Wind_in_the_Willows"
  - "https://openlibrary.org/works/OL28570037W/The_Wind_in_the_Willows"
  - "https://www.isfdb.org/cgi-bin/title.cgi?835"
  - "https://www.britannica.com/topic/The-Wind-in-the-Willows"
  - "https://www.librarything.com/work/1534"
  - "https://www.google.com/search?kgmid=/m/0c8sb"
  - "https://standardebooks.org/ebooks/kenneth-grahame/the-wind-in-the-willows"
---

{% book_link page.title %}, by {% author_link page.book_authors link=false %}, is a standalone novel.

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

{% capture disco_elysium %}{% book_link "Disco Elysium" %}{% endcapture %}

{% capture jacques %}{% author_link "Brian Jacques" %}{% endcapture %}
{% capture jacquess %}{% author_link "Brian Jacques" possessive %}{% endcapture %}
{% capture jacques_lastname %}{% author_link "Brian Jacques" link_text="Jacques" %}{% endcapture %}
{% capture jacquess_lastname %}{% author_link "Brian Jacques" link_text="Jacques" possessive %}{% endcapture
%}
{% capture redwall_series %}{% series_link "Redwall" %}{% endcapture %}
{% capture redwall %}{% book_link "Redwall" %}{% endcapture %}

{% capture homer %}{% author_link "Homer" %}{% endcapture %}
{% capture homers %}{% author_link "Homer" possessive %}{% endcapture %}
{% capture the_odyssey %}{% book_link "The Odyssey" %}{% endcapture %}

My father read {{ this_book }} to me when I was young. My first memory of it
is him reading the final chapter, _The Return of Ulysses_, in which Toad,
Badger, Mole, and Ratty storm Toad Hall and take it back from the weasels,
ferrets, and stoats. I remember him singing _When The Toad Came Home_. I don't
know if we actually read the whole book, although on this re-read I found some
of the chapters to be familiar, and others to be completely new, so I suspect
we only read some of them.

<!-- This book influence Jacques. He has the same "Wait they're in a human
world?" problem. Horse animals doing work. (What!?) And weasels, stoats, and
ferrets as the bad guys. Badgers as powerful. -->
