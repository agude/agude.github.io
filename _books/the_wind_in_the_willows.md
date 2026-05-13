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

{% book_link page.title %}, by {% author_link page.book_authors link=false %},
is a standalone novel.

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
{% capture jacquess_lastname %}{% author_link "Brian Jacques" link_text="Jacques" possessive %}{% endcapture %}
{% capture redwall_series %}{% series_link "Redwall" %}{% endcapture %}
{% capture redwall %}{% book_link "Redwall" %}{% endcapture %}
{% capture mossflower %}{% book_link "Mossflower" %}{% endcapture %}

{% capture homer %}{% author_link "Homer" %}{% endcapture %}
{% capture homers %}{% author_link "Homer" possessive %}{% endcapture %}
{% capture the_odyssey %}{% book_link "The Odyssey" %}{% endcapture %}

{% capture tennyson %}{% author_link "Alfred, Lord Tennyson" %}{% endcapture %}
{% capture tennysons %}{% author_link "Alfred, Lord Tennyson" possessive %}{% endcapture %}
{% capture tennyson_lastname %}{% author_link "Alfred, Lord Tennyson" link_text="Tennyson" %}{% endcapture %}
{% capture tennysons_lastname %}{% author_link "Alfred, Lord Tennyson" link_text="Tennyson" possessive %}{% endcapture %}

{% capture adams %}{% author_link "Richard Adams" %}{% endcapture %}
{% capture adamss %}{% author_link "Richard Adams" possessive %}{% endcapture %}
{% capture adams_lastname %}{% author_link "Richard Adams" link_text="Adams" %}{% endcapture %}
{% capture adamss_lastname %}{% author_link "Richard Adams" link_text="Adams" possessive %}{% endcapture %}
{% capture watership_down %}{% book_link "Watership Down" %}{% endcapture %}

{% capture lewis %}{% author_link "C.S. Lewis" %}{% endcapture %}
{% capture lewiss %}{% author_link "C.S. Lewis" possessive %}{% endcapture %}
{% capture lewis_lastname %}{% author_link "C.S. Lewis" link_text="Lewis" %}{% endcapture %}
{% capture lewiss_lastname %}{% author_link "C.S. Lewis" link_text="Lewis" possessive %}{% endcapture %}
{% capture narnia %}{% series_link "The Chronicles of Narnia" %}{% endcapture %}

{% capture milne %}{% author_link "A.A. Milne" %}{% endcapture %}
{% capture milnes %}{% author_link "A.A. Milne" possessive %}{% endcapture %}
{% capture milne_lastname %}{% author_link "A.A. Milne" link_text="Milne" %}{% endcapture %}
{% capture milnes_lastname %}{% author_link "A.A. Milne" link_text="Milne" possessive %}{% endcapture %}
{% capture winnie_the_pooh %}{% book_link "Winnie-the-Pooh" %}{% endcapture %}

My father read {{ this_book }} to me when I was young. My first memory of it
is him reading the final chapter, _The Return of Ulysses_, in which Toad,
Badger, Mole, and Ratty storm Toad Hall and take it back from the weasels,
ferrets, and stoats. I remember him singing _When The Toad Came Home_. I don't
know if we actually read the whole book, although on this re-read I found some
of the chapters to be familiar, and others to be completely new, so I suspect
we only read some of them.

<!-- Section about how its like childhood: so much to do and so little needs
to be done. How it captures my father's philosophy. -->

{{ this_book }} was obviously hugely influential to {{ jacques }} when writing
the {{ redwall_series }}. {{ jacquess_lastname }} animals share a lot of the
same traits as {{ the_authors_lastname_possessive }}: badgers are fearsome and
wise; moles are honest and obedient; weasels, ferrets, and stoats are bad.
They're both English pastoral stories. They both feature songs woven through
them. {{ jacquess_lastname }} {{ redwall }} even has the same uncomfortable
juxtaposition of anthropomorphic animals in a human world, which he thankfully
drops by the second book, {{ mossflower }}.

{{ this_book }} reminded me of others I've read. Of course, Toad's vengeful
return is based on Odysseus's from {{ homers }} {{ the_odyssey }}, it's in the
chapter title! The focus on anthropomorphized animals in England is
reminiscent of {{ adamss_lastname }} {{ watership_down }} (although {{
watership_down }} is much darker). The way Mole can feel his home calling to
him "like an electric shock" is the similar to how Shivers allows Harrier Du
Bois to commune with Revachol in {{ disco_elysium }}.
