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
class="author-name">{{ page.book_authors }}</span>, is in progress!

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

{% capture sst %}{% book_link "Starship Troopers" %}{% endcapture %}
{% capture stranger %}{% book_link "Stranger in a Strange Land" %}{% endcapture %}

{% capture clarke %}{% author_link "Arthur C. Clarke" %}{% endcapture %}
{% capture clarke_lastname_possessive %}{% author_link "Arthur C. Clarke" link_text="Clarke" possessive %}{% endcapture %}
{% capture odyessy %}{% book_link "2001: A Space Odyssey" %}{% endcapture %}

{% capture tolkien %}{% author_link "J. R. R. Tolkien" %}{% endcapture %}
{% capture tolkein_lastname_possessive %}{% author_link "J. R. R. Tolkien" link_text="Tolkien" possessive %}{% endcapture %}
{% capture lotr1 %}{% book_link "The Fellowship of the Rings" %}{% endcapture %}
{% capture lotr %}{% series_link "The Lord of the Rings" %}{% endcapture %}

{% capture wells %}{% author_link "Marth Wells" %}{% endcapture %}
{% capture wells_lastname_possessive %}{% author_link "Marth Wells" link_text="Wells" possessive %}{% endcapture %}
{% capture mb1 %}{% book_link "All Systems Red" %}{% endcapture %}
{% capture mb4 %}{% book_link "Exit Strategy" %}{% endcapture %}

{% capture smiths_lastname_possessive %}{% author_link "L. Neil Smith" link_text="Smith" possessive %}{% endcapture %}
{% capture probability_broach %}{% book_link "The Probability Broach" %}{% endcapture %}

{% capture rand_lastname_possessive %}{% author_link "Ayn Rand" link_text="Rand" possessive %}{% endcapture %}
{% capture atlas %}{% book_link "Atlas Shrugged" %}{% endcapture %}
{% capture fountainhead %}{% book_link "The Fountainhead" %}{% endcapture %}

{% capture doyle_lastname_possessive %}{% author_link "Arthur Conan Doyle" link_text="Doyle" possessive %}{% endcapture %}
{% capture memoirs %}{% book_link "The Memoirs of Sherlock Holmes" %}{% endcapture %}
{% capture greek %}{% short_story_link "The Adventure of the Greek Interpreter" %}{% endcapture %}

{% capture brunner_lastname_possessive %}{% author_link "John Brunner" link_text="Brunner" possessive %}{% endcapture %}
{% capture zanzibar %}{% book_link "Stand on Zanzibar" %}{% endcapture %}

{% capture firefly %}<cite class="tv-show-title">Firefly</cite>{% endcapture %}

{% capture the_population_bomb %}{% book_link "The Population Bomb" %}{% endcapture %}
{% capture paul_ehrlich %}{% author_link "Paul R. Ehrlich" link_text="Paul"%}{% endcapture %}
{% capture anne_ehrlichs %}{% author_link "Anne Howland Ehrlich" link_text="Anne Ehrlich" possessive %}{% endcapture %}
{% capture paul_and_anne %}{{ paul_ehrlich }} and {{ anne_ehrlichs }}{% endcapture %}

{% capture williams_lastname_possessive %}{% author_link "Walter Jon Williams" link_text="Williams" possessive %}{% endcapture %}
{% capture metropolitan %}{% book_link "Metropolitan" %}{% endcapture %}
{% capture fire %}{% book_link "City on Fire" %}{% endcapture %}

{% capture keatss %}{% author_link "John Keats" possessive %}{% endcapture %}
{% capture keats_lastname %}{% author_link "John Keats" link_text="Keats" %}{% endcapture %}
{% capture keats_lastname_possessive %}{% author_link "John Keats" link_text="Keats" possessive %}{% endcapture %}
{% capture hyperion_keats %}{% book_link "Hyperion" author="John Keats" %}{% endcapture %}

{% capture simmons_lastname_possessive %}{% author_link "Dan Simmons" link_text="Simmons" possessive %}{% endcapture %}
{% capture hyperion_simmons %}{% book_link "Hyperion" author="Dan Simmons" %}{% endcapture %}

I first read {{ this_book }} about 20 years ago and I loved it. A bunch of
plucky rebels, having been abused by Earth too long and with their backs
against the wall, decide to declare their independence and start throwing
rocks down the gravity well until they get their way. And they have a sentient
computer backing them up! It wasn't my first time reading {{
the_authors_lastname }}, that would be {{ sst }} and {{ stranger }}, but it
was my favorite. I even went out an bought a hardcover copy to display on my
shelf after returning the paperback to the library. The only other books where
I did that were {{ clarke_lastname_possessive }} {{ odyessy }} and {{
tolkein_lastname_possessive }} {{ lotr1 }}. I didn't like it as much this read
through.

The story is still engaging, but the long digressions about libertarianism are
much more annoying now. Maybe I was more libertarian curious in my younger age,
or perhaps twenty more years of experience has helped me understand how
selfish the ideology is, or perhaps the ascension of a greedy fascism in the
modern political environment has soured me on the whole idea. Whatever it is,
I now much prefer books that champion community over individualism like {{
wells_lastname_possessive }} {{ mb1 }} and {{ mb4 }} to libertarian apologia
in the vain of {{ smiths_lastname_possessive }} {{ probability_broach }} or {{
rand_lastname_possessive }} {{ fountainhead }} and {{ atlas }}.[^orcs]

[^orcs]: It's clear from the above paragraphs which side of [John
    Rogers's][orcs] line I fall:

    > There are two novels that can change a bookish fourteen-year old's life:
    > {{ lotr }} and {{ atlas }}. One is a childish fantasy that often
    > engenders a lifelong obsession with its unbelievable heroes, leading to
    > an emotionally stunted, socially crippled adulthood, unable to deal with
    > the real world. The other, of course, involves orcs.

[orcs]: https://kfmonkey.blogspot.com/2009/03/ephemera-2009-7.html

For all its lectures, {{ this_book }} actually does show some of
libertarianism warts: lynch mobs, lack of forced vaccinations killing
thousands, the hypocrisy of the self-reliant relying on stealing from
each other, taxes are theft but theft is fine.

The best character is Mycroft "Mike" HOLMES IV,[^holmes] the sentient computer
named after Sherlock's brother from {{ doyle_lastname_possessive }} {{ greek
}}. In some ways he's a standard sci-fi AI: logical, good with numbers, can
compute probabilities from limited information. But he shows hints of behavior
like a modern generative AI system: he writes jokes and wants to understand
humor, he generates real-time video of his "Adam Selene" identity. His
sentience wasn't designed, it emerged when he got complex enough. Mike is also
the ultimate free lunch, able to plan and oversee the revolution and paid only
in companionship and jokes.

[^holmes]: Highly Optional, Logical, Multi-Evaluating Supervisor, Mark IV

The pidgin Manny speaks mostly reads like the mixed English--Chinese from {{
firefly }}, but occasionally the slang sounds off, almost a "codder-shiggy"
problem as in {{ zanzibar }}. Also similar to {{ zanzibar }}, {{ this_book
}} also deals with over population and environmental collapse, themes that
resonated in the late 60s, exemplified by {{ paul_and_anne }} {{
the_population_bomb }}. {{ this_book }} deals with a revolution like {{
williams_lastname_possessive }} {{ metropolitan }}, but doesn't really dig
into aftermath like {{ fire }}. There is a brief reference to the professor
reading {{ keats_lastname }}, no doubt {{ hyperion_keats }} whose theme of the
new order overthrowing the old fits perfectly in this story, just as it did in
{{ simmons_lastname_possessive }} {{ hyperion_simmons }}.
