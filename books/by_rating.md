---
title: "Book Reviews: By Rating"
short_title: Rating
layout: page
permalink: /books/by-rating/
book_topbar_include: true
description: >
  Alexander Gude's (short) book reviews, grouped by rating and ranked within
  each group.
redirect_from: /books/ranked/
ranked_list:
  # 5 Stars
  - Echopraxia
  - Blindsight
  - A Fire Upon the Deep
  - Surface Detail
  - Use of Weapons
  - Look to Windward
  - The Player of Games
  - Inversions
  - Pandora's Star
  - Judas Unchained
  - The Hydrogen Sonata
  - A Memory Called Empire
  - Night Without Stars
  - The Colonel
  - The Fall of Hyperion
  - A Desolation Called Peace
  - Childhood's End
  - Dragon's Egg
  - Starquake
  - Salamandastron
  - Mattimeo
  - The Abyss Beyond Dreams
  - Serpent Valley
  - The Dreaming Void
  # 4 Stars
  - Excession
  - Redwall
  - Hyperion
  - The Tainted Cup
  - Patternmaster
  - Wild Seed
  - Eater
  - The Citadel of the Autarch
  - Grand Melee
  - The Temporal Void
  - The Evolutionary Void
  - The Sword of the Lictor
  - Valuable Humans in Transit and Other Stories
  - Dog Soldier
  - Mariel of Redwall
  - We Are Legion (We Are Bob)
  - A Drop of Corruption
  - Mossflower
  - Matter
  - For We Are Many
  - Ymir
  - The Shadow of the Torturer
  - The Last Policeman
  - All These Worlds
  # 3 Stars
  - Mission of Gravity
  - Martin The Warrior
  - The Left Hand of Darkness
  - Gun, with Occasional Music
  - Countdown City
  - Heaven's River
  - The Dragon's Banker
  - The State of the Art
  - Clay's Ark
  - The Nameless City
  - World of Trouble
  - "Flatland: A Romance of Many Dimensions"
  - The Fractal Prince
  - Flowers for Algernon
  - Chevalier
  - The Claw of the Conciliator
  - The Causal Angel
  - There Is No Antimemetics Division
  # 2 Stars
  - Close to Critical
  - Star Light
  - Stand on Zanzibar
  - Mind of My Mind
  - The Quantum Thief
  - The Urth of the New Sun
  # 1 Stars
  - Consider Phlebas
  - House of Suns
  - The Three-Body Problem
---

Below you'll find short reviews of the books I've read, grouped by rating and
ranked within each group.

{% include books_topbar.html %}

{% comment %}
Ensure that the ranking is monotonically decreasing in star rating
(non-production only)
{% endcomment %}
{% check_monotonic_rating page.ranked_list %}

{% comment %}
Iterate through ratings (high to low) and display books
from the ranked_list that match each rating.
{% endcomment %}

{%- capture newline %}
{% endcapture -%}

{% assign ratings_to_process = "5|4|3|2|1" | split: "|" %}
{% assign ranked_titles = page.ranked_list %}

{% for current_rating_str in ratings_to_process %}

  {% comment %} Convert the rating string to an integer for filtering {% endcomment %}
  {% assign current_rating_int = current_rating_str | plus: 0 %}

  {% comment %} OPTIMIZATION: Pre-filter site.books using the INTEGER rating {% endcomment %}
  {% assign books_with_current_rating = site.books | where_exp: "item", "item.rating == current_rating_int" %}

  {% comment %} Find book OBJECTS from the ranked list matching the current rating {% endcomment %}
  {% assign books_in_rating_group = "" | split: "" %}
  {% for ranked_title in ranked_titles %}
    {% assign found_book_object = false %}

    {% comment %} Prepare the target title from the ranked list (robust matching) {% endcomment %}
    {% assign target_title_processed = ranked_title | replace: newline, " " | downcase | strip %}

    {% comment %} Loop ONLY through the pre-filtered books {% endcomment %}
    {% for book in books_with_current_rating %}
      {% unless book.title %}{% continue %}{% endunless %}
      {% assign current_title_processed = book.title | replace: newline, " " | downcase | strip %}

      {% if current_title_processed == target_title_processed %}
        {% assign found_book_object = book %}
        {% break %}
      {% endif %}
    {% endfor %}

    {% comment %} Add the book if found with the correct rating {% endcomment %}
    {% if found_book_object %}
       {% assign books_in_rating_group = books_in_rating_group | push: found_book_object %}
    {% elsif jekyll.environment != "production" %}
       {% comment %} If not found for THIS rating, check if the title exists AT ALL in site.books.
           Log only if the title from ranked_list is completely missing from the site data. {% endcomment %}
       {% assign title_exists_in_site = false %}
       {% for book_check in site.books %}
         {% unless book_check.title %}{% continue %}{% endunless %}
         {% assign check_title_processed = book_check.title | replace: newline, " " | downcase | strip %}
         {% if check_title_processed == target_title_processed %}
           {% assign title_exists_in_site = true %}
           {% break %}
         {% endif %}
       {% endfor %}

       {% comment %} Only log an error if the title from the ranked list was never found in site.books {% endcomment %}
       {% unless title_exists_in_site %}
<!-- WARNING: RANKED_LIST_TITLE_NOT_FOUND_IN_SITE: Title='{{ ranked_title | escape }}' -->
       {% endunless %}
    {% endif %}
  {% endfor %}

  {% comment %} Display the section if books were found for this rating {% endcomment %}
  {% if books_in_rating_group.size > 0 %}
<h2 class="book-list-headline" id="rating-{{ current_rating_str }}">{% include book_rating.html rating=current_rating_int wrapper_tag="span" %}</h2>
<div class="card-grid">
      {% for book in books_in_rating_group %}
        {% include book_card.html
          url=book.url
          image=book.image
          title=book.title
          author=book.book_author
          rating=book.rating
          description=book.excerpt
        %}
      {% endfor %}
</div>
  {% endif %}

{% endfor %}
