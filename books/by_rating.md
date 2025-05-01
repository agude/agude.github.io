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

{% render_ranked_books page.ranked_list %}
