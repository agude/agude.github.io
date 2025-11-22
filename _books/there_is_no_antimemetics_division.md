---
date: 2025-11-21
title: There Is No Antimemetics Division
book_authors: qntm
series: null
book_number: 1
is_anthology: false
rating: 4
image: /books/covers/there_is_no_antimemetics_division.jpg
---

<cite class="book-title">{{ page.title }}</cite>, by <span
class="author-name">{{ page.book_authors }}</span>, is in progress!

{% capture this_book %}<cite class="book-title">{{ page.title }}</cite>{% endcapture %}
{% capture the_author %}<span class="author-name">{{ page.book_authors }}</span>{% endcapture %}
{% capture the_authors %}<span class="author-name">{{ page.book_authors }}</span>'s{% endcapture %}
{% capture author_last_name_text %}{{ page.book_authors | split: " " | last }}{% endcapture %}
{% capture the_author_link %}{% author_link page.book_authors %}{% endcapture %}
{% capture the_authors_link %}{% author_link page.book_authors possessive %}{% endcapture %}
{% capture the_authors_lastname_link %}{% author_link page.book_authors link_text=author_last_name_text %}{% endcapture %}
{% capture the_authors_lastname_possessive_link %}{% author_link page.book_authors link_text=author_last_name_text possessive %}{% endcapture %}

{% capture original %}{% book_link "There Is No Antimemetics Division (Original Edition)" link_text="original edition" %}{% endcapture %}

{{ this_book }} is a {{the_authors }} rewrite of his {{ original }}. 

I thought the strongest part of the {{ original }} was the first half, written
as disjointed short stories with tight pacing. The weakest part was the second
half, where the author tried to weave them into a narrative. The execution
felt clumsy, reading like a series of scenes on a stage just wide enough to
contain the action, rather than a wider world.

This rewrite fixes all of those problems. The short stories maintain their
pacing, and some are even edited down to be tighter. {{ the_author }} adds in
just a few more hints and signposts, which help make it clearer how they're
all related. The short stories are now an integral part of the larger work
instead of just context or background.

<!-- Basically the old one didn't feel like a whole, it felt like a bunch of
parts -->
