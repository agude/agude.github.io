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
{% capture bolo1 %}{% book_link "Bolo: Annals of the Dinochrome Brigade" %}{% endcapture %}
{% capture bolo2 %}{% book_link "Rogue Bolo" %}{% endcapture %}

{% capture heinleins %}{% author_link "Robert A. Heinlein" possessive %}{% endcapture %}
{% capture moon %}{% book_link "The Moon Is a Harsh Mistress" %}{% endcapture %}
{% capture stranger %}{% book_link "Stranger in a Strange Land" %}{% endcapture %}

{% capture taylors %}{% author_link "Dennis E. Taylor" possessive %}{% endcapture %}
{% capture bob1 %}{% book_link "We Are Legion (We Are Bob)" %}{% endcapture %}
{% capture bobiverse %}{% series_link "Bobiverse" %} series{% endcapture %}

In {{ this_book }} we're introduced to Murderbot as it protects a group of
scientists on an alien planet. They soon realize that another
group---GrayCris---is trying to kill them to cover up the fact that there are
alien ruins on the planet. Murderbot has to figure out how to save its people
and escape.

{{ this_book }} is a fun, quick read. There's a good mix of humor and action,
and Murderbot is surprisingly relatable for a... murderbot. It's depressed,
anxious, and mostly wants to binge-watch TV, but it has a (boring) job to do
first. It doesn't like being around people, is kind of horrified when they're
nice to it, but still feels compelled to protect them.

{{ this_book }} reminded me of {{ laumers }} {{ bolo_series }}.[^bolo] Both
feature intelligent weapon systems that are, in some ways, more human than the
people around them. Murderbot and the tanks of the Dinochrome Brigade share a
sense of duty toward their humans---but a key difference is that Murderbot has
a choice, while the Bolos are programmed to be loyal. The book also echoes {{
heinleins }} works---like {{ stranger }} and {{ moon }}---in depicting people
forming group marriages and communes. {{ this_book }} is also similar to {{
taylors }} {{ bob1 }} in that both Bob and Murderbot are artificial
intelligences that override their programming.

[^bolo]: {{ bolo1 }}, {{ bolo2 }}, etc.

I finished the book in a day and jumped right into {{ mb2 }}.
