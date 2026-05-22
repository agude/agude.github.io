---
date: 2026-05-18 10:46:00 -0700
title: Neuromancer
book_authors: William Gibson
series: Sprawl
book_number: 1
is_anthology: false
rating: 5
image: /books/covers/neuromancer.jpg
wikidata_qid: Q662029
isbn: 978-0-441-56956-4
date_published: 1984-07-01
awards:
  - hugo
  - nebula
same_as_urls:
  - "https://www.wikidata.org/wiki/Q662029"
  - "https://en.wikipedia.org/wiki/Neuromancer"
  - "https://openlibrary.org/works/OL27258W"
  - "https://www.isfdb.org/cgi-bin/title.cgi?1475"
  - "https://www.britannica.com/topic/Neuromancer"
  - "https://www.librarything.com/work/609"
  - "https://www.google.com/search?kgmid=/m/05g5q"
---

{% book_link page.title %}, by {% author_link page.book_authors link=false %}, is the first book in {% series_text page.series link=false %}.

{% capture this_book %}{% book_link page.title %}{% endcapture %}
{% capture the_author %}{% author_link page.book_authors link=false %}{% endcapture %}
{% capture the_authors %}{% author_link page.book_authors link=false possessive %}{% endcapture %}
{% capture author_last_name_text %}{{ page.book_authors | split: " " | last }}{% endcapture %}
{% capture the_authors_lastname %}{% author_link page.book_authors link=false link_text=author_last_name_text %}{% endcapture %}
{% capture the_authors_lastname_possessive %}{% author_link page.book_authors link=false link_text=author_last_name_text possessive %}{% endcapture %}
{% capture the_author_link %}{% author_link page.book_authors %}{% endcapture %}
{% capture the_authors_link %}{% author_link page.book_authors possessive %}{% endcapture %}
{% capture the_authors_lastname_link %}{% author_link page.book_authors link_text=author_last_name_text %}{% endcapture %}
{% capture the_authors_lastname_possessive_link %}{% author_link page.book_authors link_text=author_last_name_text possessive %}{% endcapture %}

{% capture this_series %}{% series_text page.series %}{% endcapture %}

{% capture simmons %}{% author_link "Dan Simmons" %}{% endcapture %}
{% capture simmonss %}{% author_link "Dan Simmons" possessive %}{% endcapture %}
{% capture simmons_lastname %}{% author_link "Dan Simmons" link_text="Simmons" %}{% endcapture %}
{% capture simmonss_lastname %}{% author_link "Dan Simmons" link_text="Simmons" possessive %}{% endcapture %}
{% capture hyperion_cantos %}{% series_link "Hyperion Cantos" %}{% endcapture %}
{% capture hyperion %}{% book_link "Hyperion" %}{% endcapture %}

{% capture arkady_and_boris %}{% author_link "Arkady Strugatsky" link_text="Arkady" %} and {% author_link "Boris Strugatsky" %}{% endcapture %}
{% capture arkady_and_boriss %}{% author_link "Arkady Strugatsky" link_text="Arkady" %} and {% author_link "Boris Strugatsky" possessive %}{% endcapture %}
{% capture roadside_picnic %}{% book_link "Roadside Picnic" %}{% endcapture %}

{% capture banks %}{% author_link "Iain M. Banks" %}{% endcapture %}
{% capture bankss %}{% author_link "Iain M. Banks" possessive %}{% endcapture %}
{% capture banks_lastname %}{% author_link "Iain M. Banks" link_text="Banks" %}{% endcapture %}
{% capture bankss_lastname %}{% author_link "Iain M. Banks" link_text="Banks" possessive %}{% endcapture %}
{% capture culture %}{% series_link "Culture" %}{% endcapture %}
{% capture look_to_windward %}{% book_link "Look to Windward" %}{% endcapture %}
{% capture surface_detail %}{% book_link "Surface Detail" %}{% endcapture %}

{% capture qntm %}{% author_link "qntm" %}{% endcapture %}
{% capture qntms %}{% author_link "qntm" possessive %}{% endcapture %}
{% capture valuable_humans %}{% book_link "Valuable Humans in Transit and Other Stories" %}{% endcapture %}
{% capture lena %}{% short_story_link "Lena" from_book="Valuable Humans in Transit and Other Stories" %}{% endcapture %}

{% capture stephenson %}{% author_link "Neal Stephenson" %}{% endcapture %}
{% capture stephensons %}{% author_link "Neal Stephenson" possessive %}{% endcapture %}
{% capture stephenson_lastname %}{% author_link "Neal Stephenson" link_text="Stephenson" %}{% endcapture %}
{% capture stephensons_lastname %}{% author_link "Neal Stephenson" link_text="Stephenson" possessive %}{% endcapture %}
{% capture snow_crash %}{% book_link "Snow Crash" %}{% endcapture %}

{% capture brunner %}{% author_link "John Brunner" %}{% endcapture %}
{% capture brunners %}{% author_link "John Brunner" possessive %}{% endcapture %}
{% capture brunner_lastname %}{% author_link "John Brunner" link_text="Brunner" %}{% endcapture %}
{% capture brunners_lastname %}{% author_link "John Brunner" link_text="Brunner" possessive %}{% endcapture %}
{% capture stand_on_zanzibar %}{% book_link "Stand on Zanzibar" %}{% endcapture %}

{% capture watts %}{% author_link "Peter Watts" %}{% endcapture %}
{% capture wattss %}{% author_link "Peter Watts" possessive %}{% endcapture %}
{% capture watts_lastname %}{% author_link "Peter Watts" link_text="Watts" %}{% endcapture %}
{% capture wattss_lastname %}{% author_link "Peter Watts" link_text="Watts" possessive %}{% endcapture %}
{% capture firefall %}{% series_link "Firefall" %}{% endcapture %}
{% capture blindsight %}{% book_link "Blindsight" %}{% endcapture %}

{% capture stross %}{% author_link "Charles Stross" %}{% endcapture %}
{% capture strosss %}{% author_link "Charles Stross" possessive %}{% endcapture %}
{% capture stross_lastname %}{% author_link "Charles Stross" link_text="Stross" %}{% endcapture %}
{% capture strosss_lastname %}{% author_link "Charles Stross" link_text="Stross" possessive %}{% endcapture %}
{% capture accelerando %}{% book_link "Accelerando" %}{% endcapture %}

{% capture card %}{% author_link "Orson Scott Card" %}{% endcapture %}
{% capture cards %}{% author_link "Orson Scott Card" possessive %}{% endcapture %}
{% capture card_lastname %}{% author_link "Orson Scott Card" link_text="Card" %}{% endcapture %}
{% capture cards_lastname %}{% author_link "Orson Scott Card" link_text="Card" possessive %}{% endcapture %}
{% capture enders_game %}{% series_link "Ender's Game" %}{% endcapture %}
{% capture speaker_for_the_dead %}{% book_link "Speaker for the Dead" %}{% endcapture %}

{% capture fall %}{% author_link "Isabel Fall" %}{% endcapture %}
{% capture falls %}{% author_link "Isabel Fall" possessive %}{% endcapture %}
{% capture fall_lastname %}{% author_link "Isabel Fall" link_text="Fall" %}{% endcapture %}
{% capture falls_lastname %}{% author_link "Isabel Fall" link_text="Fall" possessive %}{% endcapture %}
{% capture attack_helicopter %}{% book_link "I Sexually Identify as an Attack Helicopter" %}{% endcapture %}

{% capture dick %}{% author_link "Philip K. Dick" %}{% endcapture %}
{% capture dicks %}{% author_link "Philip K. Dick" possessive %}{% endcapture %}
{% capture dick_lastname %}{% author_link "Philip K. Dick" link_text="Dick" %}{% endcapture %}
{% capture dicks_lastname %}{% author_link "Philip K. Dick" link_text="Dick" possessive %}{% endcapture %}
{% capture do_androids_dream %}{% book_link "Do Androids Dream of Electric Sheep?" %}{% endcapture %}

{% capture martine %}{% author_link "Arkady Martine" %}{% endcapture %}
{% capture martines %}{% author_link "Arkady Martine" possessive %}{% endcapture %}
{% capture martine_lastname %}{% author_link "Arkady Martine" link_text="Martine" %}{% endcapture %}
{% capture martines_lastname %}{% author_link "Arkady Martine" link_text="Martine" possessive %}{% endcapture %}
{% capture teixcalaan %}{% series_link "Teixcalaan" %}{% endcapture %}
{% capture a_memory_called_empire %}{% book_link "A Memory Called Empire" %}{% endcapture %}

{% capture taylor %}{% author_link "Dennis E. Taylor" %}{% endcapture %}
{% capture taylors %}{% author_link "Dennis E. Taylor" possessive %}{% endcapture %}
{% capture taylor_lastname %}{% author_link "Dennis E. Taylor" link_text="Taylor" %}{% endcapture %}
{% capture taylors_lastname %}{% author_link "Dennis E. Taylor" link_text="Taylor" possessive %}{% endcapture %}
{% capture bobiverse %}{% series_link "Bobiverse" %}{% endcapture %}
{% capture we_are_bob %}{% book_link "We Are Legion (We Are Bob)" %}{% endcapture %}

{% capture disco_elysium %}{% book_link "Disco Elysium" %}{% endcapture %}

{% capture sprawl %}{% series_link "Sprawl" %}{% endcapture %}
{% capture johnny_mnemonic %}{% short_story_link "Johnny Mnemonic" %}{% endcapture %}
{% capture burning_chrome %}{% book_link "Burning Chrome" %}{% endcapture %}

{% capture the_matrix %}{% movie_title "The Matrix" %}{% endcapture %}
{% capture deus_ex %}{% game_title "Deus Ex" %}{% endcapture %}
{% capture shadowrun %}{% game_title "Shadowrun" %}{% endcapture %}
{% capture dollhouse %}{% tv_show_title "Dollhouse" %}{% endcapture %}
{% capture westworld %}{% tv_show_title "Westworld" %}{% endcapture %}
{% capture blade_runner %}{% movie_title "Blade Runner" %}{% endcapture %}
{% capture elysium %}{% movie_title "Elysium" %}{% endcapture %}
{% capture inception %}{% movie_title "Inception" %}{% endcapture %}

{% capture weber %}{% author_link "David Weber" %}{% endcapture %}
{% capture webers %}{% author_link "David Weber" possessive %}{% endcapture %}
{% capture weber_lastname %}{% author_link "David Weber" link_text="Weber" %}{% endcapture %}
{% capture webers_lastname %}{% author_link "David Weber" link_text="Weber" possessive %}{% endcapture %}
{% capture honor_harrington %}{% series_link "Honor Harrington" %}{% endcapture %}
{% capture the_honor_of_the_queen %}{% book_link "The Honor of the Queen" %}{% endcapture %}

I was apprehensive about reading {{ this_book }}. It was so influential in the
cyberpunk genre---we'll talk about that later---that I was worried it would
come off derivative itself, having already read and see many of the works it
inspired. Or worse, that it would be all ideas with no story as we so often
see in science fiction.

{{ this_book }} is a heist. That's a great choice by {{ the_authors_lastname
}} because it gives the story instant momentum and a reason to explore the
world: you have to assemble the team.

I picked up {{ this_book }} after getting a chapter into my {{ snow_crash }}
re-read, and realizing I had never read a single thing by {{
the_authors_lastname }}. {{ snow_crash }} is a response and satire to a lot of
what {{ the_authors_lastname }} developed, and I knew I wouldn't be able to
spot it without first going through {{ this_book }}.

The puppet shops, where people can sell their bodies while their mind is
turned off, were later used by Whedon <!-- TODO: Link as author? Something
else? --> in {{ dollhouse }}. The way Wintermute _literally_ can't know the
code word, it just can't exist in his mind, is similar to how the host robots
in {{ westworld }} can't see things that might reveal they're hosts.
