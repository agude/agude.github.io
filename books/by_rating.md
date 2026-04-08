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
  - A Fire Upon The Deep
  - Surface Detail
  - Use of Weapons
  - Look to Windward
  - The Player of Games
  - Hyperion
  - Inversions
  - The Hydrogen Sonata
  - The Colonel
  - The Fall of Hyperion
  - The Triumphant
  - A Mote in Shadow
  - There Is No Antimemetics Division
  # 4 Stars
  - A Memory Called Empire
  - Artificial Condition
  - Network Effect
  - The Tainted Cup
  - Exit Strategy
  - Explorers on the Moon
  - Childhood's End
  - Excession
  - Roadside Picnic
  - A Desolation Called Peace
  - Salamandastron
  - Mattimeo
  - Serpent Valley
  - The Sword of the Lictor
  - The Citadel of the Autarch
  - The Shadow of the Torturer
  - A Canticle for Leibowitz
  - Destination Moon
  - Dragon's Egg
  - Wild Seed
  - The Unconquerable
  - The Short Victorious War
  - Pandora's Star
  - Judas Unchained
  - Metropolitan
  # 3 Stars
  - Eater
  - Night Without Stars
  - Field of Dishonor
  - On Basilisk Station
  - Rogue Protocol
  - A Drop of Corruption
  - The Honor of the Queen
  - Starquake
  - The Abyss Beyond Dreams
  - The Dreaming Void
  - Redwall
  - The Rise of Endymion
  - Endymion
  - Grand Melee
  - Patternmaster
  - Valuable Humans in Transit and Other Stories
  - Dog Soldier
  - Honor of the Regiment
  - Mariel of Redwall
  - We Are Legion (We Are Bob)
  - All Systems Red
  - Mossflower
  - Matter
  - The Claw of the Conciliator
  - Not Till We Are Lost
  - For We Are Many
  - Sunstone Imperative
  - Ymir
  - All These Worlds
  - Last Stand
  - "Home: Habitat, Range, Niche, Territory"
  - The Moon Is a Harsh Mistress
  - The Left Hand of Darkness
  - The War of the Worlds
  - The Darfsteller
  - Rogue Bolo
  - The Last Policeman
  - The State of the Art
  - The Blue Lotus
  - The Nameless City
  - "Flatland: A Romance of Many Dimensions"
  - "Bolo: Annals of the Dinochrome Brigade"
  # 2 Stars
  - There Is No Antimemetics Division (Original Edition)
  - Red Rising
  - Monday Begins on Saturday
  - This Is How You Lose the Time War
  - The Temporal Void
  - The Evolutionary Void
  - Chevalier
  - City on Fire
  - Mission of Gravity
  - Martin the Warrior
  - The Fractal Prince
  - The Dragon's Banker
  - Heaven's River
  - Gun, with Occasional Music
  - Clay's Ark
  - Cigars of the Pharaoh
  - Flowers for Algernon
  - Close to Critical
  - Star Light
  - The Causal Angel
  - Consider Phlebas
  - Countdown City
  - World of Trouble
  - The Sirens of Titan
  # 1 Stars
  - The Urth of the New Sun
  - Stand on Zanzibar
  - Lords of Uncreation
  - Eyes of the Void
  - Shards of Earth
  - The Quantum Thief
  - Mind of My Mind
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
