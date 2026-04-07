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

{% capture hh1 %}{% book_link "On Basilisk Station" %}{% endcapture %}
{% capture hh2 %}{% book_link "The Honor of the Queen" %}{% endcapture %}
{% capture hh3 %}{% book_link "The Short Victorious War" %}{% endcapture %}
{% capture hh4 %}{% book_link "Field of Dishonor" %}{% endcapture %}
{% capture hh5 %}{% book_link "Flag in Exile" %}{% endcapture %}

{% capture herbert %}{% author_link "Frank Herbert" %}{% endcapture %}
{% capture herberts %}{% author_link "Frank Herbert" possessive %}{% endcapture %}
{% capture herbert_lastname %}{% author_link "Frank Herbert" link_text="Herbert" %}{% endcapture %}
{% capture herberts_lastname %}{% author_link "Frank Herbert" link_text="Herbert" possessive %}{% endcapture %}
{% capture dune_series %}{% series_link "Dune" %}{% endcapture %}
{% capture dune %}{% book_link "Dune" %}{% endcapture %}

{% capture clancy %}{% author_link "Tom Clancy" %}{% endcapture %}  
{% capture clancys %}{% author_link "Tom Clancy" possessive %}{% endcapture %}  
{% capture clancy_lastname %}{% author_link "Tom Clancy" link_text="Clancy" %}{% endcapture %}  
{% capture clancys_lastname %}{% author_link "Tom Clancy" link_text="Clancy" possessive %}{% endcapture %}  
{% capture without_remorse %}{% book_link "Without Remorse" %}{% endcapture %}

{{ this_book }} begins right where {{ hh3 }} ends, with the court martial
Pavel Young and the fallout from political compromise it forced. In my last
review, I was worried because I knew this ship was going to be mostly political
and personal drama without the massive naval battles that have been a feature
of the series. But it actually worked really well! It was a good break.

_But_ {{ the_authors }} writing is deteriorating in one specific way: he is
**really** starting to add in long descriptions about his worldbuilding, what
his characters are thinking and planing. Sometimes there would be entire
paragraphs of explanation between each line of dialog. The <cite>[How David
Weber orders a pizza][pizza]</cite> parody is too spot on. And I hear it only
gets worse as we go. I'm not sure how much longer I can put up with it.

[pizza]: https://boards.straightdope.com/t/how-david-weber-orders-a-pizza/606473

**But** again the action scenes are satisfying! The marine training mission
that "accidentally" systematically dismantles gangster protecting Paul
Tankersley is right out of {{ clancys }} {{ without_remorse }}. Even though
dueling feels anachronistic, despite the setting being "the British Empire but
in Space", they're tense and an opportunity for Honor to destroy people. And
as I said above, the change from naval to personal scale drama did a lot to
reinvigorate the series.
