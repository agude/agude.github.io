---
date: 2025-08-11
title: The Unconquerable
book_authors:
  - S. M. Stirling
  - S. N. Lewitt
  - Shirley Meier
  - Christopher Stasheff
  - Karen Wehrstein
  - Todd Johnson
  - William R. Forstchen
series: Bolo
book_number: 11
is_anthology: true
rating: 4
image: /books/covers/bolos_book_2_the_unconquerable_1st_edition.jpg
---

<cite class="book-title">{{ page.title }}</cite> is the eleventh book in the
<span class="book-series">{{ page.series }}</span> series. It's an anthology
of Bolo stories written by seven different authors.

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

{% capture author_stirling %}{% author_link "S. M. Stirling" %}{% endcapture %}
{% capture author_lewitt %}{% author_link "S. N. Lewitt" %}{% endcapture %}
{% capture author_meier %}{% author_link "Shirley Meier" %}{% endcapture %}
{% capture author_stasheff %}{% author_link "Christopher Stasheff" %}{% endcapture %}
{% capture author_wehrstein %}{% author_link "Karen Wehrstein" %}{% endcapture %}
{% capture author_johnson %}{% author_link "Todd Johnson" %}{% endcapture %}
{% capture author_forstchen %}{% author_link "William R. Forstchen" %}{% endcapture %}

{% capture ancestral_voices %}{% short_story_link "Ancestral Voices" %}{% endcapture %}
{% capture sir_kendricks_lady %}{% short_story_link "Sir Kendrick's Lady" %}{% endcapture %}
{% capture youre_it %}{% short_story_link "You're It" %}{% endcapture %}
{% capture shared_experience %}{% short_story_link "Shared Experience" %}{% endcapture %}
{% capture the_murphosensor_bomb %}{% short_story_link "The Murphosensor Bomb" %}{% endcapture %}
{% capture legacy %}{% short_story_link "Legacy" %}{% endcapture %}
{% capture endings %}{% short_story_link "Endings" %}{% endcapture %}

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

### {% short_story_title "Ancestral Voices" %}
<div class="written-by">by {{ author_stirling }}</div>
{% rating_stars 4 %}

### {% short_story_title "Sir Kendrick's Lady" %}
<div class="written-by">by {{ author_lewitt }}</div>
{% rating_stars 4 %}

### {% short_story_title "You're It" %}
<div class="written-by">by {{ author_meier }}</div>
{% rating_stars 5 %}

### {% short_story_title "Shared Experience" %}
<div class="written-by">by {{ author_stasheff }}</div>
{% rating_stars 1 %}

### {% short_story_title "The Murphosensor Bomb" %}
<div class="written-by">by {{ author_wehrstein }}</div>
{% rating_stars 5 %}

### {% short_story_title "Legacy" %}
<div class="written-by">by {{ author_johnson }}</div>
{% rating_stars 4 %}

### {% short_story_title "Endings" %}
<div class="written-by">by {{ author_forstchen }}</div>
{% rating_stars 5 %}
