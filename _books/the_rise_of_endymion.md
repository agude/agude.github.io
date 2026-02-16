---
date: 2026-02-13
title: The Rise of Endymion
book_authors: Dan Simmons
series: Hyperion Cantos
book_number: 4
rating: 4
image: /books/covers/the_rise_of_endymion.jpg
---

<cite class="book-title">{{ page.title }}</cite>, by <span
class="author-name">{{ page.book_authors }}</span>, is the forth and final book in the
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

{% capture hyperion %}{% book_link "Hyperion" %}{% endcapture %}
{% capture fall_hyperion %}{% book_link "The Fall of Hyperion" %}{% endcapture %}
{% capture endymion %}{% book_link "Endymion" %}{% endcapture %}
{% capture ilium %}{% book_link "Ilium" %}{% endcapture %}
{% capture olympos %}{% book_link "Olympos" %}{% endcapture %}
{% capture flashback %}{% book_link "Flashback" %}{% endcapture %}

{% capture rowling %}{% author_link "J. K. Rowling" %}{% endcapture %}
{% capture asimov_lastname %}{% author_link "Isaac Asimov" link_text="Asimov" %}{% endcapture %}

{% capture keatss %}{% author_link "John Keats" possessive %}{% endcapture %}
{% capture keats_lastname %}{% author_link "John Keats" link_text="Keats" %}{% endcapture %}
{% capture keats_lastname_possessive %}{% author_link "John Keats" link_text="Keats" possessive %}{% endcapture %}
{% capture hyperion_keats %}{% book_link "Hyperion" author="John Keats" %}{% endcapture %}

{% capture look_to_windward %}{% book_link "Look to Windward" %}{% endcapture %}
{% capture the_hydrogen_sonata %}{% book_link "The Hydrogen Sonata" %}{% endcapture %}
{% capture culture %}{% series_link "Culture" %}{% endcapture %}
{% capture banks %}{% author_link "Iain M. Banks" %}{% endcapture %}
{% capture bankss %}{% author_link "Iain M. Banks" possessive %}{% endcapture %}
{% capture banks_lastname %}{% author_link "Iain M. Banks" link_text="Banks" %}{% endcapture %}
{% capture bankss_lastname %}{% author_link "Iain M. Banks" link_text="Banks" possessive %}{% endcapture %}

{% capture a_memory_called_empire %}{% book_link "A Memory Called Empire" %}{% endcapture %}
{% capture martine %}{% author_link "Arkady Martine" %}{% endcapture %}
{% capture martines %}{% author_link "Arkady Martine" possessive %}{% endcapture %}
{% capture martine_lastname %}{% author_link "Arkady Martine" link_text="Martine" %}{% endcapture %}
{% capture martines_lastname %}{% author_link "Arkady Martine" link_text="Martine" possessive %}{% endcapture %}

{% capture to_kill_a_mockingbird %}{% book_link "To Kill a Mockingbird" %}{% endcapture %}
{% capture lee %}{% author_link "Harper Lee" %}{% endcapture %}
{% capture lees %}{% author_link "Harper Lee" possessive %}{% endcapture %}
{% capture lee_lastname %}{% author_link "Harper Lee" link_text="Lee" %}{% endcapture %}
{% capture lees_lastname %}{% author_link "Harper Lee" link_text="Lee" possessive %}{% endcapture %}

{% capture city_on_fire %}{% book_link "City on Fire" %}{% endcapture %}
{% capture williams %}{% author_link "Walter John Williams" %}{% endcapture %}
{% capture williamss %}{% author_link "Walter John Williams" possessive %}{% endcapture %}
{% capture williams_lastname %}{% author_link "Walter John Williams" link_text="Williams" %}{% endcapture %}
{% capture williamss_lastname %}{% author_link "Walter John Williams" link_text="Williams" possessive %}{% endcapture %}

{% capture judas_unchained %}{% book_link "Judas Unchained" %}{% endcapture %}
{% capture hamilton %}{% author_link "Peter F. Hamilton" %}{% endcapture %}
{% capture hamiltons %}{% author_link "Peter F. Hamilton" possessive %}{% endcapture %}
{% capture hamilton_lastname %}{% author_link "Peter F. Hamilton" link_text="Hamilton" %}{% endcapture %}
{% capture hamiltons_lastname %}{% author_link "Peter F. Hamilton" link_text="Hamilton" possessive %}{% endcapture %}

{% capture the_moon_is_a_harsh_mistress %}{% book_link "The Moon Is a Harsh Mistress" %}{% endcapture %}
{% capture heinlein %}{% author_link "Robert A. Heinlein" %}{% endcapture %}
{% capture heinleins %}{% author_link "Robert A. Heinlein" possessive %}{% endcapture %}
{% capture heinlein_lastname %}{% author_link "Robert A. Heinlein" link_text="Heinlein" %}{% endcapture %}
{% capture heinleins_lastname %}{% author_link "Robert A. Heinlein" link_text="Heinlein" possessive %}{% endcapture %}

{% capture bradbury %}{% author_link "Ray Bradbury" %}{% endcapture %}
{% capture bradburys %}{% author_link "Ray Bradbury" possessive %}{% endcapture %}
{% capture bradbury_lastname %}{% author_link "Ray Bradbury" link_text="Bradbury" %}{% endcapture %}
{% capture bradburys_lastname %}{% author_link "Ray Bradbury" link_text="Bradbury" possessive %}{% endcapture %}

{% capture childhoods_end %}{% book_link "Childhood's End" %}{% endcapture %}
{% capture clarke %}{% author_link "Arthur C. Clarke" %}{% endcapture %}
{% capture clarkes %}{% author_link "Arthur C. Clarke" possessive %}{% endcapture %}
{% capture clarke_lastname %}{% author_link "Arthur C. Clarke" link_text="Clarke" %}{% endcapture %}
{% capture clarkes_lastname %}{% author_link "Arthur C. Clarke" link_text="Clarke" possessive %}{% endcapture %}

{% capture dune %}{% book_link "Dune" %}{% endcapture %}
{% capture herbert %}{% author_link "Frank Herbert" %}{% endcapture %}
{% capture herberts %}{% author_link "Frank Herbert" possessive %}{% endcapture %}
{% capture herbert_lastname %}{% author_link "Frank Herbert" link_text="Herbert" %}{% endcapture %}
{% capture herberts_lastname %}{% author_link "Frank Herbert" link_text="Herbert" possessive %}{% endcapture %}

{% capture wolfe %}{% author_link "Gene Wolfe" %}{% endcapture %}
{% capture wolfes %}{% author_link "Gene Wolfe" possessive %}{% endcapture %}
{% capture wolfe_lastname %}{% author_link "Gene Wolfe" link_text="Wolfe" %}{% endcapture %}
{% capture wolfes_lastname %}{% author_link "Gene Wolfe" link_text="Wolfe" possessive %}{% endcapture %}

{% capture final_architecture %}{% series_link "The Final Architecture" %}{% endcapture %}
{% capture tchaikovsky %}{% author_link "Adrian Tchaikovsky" %}{% endcapture %}
{% capture tchaikovskys %}{% author_link "Adrian Tchaikovsky" possessive %}{% endcapture %}
{% capture tchaikovsky_lastname %}{% author_link "Adrian Tchaikovsky" link_text="Tchaikovsky" %}{% endcapture %}
{% capture tchaikovskys_lastname %}{% author_link "Adrian Tchaikovsky" link_text="Tchaikovsky" possessive %}{% endcapture %}

{% capture this_is_how_you_lose_the_time_war %}{% book_link "This Is How You Lose the Time War" %}{% endcapture %}
{% capture el_mohtar %}{% author_link "Amal El-Mohtar" %}{% endcapture %}
{% capture el_mohtars %}{% author_link "Amal El-Mohtar" possessive %}{% endcapture %}
{% capture el_mohtar_lastname %}{% author_link "Amal El-Mohtar" link_text="El-Mohtar" %}{% endcapture %}
{% capture el_mohtars_lastname %}{% author_link "Amal El-Mohtar" link_text="El-Mohtar" possessive %}{% endcapture %}
{% capture gladstone %}{% author_link "Max Gladstone" %}{% endcapture %}
{% capture gladstones %}{% author_link "Max Gladstone" possessive %}{% endcapture %}
{% capture gladstone_lastname %}{% author_link "Max Gladstone" link_text="Gladstone" %}{% endcapture %}
{% capture gladstones_lastname %}{% author_link "Max Gladstone" link_text="Gladstone" possessive %}{% endcapture %}
{% capture el_mohtar_and_gladstone %}{% author_link "Amal El-Mohtar" %} and {% author_link "Max Gladstone" %}{% endcapture %}
{% capture el_mohtar_and_gladstones %}{% author_link "Amal El-Mohtar" %} and {% author_link "Max Gladstone" possessive %}{% endcapture %}

{% capture waiting_for_godot %}{% book_link "Waiting for Godot" %}{% endcapture %}
{% capture beckett %}{% author_link "Samuel Beckett" %}{% endcapture %}
{% capture becketts %}{% author_link "Samuel Beckett" possessive %}{% endcapture %}
{% capture beckett_lastname %}{% author_link "Samuel Beckett" link_text="Beckett" %}{% endcapture %}
{% capture becketts_lastname %}{% author_link "Samuel Beckett" link_text="Beckett" possessive %}{% endcapture %}

{% capture et %}<cite class="movie-title">E.T. the Extra-Terrestrial</cite>{% endcapture %}

{{ this_book }} breaks from the past three books in the {{ this_series }} in
that it is not named and themes after one of {{ keats_lastname_possessive }}
works. Instead, it mirrors {{ keats_lastname_possessive }} life. Aenea is a {{
keats_lastname }} stand-in, who like the poet knows her time is short rush to
complete her life's work of helping people understand the world and become
empathetic. Her philosophy and interaction with the Void Which Binds embodies
his concept of the _Chameleon Poet_ {{ keats_lastname }}, allowing everyone to
feel which others are.

Aenea is _also_ a Christ-like figure, a point {{ the_authors_lastname }}
drives home when he has her explain that Christ was the first human able to
touch the Void. Like Christ, Aenea's disciples drink her blood to gain her
abilities. And she is tortured to death just as the Christian messiah. This
continues the theme of "dying into life", with her mass movement taking off
only with the Shared Moment sent out through Void at her death. Dying into
life is taken to its final extreme in {{ this_book }}, with Aenea preaching
that the human race must splinter into many new races to survive.

I liked this book about the same as {{ endymion }}, but I think it's pacing
was much worse. The first third of the book jumps back and forth between
from cliffhanger to cliffhanger, but the middle third on T'ien Shan drags as
it spend 300 pages in one place, following Aenea as she preaches to her
disciples. The book is saved by a climax that wraps up the series and explains
further mysteries from the first few books, just as {{ fall_hyperion }} does
for {{ hyperion }}.

I still didn't like Raul or Aenea, although their relationship was a little
better this time around. But the supporting characters---A. Bettik, Federico
de Soya, Kassad---are great, although Bettik gets written out of this book a
bit only to show up at the end of the observer for the other powers of the
Void.

### The Author

{{ the_author }} has been a mystery to me while I read {{ this_series }}. I
know that he is now a far-right fascist, and so I've looked for the seeds of
it in his work, but they're hard to find. They feature multicultural casts,
there are gay characters in the background, the thesis of {{ this_book }} is
that diversity is our strength. Kassad, a Muslim, is one of the heroes.

But although the seeds are hard to find, they are there: his an obsession with
the sexuality of young girls, the way he writes about the violence and
barbarianism of Muslims, and his disparagingly refers to welfare queens.

I don't think I will read any more of {{ the_authors_lastname_possessive }}
work. I hear {{ ilium }} and {{ olympos }} take the anti-Muslim stance up
another level, and that {{ flashback }} is a right-wing screed against a
barely disguised Obama. In someways it is easier to support an artist who is a
horrible person---like {{ asimov_lastname }} or {{ clarke_lastname }}---after
they're dead. I won't read {{ rowling }} because supporting her gives her more
money and power to attack my trans friends, and likewise with {{
the_authors_lastname }}.
