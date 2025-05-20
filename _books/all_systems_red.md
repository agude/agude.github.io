---
date: 2025-05-17
title: All Systems Red
book_author: Martha Wells
series: The Murderbot Diaries
book_number: 1
rating: 4
image: /books/covers/all_systems_red.jpg
awards:
  - hugo
  - locus
  - nebula
---

<cite class="book-title">{{ page.title }}</cite>, by <span
class="author-name">{{ page.book_author }}</span>, is the first book in the
<span class="book-series">{{ page.series }}</span>. It introduces us to
Murderbot as it saves a team of scientists.

{% capture this_book %}<cite class="book-title">{{ page.title }}</cite>{% endcapture %}
{% capture the_author %}<span class="author-name">{{ page.book_author }}</span>{% endcapture %}
{% capture the_authors_lastname %}<span class="author-name">{{ page.book_author | split: " " | last }}</span>{% endcapture %}
{% capture the_authors %}{% author_link page.book_author possessive %}{% endcapture %}
{% capture the_author_link %}{% author_link page.book_author %}{% endcapture %}
{% capture this_series %}{% series_text page.series %}{% endcapture %}

{% capture mb1 %}{% book_link "All Systems Red" %}{% endcapture %}
{% capture mb2 %}{% book_link "Artificial Condition" %}{% endcapture %}

{% capture laumers %}{% author_link "Keith Laumer" possessive %}{% endcapture %}
{% capture bolo_series %}{% series_link "Bolo" %} series{% endcapture %}

{% capture heinleins %}{% author_link "Robert A. Heinlein" possessive %}{% endcapture %}
{% capture moon %}{% book_link "The Moon Is a Harsh Mistress" %}{% endcapture %}
{% capture stranger %}{% book_link "Stranger in a Strange Land" %}{% endcapture %}

In {{ this_book }} we're introduced to Murderbot as it protects a group of
scientists on an alien planet. They soon realize that another
group---GrayCris---is trying to kill them to cover up the fact that there are
alien ruins on the planet. Murderbot has to figure out how to save its people
and escape the planet.

{{ this_book }} is a fun, quick read. There is a good mix of humor and action,
and Murderbot is very relatable despite being a... murderbot. It is depressed,
anxious, and just wants to binge-watch TV but has a (boring) job it has to do
first. It doesn't like being around people, is sort of horrifed when they're
nice to it, but it also feels a need to protect them.

{{ this_book }} reminded me of {{ laumers }} {{ bolo_series }}. Both feature
intelligent weapon systems that are in some ways more human than their human
companions. Both Murderbot and the tanks of the Dinochrome Brigade feel a
sense of duty to their humans, but a key diference is that Murderbot has a
choice whereas Bolos' programing determines their loyalties. The book is also
similar to {{ heinleins }} works---like {{ stranger }} and {{ moon }}---in
depecting people mostly living in group marriages.

I finished the book in a day and jumped right into {{ mb2 }}.
