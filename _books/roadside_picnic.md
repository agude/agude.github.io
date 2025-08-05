---
date: 2025-08-04
title: Roadside Picnic
book_authors:
  - Arkady Strugatsky
  - Boris Strugatsky
series: null
book_number: 1
rating: 5
image: /books/covers/roadside_picnic.jpg
---

<cite class="book-title">{{ page.title }}</cite>, by brothers <span
class="author-name">{{ page.book_authors[0] | split: " " | first }}</span> and
<span class="author-name">{{ page.book_authors[1] }}</span>, is a Soviet
sci-fi novel. It's essentially four short stories, each presented as a
chapter, about the life of Redrick "Red" Schuhart, a "stalker" who illegally
enters an alien-contaminated zone to retrieve items for the black market.

{% capture this_book %}<cite class="book-title">{{ page.title }}</cite>{% endcapture %}
{% capture the_author %}<span class="author-name">{{ page.book_authors }}</span>{% endcapture %}
{% capture the_authors %}<span class="author-name">{{ page.book_authors }}</span>'s{% endcapture %}
{% capture author_last_name_text %}{{ page.book_authors | split: " " | last }}{% endcapture %}
{% capture the_authors_lastname %}<span class="author-name">{{ page.book_authors | split: " " | last }}</span>{% endcapture %}
{% capture the_authors_lastname_possessive %}<span class="author-name">{{ page.book_authors | split: " " | last }}</span>'s{% endcapture %}
{% capture the_author_link %}{% author_link page.book_authors %}{% endcapture %}
{% capture the_authors_link %}{% author_link page.book_authors possessive %}{% endcapture %}
{% capture the_authors_lastname_link %}{% author_link page.book_authors link_text=author_last_name_text %}{% endcapture %}
{% capture the_authors_lastname_possessive_link %}{% author_link page.book_authors link_text=author_last_name_text possessive %}{% endcapture %}
{% capture this_series %}{% series_text page.series %}{% endcapture %}
