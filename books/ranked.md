---
title: "Book Reviews: Ranked"
layout: page
permalink: /books/ranked/
book_topbar_include: false
description: >
  Alexander Gude's (short) book reviews.
ranked_list:
  # 5 Stars
  - Echopraxia
  - Blindsight
  - A Fire Upon the Deep
  - Use of Weapons
  - The Player of Games
  - Pandora's Star
  - Judas Unchained
  - Night Without Stars
  - The Colonel
  - The Fall of Hyperion
  - Childhood's End
  - Dragon's Egg
  - Starquake
  - Mattimeo
  - The Abyss Beyond Dreams
  - Serpent Valley
  - The Dreaming Void
  # 4 Stars
  - Excession
  - Redwall
  - Hyperion
  - The Tainted Cup
  - Eater
  - The Citadel of the Autarch
  - The Temporal Void
  - The Evolutionary Void
  - The Sword of the Lictor
  - Valuable Humans in Transit and Other Stories
  - Dog Soldier
  - Mariel of Redwall
  - We Are Legion (We Are Bob)
  - Mossflower
  - For We Are Many
  - The Last Policeman
  - Ymir
  - The Shadow of the Torturer
  - All These Worlds
  # 3 Stars
  - Mission of Gravity
  - Gun, with Occasional Music
  - Countdown City
  - Heaven's River
  - The Dragon's Banker
  - The State of the Art
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
  - The Quantum Thief
  - The Urth of the New Sun
  # 1 Stars
  - Consider Phlebas
  - House of Suns
  - The Three-Body Problem
---

{% include books_topbar.html %}

<h2 class="book-list-headline">Ranked List of Books</h2>

<div class="card-grid">

{% for book in page.ranked_list %}
  {% include auto_book_card.html title=book %}
{% endfor %}

</div>
