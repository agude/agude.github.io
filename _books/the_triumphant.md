---
date: 2025-09-23
title: The Triumphant
book_authors:
  - Linda Evans
  - Robert R. Hollingsworth
  - David Weber
series: Bolo
book_number: 12
is_anthology: true
rating: null
image: /books/covers/bolos_book_3_the_triumphant_1st_edition.jpg
---

<cite class="book-title">{{ page.title }}</cite> is the twelfth book in the
<span class="book-series">{{ page.series }}</span> series. It's an anthology
of Bolo stories written by three different authors.

{% capture this_book %}<cite class="book-title">{{ page.title }}</cite>{% endcapture %}
{% capture this_series %}{% series_text page.series %}{% endcapture %}

{% capture author_evans %}{% author_link "Linda Evans" %}{% endcapture %}
{% capture author_hollingsworth %}{% author_link "Robert R. Hollingsworth" %}{% endcapture %}
{% capture author_weber %}{% author_link "David Weber" %}{% endcapture %}

{% comment %}Bolos{% endcomment %}
{% capture bolo1 %}{% book_link "Bolo: Annals of the Dinochrome Brigade" %}{% endcapture %}
{% capture bolo2 %}{% book_link "Rogue Bolo" %}{% endcapture %}
{% capture bolo3 %}{% book_link "The Stars Must Wait" %}{% endcapture %}
{% capture bolo4 %}{% book_link "Bolo Brigade" %}{% endcapture %}
{% capture bolo5 %}{% book_link "Bolo Rising" %}{% endcapture %}
{% capture bolo6 %}{% book_link "Bolo Strike" %}{% endcapture %}
{% capture bolo7 %}{% book_link "The Road to Damascus" %}{% endcapture %}
{% capture bolo8 %}{% book_link "Bolo!" %}{% endcapture %}
{% capture bolo9 %}{% book_link "Old Soldiers" %}{% endcapture %}
{% capture bolo10 %}{% book_link "Honor of the Regiment" %}{% endcapture %}
{% capture bolo11 %}{% book_link "The Unconquerable" %}{% endcapture %}
{% capture bolo12 %}{% book_link "The Triumphant" %}{% endcapture %}
{% capture bolo13 %}{% book_link "Last Stand" %}{% endcapture %}
{% capture bolo14 %}{% book_link "Old Guard" %}{% endcapture %}
{% capture bolo15 %}{% book_link "Cold Steel" %}{% endcapture %}


### {% short_story_title "The Farmer's Wife" %}
<div class="written-by">by {{ author_evans }}</div>
{% rating_stars 3 %}

### {% short_story_title "Little Red Hen" %}
<div class="written-by">by {{ author_evans }} and {{ author_hollingsworth }}</div>
{% rating_stars 5 %}

### {% short_story_title "Little Dog Gone" %}
<div class="written-by">by {{ author_evans }}</div>
{% rating_stars null %}

### {% short_story_title "Miles to Go" %}
<div class="written-by">by {{ author_weber }}</div>
{% rating_stars null %}
