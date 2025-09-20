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
  - Disco Elysium
  - Echopraxia
  - Blindsight
  - A Fire Upon the Deep
  - Surface Detail
  - Use of Weapons
  - Look to Windward
  - The Player of Games
  - Inversions
  - Hyperion
  - Pandora's Star
  - Judas Unchained
  - The Hydrogen Sonata
  - A Memory Called Empire
  - Night Without Stars
  - Exit Strategy
  - The Colonel
  - The Fall of Hyperion
  - Artificial Condition
  - Network Effect
  - Rogue Protocol
  - A Desolation Called Peace
  - Explorers on the Moon
  - Childhood's End
  - Dragon's Egg
  - Starquake
  - Salamandastron
  - Mattimeo
  - Roadside Picnic
  - The Abyss Beyond Dreams
  - Serpent Valley
  - A Mote in Shadow
  - The Dreaming Void
  # 4 Stars
  - Excession
  - Redwall
  - The Tainted Cup
  - The Sword of the Lictor
  - The Citadel of the Autarch
  - The Shadow of the Torturer
  - Destination Moon
  - Eater
  - The Unconquerable
  - Patternmaster
  - Wild Seed
  - Grand Melee
  - Metropolitan
  - The Temporal Void
  - The Evolutionary Void
  - Valuable Humans in Transit and Other Stories
  - Dog Soldier
  - Honor of the Regiment
  - Mariel of Redwall
  - We Are Legion (We Are Bob)
  - All Systems Red
  - A Drop of Corruption
  - Mossflower
  - Matter
  - Not Till We Are Lost
  - For We Are Many
  - Ymir
  - City on Fire
  - All These Worlds
  # 3 Stars
  - Mission of Gravity
  - "Home: Habitat, Range, Niche, Territory"
  - Martin The Warrior
  - Chevalier
  - The Left Hand of Darkness
  - The War of the Worlds
  - Rogue Bolo
  - The Last Policeman
  - Gun, with Occasional Music
  - Heaven's River
  - The Claw of the Conciliator
  - The Dragon's Banker
  - The State of the Art
  - The Blue Lotus
  - Clay's Ark
  - Lords of Uncreation
  - The Nameless City
  - "Flatland: A Romance of Many Dimensions"
  - The Fractal Prince
  - Cigars of the Pharaoh
  - Flowers for Algernon
  - "Bolo: Annals of the Dinochrome Brigade"
  - Countdown City
  - Eyes of the Void
  - Shards of Earth
  - The Causal Angel
  - There Is No Antimemetics Division
  # 2 Stars
  - Close to Critical
  - Star Light
  - World of Trouble
  - Stand on Zanzibar
  - Mind of My Mind
  - The Quantum Thief
  - The Urth of the New Sun
  # 1 Stars
  - Consider Phlebas
  - House of Suns
  - Tintin in the Congo
  - The Three-Body Problem
---

Below you'll find short reviews of the books I've read, grouped by rating and
ranked within each group.

{% include books_topbar.html %}

{% comment %}
Display books grouped by rating, using the order defined in page.ranked_list.
The tag also validates the list's monotonicity and book existence in
non-production environments, halting the build on error.
{% endcomment %}

{% display_ranked_books page.ranked_list %}
