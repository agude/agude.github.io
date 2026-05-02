---
date: 2026-04-22
title: Ubik
book_authors: Philip K. Dick
series: null
book_number: 1
is_anthology: false
rating: null
image: /books/covers/ubik.jpg
wikidata_qid: Q617357
isbn: 978-0440092001
date_published: 1969-05-01
same_as_urls:
  - "https://www.wikidata.org/wiki/Q617357"
  - "https://en.wikipedia.org/wiki/Ubik"
  - "https://openlibrary.org/works/OL2172454W"
  - "https://www.isfdb.org/cgi-bin/title.cgi?948"
  - "https://www.librarything.com/work/16572"
  - "https://www.google.com/search?kgmid=/m/05ssr"
---

{% book_link page.title %}, by {% author_link page.book_authors link=false %}, is a 1969 science fiction novel.

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

{% capture maze %}{% book_link "A Maze of Death" %}{% endcapture %}

Twenty-five years ago, I read my first {{ the_author }} book: {{ maze }}. I
don't know where I got it, or why I picked it up. If I had to guess, I would
say it was one of the books left in my family's run-down Adirondack cabin,
probably by someone who didn't mind parting with it. I got halfway through and
put it back for some other bored traveler. I **hated** it. I didn't find any
redeeming features in {{ the_authors_lastname_possessive }} sparse prose or
ensemble cast of disposable characters. I did not find the big ideas about
reality to be compelling with nothing else around them.

A few weeks ago I decide to read {{ this_book }}. I wanted to give {{
the_author }} another shot because he is such a titan of Hollywood sci-fi, and
I thought with Twenty-five more years of life and reading I would be ready to
give him a fair shake. Instead, I found myself hating the exact same things I
hated in {{ maze }}.

{{ this_book }} has a disposable cast of characters who work at a Prudence
organization: a company that employees anti-psi to confound telepaths and
precogs. After a mission goes wrong, reality starts deteriorating as items
transform into past versions of themselves and the team ages into dust. And
the only thing that can stabilize reality it, perhaps, the substance known as
Ubik.
