---
date: 2026-03-01 20:34:56 -0800
title: Red Rising
book_authors: Pierce Brown
series: Red Rising Trilogy
book_number: 1
is_anthology: false
rating: 3
image: /books/covers/red_rising.jpg
wikidata_qid: Q18393778
isbn: 978-0-345-53978-6
date_published: 2014-01-28
same_as_urls:
  - "https://www.wikidata.org/wiki/Q18393778"
  - "https://en.wikipedia.org/wiki/Red_Rising"
  - "https://openlibrary.org/works/OL17076473W"
  - "https://www.isfdb.org/cgi-bin/title.cgi?1664916"
  - "https://www.librarything.com/work/13865214"
  - "https://www.google.com/search?kgmid=/m/0_kqnv7"
---

{% book_link page.title %}, by {% author_link page.book_authors link=false %},
is the first book in {% series_text page.series link=false %}.

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

{% capture rand %}{% author_link "Ayn Rand" %}{% endcapture %}
{% capture rands %}{% author_link "Ayn Rand" possessive %}{% endcapture %}  
{% capture rand_lastname %}{% author_link "Ayn Rand" link_text="Rand" %}{% endcapture %}
{% capture rands_lastname %}{% author_link "Ayn Rand" link_text="Rand" possessive %}{% endcapture %}
{% capture atlas_shrugged %}{% book_link "Atlas Shrugged" %}{% endcapture %}

{% capture heinlein %}{% author_link "Robert A. Heinlein" %}{% endcapture %}  
{% capture heinleins %}{% author_link "Robert A. Heinlein" possessive %}{% endcapture %}  
{% capture heinlein_lastname %}{% author_link "Robert A. Heinlein" link_text="Heinlein" %}{% endcapture %}  
{% capture heinleins_lastname %}{% author_link "Robert A. Heinlein" link_text="Heinlein" possessive %}{%      endcapture %}  
{% capture the_moon_is_a_harsh_mistress %}{% book_link "The Moon Is a Harsh Mistress" %}{% endcapture %}
{% capture starship_troopers %}{% book_link "Starship Troopers" %}{% endcapture %}

{% capture collins %}{% author_link "Suzanne Collins" %}{% endcapture %}
{% capture collinss %}{% author_link "Suzanne Collins" possessive %}{% endcapture %}
{% capture collins_lastname %}{% author_link "Suzanne Collins" link_text="Collins" %}{% endcapture %}
{% capture collinss_lastname %}{% author_link "Suzanne Collins" link_text="Collins" possessive %}{% endcapture %}
{% capture the_hunger_games %}{% book_link "The Hunger Games" %}{% endcapture %}

{% capture tchaikovsky %}{% author_link "Adrian Tchaikovsky" %}{% endcapture %}
{% capture tchaikovskys %}{% author_link "Adrian Tchaikovsky" possessive %}{% endcapture %}
{% capture tchaikovsky_lastname %}{% author_link "Adrian Tchaikovsky" link_text="Tchaikovsky" %}{% endcapture %}
{% capture tchaikovskys_lastname %}{% author_link "Adrian Tchaikovsky" link_text="Tchaikovsky" possessive %}{% endcapture %}
{% capture the_final_architecture %}{% series_link "The Final Architecture" %}{% endcapture %}
{% capture shards_of_earth %}{% book_link "Shards of Earth" %}{% endcapture %}

{% capture martin %}{% author_link "George R.R. Martin" %}{% endcapture %}
{% capture martins %}{% author_link "George R.R. Martin" possessive %}{% endcapture %}
{% capture martin_lastname %}{% author_link "George R.R. Martin" link_text="Martin" %}{% endcapture %}
{% capture martins_lastname %}{% author_link "George R.R. Martin" link_text="Martin" possessive %}{% endcapture %}
{% capture a_song_of_ice_and_fire %}{% series_link "A Song of Ice and Fire" %}{% endcapture %}

{% capture simmons %}{% author_link "Dan Simmons" %}{% endcapture %}
{% capture simmonss %}{% author_link "Dan Simmons" possessive %}{% endcapture %}
{% capture simmons_lastname %}{% author_link "Dan Simmons" link_text="Simmons" %}{% endcapture %}
{% capture simmonss_lastname %}{% author_link "Dan Simmons" link_text="Simmons" possessive %}{% endcapture %}
{% capture hyperion_cantos %}{% series_link "Hyperion Cantos" %}{% endcapture %}
{% capture hyperion %}{% book_link "Hyperion" %}{% endcapture %}
{% capture endymion %}{% book_link "Endymion" %}{% endcapture %}
{% capture the_rise_of_endymion %}{% book_link "The Rise of Endymion" %}{% endcapture %}

{% capture wolfe %}{% author_link "Gene Wolfe" %}{% endcapture %}  
{% capture wolfes %}{% author_link "Gene Wolfe" possessive %}{% endcapture %}
{% capture wolfe_lastname %}{% author_link "Gene Wolfe" link_text="Wolfe" %}{% endcapture %}  
{% capture wolfes_lastname %}{% author_link "Gene Wolfe" link_text="Wolfe" possessive %}{% endcapture %}  
{% capture botns %}{% series_link "The Book of the New Sun" %}{% endcapture %}

{% capture miller %}{% author_link "Walter M. Miller Jr." %}{% endcapture %}
{% capture millers %}{% author_link "Walter M. Miller Jr." possessive %}{% endcapture %}
{% capture miller_lastname %}{% author_link "Walter M. Miller Jr." link_text="Miller" %}{% endcapture %}
{% capture millers_lastname %}{% author_link "Walter M. Miller Jr." link_text="Miller" possessive %}{% endcapture %}
{% capture a_canticle_for_leibowitz %}{% book_link "A Canticle for Leibowitz" %}{% endcapture %}

{% capture hamilton %}{% author_link "Peter F. Hamilton" %}{% endcapture %}
{% capture hamiltons %}{% author_link "Peter F. Hamilton" possessive %}{% endcapture %}
{% capture hamilton_lastname %}{% author_link "Peter F. Hamilton" link_text="Hamilton" %}{% endcapture %}
{% capture hamiltons_lastname %}{% author_link "Peter F. Hamilton" link_text="Hamilton" possessive %}{% endcapture %}
{% capture the_void_trilogy %}{% series_link "The Void Trilogy" %}{% endcapture %}

{% capture huxley %}{% author_link "Aldous Huxley" %}{% endcapture %}
{% capture huxleys %}{% author_link "Aldous Huxley" possessive %}{% endcapture %}
{% capture huxley_lastname %}{% author_link "Aldous Huxley" link_text="Huxley" %}{% endcapture %}
{% capture huxleys_lastname %}{% author_link "Aldous Huxley" link_text="Huxley" possessive %}{% endcapture %}
{% capture brave_new_world %}{% book_link "Brave New World" %}{% endcapture %}

{% capture tolkien %}{% author_link "J.R.R. Tolkien" %}{% endcapture %}
{% capture tolkiens %}{% author_link "J.R.R. Tolkien" possessive %}{% endcapture %}
{% capture tolkien_lastname %}{% author_link "J.R.R. Tolkien" link_text="Tolkien" %}{% endcapture %}
{% capture tolkiens_lastname %}{% author_link "J.R.R. Tolkien" link_text="Tolkien" possessive %}{% endcapture %}
{% capture the_lord_of_the_rings %}{% book_link "The Lord of the Rings" %}{% endcapture %}

{% capture banks %}{% author_link "Iain M. Banks" %}{% endcapture %}
{% capture bankss %}{% author_link "Iain M. Banks" possessive %}{% endcapture %}
{% capture banks_lastname %}{% author_link "Iain M. Banks" link_text="Banks" %}{% endcapture %}
{% capture bankss_lastname %}{% author_link "Iain M. Banks" link_text="Banks" possessive %}{% endcapture %}
{% capture culture %}{% series_link "Culture" %}{% endcapture %}
{% capture the_hydrogen_sonata %}{% book_link "The Hydrogen Sonata" %}{% endcapture %}

{% capture rowling %}{% author_link "J.K. Rowling" %}{% endcapture %}
{% capture rowlings %}{% author_link "J.K. Rowling" possessive %}{% endcapture %}
{% capture rowling_lastname %}{% author_link "J.K. Rowling" link_text="Rowling" %}{% endcapture %}
{% capture rowlings_lastname %}{% author_link "J.K. Rowling" link_text="Rowling" possessive %}{% endcapture %}
{% capture harry_potter %}{% series_link "Harry Potter" %}{% endcapture %}

{% capture card %}{% author_link "Orson Scott Card" %}{% endcapture %}
{% capture cards %}{% author_link "Orson Scott Card" possessive %}{% endcapture %}
{% capture card_lastname %}{% author_link "Orson Scott Card" link_text="Card" %}{% endcapture %}
{% capture cards_lastname %}{% author_link "Orson Scott Card" link_text="Card" possessive %}{% endcapture %}
{% capture enders_game %}{% book_link "Ender's Game" %}{% endcapture %}

{% capture williams %}{% author_link "Walter Jon Williams" %}{% endcapture %}
{% capture williamss %}{% author_link "Walter Jon Williams" possessive %}{% endcapture %}
{% capture williams_lastname %}{% author_link "Walter Jon Williams" link_text="Williams" %}{% endcapture %}
{% capture williamss_lastname %}{% author_link "Walter Jon Williams" link_text="Williams" possessive %}{% endcapture %}
{% capture metropolitan %}{% series_link "Metropolitan" %}{% endcapture %}
{% capture city_on_fire %}{% book_link "City on Fire" %}{% endcapture %}

{% capture warren %}{% author_link "Scott Warren" %}{% endcapture %}
{% capture warrens %}{% author_link "Scott Warren" possessive %}{% endcapture %}
{% capture warren_lastname %}{% author_link "Scott Warren" link_text="Warren" %}{% endcapture %}
{% capture warrens_lastname %}{% author_link "Scott Warren" link_text="Warren" possessive %}{% endcapture %}
{% capture war_horses %}{% series_link "War Horses" %}{% endcapture %}
{% capture serpent_valley %}{% book_link "Serpent Valley" %}{% endcapture %}
{% capture grand_melee %}{% book_link "Grand Melee" %}{% endcapture %}

{% capture homer %}{% author_link "Homer" %}{% endcapture %}
{% capture homers %}{% author_link "Homer" possessive %}{% endcapture %}
{% capture the_iliad %}{% book_link "The Iliad" %}{% endcapture %}
{% capture the_odyssey %}{% book_link "The Odyssey" %}{% endcapture %}

{% capture gattaca %}{% movie_title "Gattaca" %}{% endcapture %}

I did not expect to like {{ red_rising }}, which my book club pitched as "{{
the_hunger_games }} on Mars". And did it have good writing? No. But did it
have interesting

{{ this_book }} is a pastiche of a lot of popular books that came before it.
Most directly, it's {{ collinss_lastname }} {{ the_hunger_games }} but on
Mars. The reds compete to mine the most to win additional rations, and the
children of the Golds are throwing into a violent game to win patronage.

It even brings in game mechanics such as leveling-up to win Primus straight
out of LitRPGs that were just taking off in 2013.

Darrow is a classic Christ figure, like Sevarian in {{
