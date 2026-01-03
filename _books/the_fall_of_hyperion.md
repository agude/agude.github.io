---
date: 2025-12-30
title: The Fall of Hyperion
book_authors: Dan Simmons
series: Hyperion Cantos
book_number: 2
rating: 5
image: /books/covers/the_fall_of_hyperion.jpg
awards:
  - locus
---

<cite class="book-title">{{ page.title }}</cite>, by <span
class="author-name">{{ page.book_authors }}</span>, is the second book in the
<span class="book-series">{{ page.series }}</span> series, but really it's the
second half of {% book_link "Hyperion" %}. It sees the end of the seven
pilgrims' story, and way between the TechnoCore, the Ousters, and the
Hegemony.

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

{% capture simmons %}{% author_link "Dan Simmons" %}{% endcapture %}
{% capture simmonss %}{% author_link "Dan Simmons" possessive %}{% endcapture %}
{% capture simmons_lastname %}{% author_link "Dan Simmons" link_text="Simmons" %}{% endcapture %}
{% capture simmonss_lastname %}{% author_link "Dan Simmons" possessive link_text="Simmons" %}{% endcapture %}
{% capture hyperion %}{% book_link "Hyperion" %}{% endcapture %}
{% capture the_fall_of_hyperion %}{% book_link "The Fall of Hyperion" %}{% endcapture %}
{% capture hyperion_cantos %}{% series_link "Hyperion Cantos" %}{% endcapture %}

{% capture banks %}{% author_link "Iain M. Banks" %}{% endcapture %}
{% capture bankss %}{% author_link "Iain M. Banks" possessive %}{% endcapture %}
{% capture banks_lastname %}{% author_link "Iain M. Banks" link_text="Banks" %}{% endcapture %}
{% capture bankss_lastname %}{% author_link "Iain M. Banks" possessive link_text="Banks" %}{% endcapture %}
{% capture the_player_of_games %}{% book_link "The Player of Games" %}{% endcapture %}
{% capture surface_detail %}{% book_link "Surface Detail" %}{% endcapture %}

{% capture el_mohtar %}{% author_link "Amal El-Mohtar" %}{% endcapture %}
{% capture el_mohtars %}{% author_link "Amal El-Mohtar" possessive %}{% endcapture %}
{% capture el_mohtar_lastname %}{% author_link "Amal El-Mohtar" link_text="El-Mohtar" %}{% endcapture %}
{% capture el_mohtars_lastname %}{% author_link "Amal El-Mohtar" possessive link_text="El-Mohtar" %}{% endcapture %}
{% capture gladstone %}{% author_link "Max Gladstone" %}{% endcapture %}
{% capture gladstones %}{% author_link "Max Gladstone" possessive %}{% endcapture %}
{% capture gladstone_lastname %}{% author_link "Max Gladstone" link_text="Gladstone" %}{% endcapture %}
{% capture gladstones_lastname %}{% author_link "Max Gladstone" possessive link_text="Gladstone" %}{% endcapture %}
{% capture el_mohtar_and_gladstone %}{% author_link "Amal El-Mohtar" %} and {% author_link "Max Gladstone" %}{% endcapture %}
{% capture this_is_how_you_lose_the_time_war %}{% book_link "This Is How You Lose the Time War" %}{% endcapture %}

{% capture vonnegut %}{% author_link "Kurt Vonnegut" %}{% endcapture %}
{% capture vonneguts %}{% author_link "Kurt Vonnegut" possessive %}{% endcapture %}
{% capture vonnegut_lastname %}{% author_link "Kurt Vonnegut" link_text="Vonnegut" %}{% endcapture %}
{% capture vonneguts_lastname %}{% author_link "Kurt Vonnegut" possessive link_text="Vonnegut" %}{% endcapture %}
{% capture the_sirens_of_titan %}{% book_link "The Sirens of Titan" %}{% endcapture %}

{% capture taylor %}{% author_link "Dennis E. Taylor" %}{% endcapture %}
{% capture taylors %}{% author_link "Dennis E. Taylor" possessive %}{% endcapture %}
{% capture taylor_lastname %}{% author_link "Dennis E. Taylor" link_text="Taylor" %}{% endcapture %}
{% capture taylors_lastname %}{% author_link "Dennis E. Taylor" possessive link_text="Taylor" %}{% endcapture %}
{% capture bobiverse %}{% series_link "Bobiverse" %}{% endcapture %}

{% capture weber %}{% author_link "David Weber" %}{% endcapture %}
{% capture webers %}{% author_link "David Weber" possessive %}{% endcapture %}
{% capture weber_lastname %}{% author_link "David Weber" link_text="Weber" %}{% endcapture %}
{% capture webers_lastname %}{% author_link "David Weber" possessive link_text="Weber" %}{% endcapture %}
{% capture honor_harrington %}{% series_link "Honor Harrington" %}{% endcapture %}

{% capture asimov %}{% author_link "Isaac Asimov" %}{% endcapture %}
{% capture asimovs %}{% author_link "Isaac Asimov" possessive %}{% endcapture %}
{% capture asimov_lastname %}{% author_link "Isaac Asimov" link_text="Asimov" %}{% endcapture %}
{% capture asimovs_lastname %}{% author_link "Isaac Asimov" possessive link_text="Asimov" %}{% endcapture %}
{% capture i_robot %}{% book_link "I, Robot" %}{% endcapture %}

{% capture baum %}{% author_link "L. Frank Baum" %}{% endcapture %}
{% capture baums %}{% author_link "L. Frank Baum" possessive %}{% endcapture %}
{% capture baum_lastname %}{% author_link "L. Frank Baum" link_text="Baum" %}{% endcapture %}
{% capture baums_lastname %}{% author_link "L. Frank Baum" possessive link_text="Baum" %}{% endcapture %}
{% capture the_wonderful_wizard_of_oz %}{% book_link "The Wonderful Wizard of Oz" %}{% endcapture %}

{% capture wolfe %}{% author_link "Gene Wolfe" %}{% endcapture %}
{% capture wolfes %}{% author_link "Gene Wolfe" possessive %}{% endcapture %}
{% capture wolfe_lastname %}{% author_link "Gene Wolfe" link_text="Wolfe" %}{% endcapture %}
{% capture wolfes_lastname %}{% author_link "Gene Wolfe" possessive link_text="Wolfe" %}{% endcapture %}
{% capture botns %}{% series_link "The Book of the New Sun" %}{% endcapture %}

{% capture terminator %}<cite class="movie-title">The Terminator</cite>{% endcapture %}

{% capture moore %}{% author_link "Alan Moore" %}{% endcapture %}
{% capture moores %}{% author_link "Alan Moore" possessive %}{% endcapture %}
{% capture moore_lastname %}{% author_link "Alan Moore" link_text="Moore" %}{% endcapture %}
{% capture moores_lastname %}{% author_link "Alan Moore" possessive link_text="Moore" %}{% endcapture %}

{% capture gibbons %}{% author_link "Dave Gibbons" %}{% endcapture %}
{% capture gibbonss %}{% author_link "Dave Gibbons" possessive %}{% endcapture %}
{% capture gibbons_lastname %}{% author_link "Dave Gibbons" link_text="Gibbons" %}{% endcapture %}
{% capture gibbonss_lastname %}{% author_link "Dave Gibbons" possessive link_text="Gibbons" %}{% endcapture %}

{% capture moore_and_gibbons %}{% author_link "Alan Moore" %} and {% author_link "Dave Gibbons" %}{% endcapture %}
{% capture watchmen %}{% book_link "Watchmen" %}{% endcapture %}

I loved {{ this_book }} when I [first read it][first_read], even more so than
{{ hyperion }}. It tells a much simpler story: delivering space battles, the
Soldier fighting the Shrike, and answers to every mystery. It just doesn't
require the kind of close reading {{ hyperion }} does.

In this second read through, I recognized {{ hyperion }} for the masterpiece
it is, on the same level of as {{ wolfes_lastname }} {{ botns }} <!-- TODO...
What else? Things I rate more highly are: Firefall; Fire Upon The Deep; and
Surface Detail, Use of Weapons, Look to Windward, Player of Games, and
Inversions. BOTNS is actually rated much lower (4 stars) but I think on a
reread I'd move it into the high 5-stars with the others.-->, but my opinion
of this book didn't change; it's still great, but the gap between it and the
first book widened considerably.

[first_read]: {% link _books/the_fall_of_hyperion/review-2023-10-27.md %}

<!-- TODO Gladstone as Ozymandius -->

### Themes

1. Abrahamic Sacrific
2. Evolution of God: Technocore logical god vs evolved human empathetic god.
   Teilhard de Chardin
3. Dream and poet as observer
4. Fall of the old order
5. Pain as a force the motivates. Hegemony's life is too easy, stagnant.
   Ousters adapt themselves to the world, not the world to themselves.
