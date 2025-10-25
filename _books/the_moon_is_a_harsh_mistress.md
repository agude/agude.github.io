---
date: 2025-10-24
title: The Moon is a Harsh Mistress
book_authors: Robert A. Heinlein
series: null
book_number: 1
is_anthology: false
rating: 3
image: /books/covers/the_moon_is_a_harsh_mistress.jpg
awards:
  - hugo
  - prometheas hall of fame
---

<cite class="book-title">{{ page.title }}</cite>, by <span
class="author-name">{{ page.book_authors }}</span>, is a Hugo Award-winning
classic of libertarian science fiction. It chronicles the revolt of a lunar
penal colony against its terrestrial rulers, a revolution orchestrated by a
small group of rebels and their self-aware computer.

{% capture this_book %}<cite class="book-title">{{ page.title }}</cite>{% endcapture %}
{% capture the_authors_lastname %}<span class="author-name">{{ page.book_authors | split: " " | last }}</span>{% endcapture %}

{% capture sst %}{% book_link "Starship Troopers" %}{% endcapture %}
{% capture stranger %}{% book_link "Stranger in a Strange Land" %}{% endcapture %}

{% capture clarke_lastname_possessive %}{% author_link "Arthur C. Clarke" link_text="Clarke" possessive %}{% endcapture %}
{% capture odyessy %}{% book_link "2001: A Space Odyssey" %}{% endcapture %}

{% capture watchmen %}{% book_link "Watchmen" %}{% endcapture %}
{% capture moore_and_gibbons_possessive %}{% author_link "Alan Moore" link_text="Moore" %} and {% author_link "Dave Gibbons" link_text="Gibbons" possessive %}{% endcapture %}

{% capture tolkein_lastname_possessive %}{% author_link "J. R. R. Tolkien" link_text="Tolkien" possessive %}{% endcapture %}
{% capture lotr %}{% series_link "The Lord of the Rings" %}{% endcapture %}

{% capture wells_lastname_possessive %}{% author_link "Marth Wells" link_text="Wells" possessive %}{% endcapture %}
{% capture mb1 %}{% book_link "All Systems Red" %}{% endcapture %}
{% capture mb4 %}{% book_link "Exit Strategy" %}{% endcapture %}

{% capture smiths_lastname_possessive %}{% author_link "L. Neil Smith" link_text="Smith" possessive %}{% endcapture %}
{% capture probability_broach %}{% book_link "The Probability Broach" %}{% endcapture %}

{% capture rand_lastname_possessive %}{% author_link "Ayn Rand" link_text="Rand" possessive %}{% endcapture %}
{% capture atlas %}{% book_link "Atlas Shrugged" %}{% endcapture %}
{% capture fountainhead %}{% book_link "The Fountainhead" %}{% endcapture %}

{% capture doyle_lastname_possessive %}{% author_link "Arthur Conan Doyle" link_text="Doyle" possessive %}{% endcapture %}
{% capture greek %}{% short_story_link "The Adventure of the Greek Interpreter" %}{% endcapture %}

{% capture zanzibar %}{% book_link "Stand on Zanzibar" %}{% endcapture %}

{% capture firefly %}<cite class="tv-show-title">Firefly</cite>{% endcapture %}

{% capture the_population_bomb %}{% book_link "The Population Bomb" %}{% endcapture %}
{% capture paul_ehrlich %}{% author_link "Paul R. Ehrlich" link_text="Paul"%}{% endcapture %}
{% capture anne_ehrlichs %}{% author_link "Anne Howland Ehrlich" link_text="Anne Ehrlich" possessive %}{% endcapture %}
{% capture paul_and_anne %}{{ paul_ehrlich }} and {{ anne_ehrlichs }}{% endcapture %}

{% capture williams_lastname_possessive %}{% author_link "Walter Jon Williams" link_text="Williams" possessive %}{% endcapture %}
{% capture metropolitan %}{% book_link "Metropolitan" %}{% endcapture %}
{% capture fire %}{% book_link "City on Fire" %}{% endcapture %}

{% capture keats_lastname %}{% author_link "John Keats" link_text="Keats" %}{% endcapture %}
{% capture hyperion_keats %}{% book_link "Hyperion" author="John Keats" %}{% endcapture %}

{% capture simmons_lastname_possessive %}{% author_link "Dan Simmons" link_text="Simmons" possessive %}{% endcapture %}
{% capture hyperion_simmons %}{% book_link "Hyperion" author="Dan Simmons" %}{% endcapture %}
{% capture fall_of_hyperion %}{% book_link "The Fall of Hyperion" %}{% endcapture %}
{% capture hyperion_cantos %}{% series_link "Hyperion Cantos" %}{% endcapture %}

{% capture old_guard %}{% book_link "Old Guard" %}{% endcapture %}
{% capture bolos_series %}{% series_link "Bolo" %} series{% endcapture %}

{% capture basilisk %}{% book_link "On Basilisk Station" %}{% endcapture %}

{% capture world_breakers %}{% book_link "World Breakers" %}{% endcapture %}
{% capture time_war %}{% book_link "This Is How You Lose the Time War" %}{% endcapture %}
{% capture snowcrash %}{% book_link "Snow Crash" %}{% endcapture %}

I first read {{ this_book }} about 20 years ago and I loved it. A bunch of
plucky rebels, having been pushed around by Earth too long and with their
backs against the wall, decide to declare independence and start dropping
rocks down the gravity well until they get their way. And they have a sentient
computer backing them up! It wasn't my first time reading {{
the_authors_lastname }}, that was {{ sst }} and {{ stranger }}, but it became
my favorite. I even went out and bought a hardcover copy to display on my
shelf after finishing the paperback. The only other books I've done that for
were {{ clarke_lastname_possessive }} {{ odyessy }}, {{
tolkein_lastname_possessive }} {{ lotr }}, and {{ moore_and_gibbons_possessive
}} {{ watchmen }}. I didn't like {{ this_book }} as much this read-through.

The story is still engaging, but the long libertarian digressions are much
harder to tolerate now. Maybe I was more libertarian-curious in my younger
days, or maybe twenty more years of experience has made it clearer how selfish
the ideology is. Or maybe the rise of greedy fascism in the modern political
climate has soured me on the whole idea. Whatever the reason, I now prefer
stories that celebrate community over individualism, like {{
wells_lastname_possessive }} {{ mb1 }} and {{ mb4 }}, to libertarian apologia
in the vein of {{ smiths_lastname_possessive }} {{ probability_broach }} or {{
rand_lastname_possessive }} {{ fountainhead }} and {{ atlas }}.[^orcs]

[^orcs]: It's clear from the above paragraphs which side of [John
    Rogers's][orcs] line I fall on:

    > There are two novels that can change a bookish fourteen-year old's life:
    > {{ lotr }} and {{ atlas }}. One is a childish fantasy that often
    > engenders a lifelong obsession with its unbelievable heroes, leading to
    > an emotionally stunted, socially crippled adulthood, unable to deal with
    > the real world. The other, of course, involves orcs.

[orcs]: https://kfmonkey.blogspot.com/2009/03/ephemera-2009-7.html

For all its lecturing, {{ this_book }} does show some of libertarianism's
warts: lynch mobs, lack of vaccinations killing thousands, the hypocrisy of
the "self-reliant" relying on theft from each other. Taxes are theft, but
theft is fine, apparently.

The best character is Mycroft "Mike" HOLMES IV,[^holmes] the sentient computer
named after Sherlock's brother from {{ doyle_lastname_possessive }} {{ greek
}}. In some ways he's a standard sci-fi AI: logical, good with numbers, able
to compute probabilities from limited information. But he also behaves like
today's generative AIs: he writes jokes and poems, tries to understand humor,
and generates real-time video of his "Adam Selene" persona. His sentience
wasn't designed; it just emerged once the system grew complex enough. Mike is
also the ultimate free lunch, able to oversee the revolution and paid only in
companionship and jokes.

[^holmes]: Highly Optional, Logical, Multi-Evaluating Supervisor, Mark IV

The pidgin Mannie speaks mostly reads like the mixed English--Chinese from {{
firefly }}, but occasionally the slang sounds off, almost a "codder-shiggy"
problem as in {{ zanzibar }}. Also like {{ zanzibar }}, {{ this_book }} deals
with overpopulation and environmental collapse, themes that resonated in the
late '60s and were exemplified in {{ paul_and_anne }} {{ the_population_bomb
}}. {{ this_book }} tells a revolution story much like {{
williams_lastname_possessive }} {{ metropolitan }}, but unlike {{ fire }}, it
doesn't really explore the aftermath. There's a quick reference to the
professor reading {{ keats_lastname }}, almost certainly {{ hyperion_keats }}.
Its theme of a new order overthrowing the old fits perfectly here, just as it
did in {{ simmons_lastname_possessive }} {{ hyperion_simmons }}.

{{ this_book }} wasn't as great as I remembered, which makes me both excited
and a little nervous to revisit {{ sst }}---which I loved---and {{ stranger
}}---which I hated. I still plan to get back to the {{ hyperion_cantos }} with
{{ fall_of_hyperion }}, and the {{ bolos_series }} with {{ old_guard }}, but
for now I'm keeping my break from those going with {{ basilisk }}, maybe {{
world_breakers }} and {{ snowcrash }}. And of course, I've got to fit in our
next book club pick, {{ time_war }}, too. Hopefully I'll get plenty of time to
read over the holidays.
