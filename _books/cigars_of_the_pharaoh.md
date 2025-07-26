---
date: 2025-07-25
title: Cigars of the Pharaoh
book_authors: Hergé
series: The Adventures of Tintin
book_number: 4
rating: null
image: /books/covers/cigars_of_the_pharoah.jpg
---

<cite class="book-title">{{ page.title }}</cite>, by <span
class="author-name">{{ page.book_authors }}</span>, is the forth book in the
<span class="book-series">{{ page.series }}</span>.

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

{% capture tt1 %}{% book_link "Tintin in the Land of the Soviets" %}{% endcapture %}
{% capture tt2 %}{% book_link "Tintin in the Congo" %}{% endcapture %}
{% capture tt3 %}{% book_link "Tintin in America" %}{% endcapture %}
{% capture tt4 %}{% book_link "Cigars of the Pharaoh" %}{% endcapture %}
{% capture tt5 %}{% book_link "The Blue Lotus" %}{% endcapture %}
{% capture tt6 %}{% book_link "The Broken Ear" %}{% endcapture %}
{% capture tt7 %}{% book_link "The Black Island" %}{% endcapture %}
{% capture tt8 %}{% book_link "King Ottokar's Sceptre" %}{% endcapture %}
{% capture tt9 %}{% book_link "The Crab with the Golden Claws" %}{% endcapture %}
{% capture tt10 %}{% book_link "The Shooting Star" %}{% endcapture %}
{% capture tt11 %}{% book_link "The Secret of the Unicorn" %}{% endcapture %}
{% capture tt12 %}{% book_link "Red Rackham's Treasure" %}{% endcapture %}
{% capture tt13 %}{% book_link "The Seven Crystal Balls" %}{% endcapture %}
{% capture tt14 %}{% book_link "Prisoners of the Sun" %}{% endcapture %}
{% capture tt15 %}{% book_link "Land of Black Gold" %}{% endcapture %}
{% capture tt16 %}{% book_link "Destination Moon" %}{% endcapture %}
{% capture tt17 %}{% book_link "Explorers on the Moon" %}{% endcapture %}
{% capture tt18 %}{% book_link "The Calculus Affair" %}{% endcapture %}
{% capture tt19 %}{% book_link "The Red Sea Sharks" %}{% endcapture %}
{% capture tt20 %}{% book_link "Tintin in Tibet" %}{% endcapture %}
{% capture tt21 %}{% book_link "The Castafiore Emerald" %}{% endcapture %}
{% capture tt22 %}{% book_link "Flight 714 to Sydney" %}{% endcapture %}
{% capture tt23 %}{% book_link "Tintin and the Picaros" %}{% endcapture %}
{% capture tt24 %}{% book_link "Tintin and Alph-Art" %}{% endcapture %}
