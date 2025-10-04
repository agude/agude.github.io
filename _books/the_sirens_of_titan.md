---
date: 2025-10-02
title: The Sirens of Titan
book_authors: Kurt Vonnegut
series: null
book_number: 1
rating: 3
image: /books/covers/the_sirens_of_titan.jpg
---

<cite class="book-title">{{ page.title }}</cite>, by <span
class="author-name">{{ page.book_authors }}</span> is in progress!

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

{% capture vonneguts %}{% author_link "Kurt Vonnegut" possessive %}{% endcapture %}
{% capture harrison_bergeron %}{% short_story_link "Harrison Bergeron" %}{% endcapture %}

{% capture simmons %}{% author_link "Dan Simmons" possessive %}{% endcapture %}
{% capture hyperion %}{% book_link "Hyperion" %}{% endcapture %}

{% capture herberts %}{% author_link "Frank Herbert" possessive %}{% endcapture %}
{% capture dune %}{% book_link "Dune" %}{% endcapture %}

{% capture heinleins %}{% author_link "Robert A. Heinlein" possessive %}{% endcapture %}
{% capture stranger_in_a_strange_land %}{% book_link "Stranger in a Strange Land" %}{% endcapture %}

{% capture brunners %}{% author_link "John Brunner" possessive %}{% endcapture %}
{% capture stand_on_zanzibar %}{% book_link "Stand on Zanzibar" %}{% endcapture %}

{% capture moores %}{% author_link "Alan Moore" possessive %}{% endcapture %}
{% capture watchmen %}{% book_link "Watchmen" %}{% endcapture %}

{% capture wattss %}{% author_link "Peter Watts" possessive %}{% endcapture %}
{% capture echopraxia %}{% book_link "Echopraxia" %}{% endcapture %}

{% capture banks %}{% author_link "Iain M. Banks" %}{% endcapture %}
{% capture bankss %}{% author_link "Iain M. Banks" possessive %}{% endcapture %}
{% capture consider_phlebas %}{% book_link "Consider Phlebas" %}{% endcapture %}
{% capture look_to_windward %}{% book_link "Look to Windward" %}{% endcapture %}
{% capture hydrogen %}{% book_link "The Hydrogen Sonata" %}{% endcapture %}

{% capture fitzgeralds %}{% author_link "F. Scott Fitzgerald" possessive %}{% endcapture %}
{% capture great_gatsby %}{% book_link "The Great Gatsby" %}{% endcapture %}

{% capture carrolls %}{% author_link "Lewis Carroll" possessive %}{% endcapture %}
{% capture alices_adventures %}{% book_link "Alice's Adventures in Wonderland" %}{% endcapture %}

{% capture faulkners %}{% author_link "William Faulkner" possessive %}{% endcapture %}
{% capture absalom_absalom %}{% book_link "Absalom, Absalom!" %}{% endcapture %}
{% capture sound_and_the_fury %}{% book_link "The Sound and the Fury" %}{% endcapture %}

{% capture hugos %}{% author_link "Victor Hugo" possessive %}{% endcapture %}
{% capture les_miserables %}{% book_link "Les Misérables" %}{% endcapture %}

{% capture memento %}<cite class="movie-title">Memento</cite>{% endcapture %}
{% capture disco_elysium %}{% book_link "Disco Elysium" %}{% endcapture %}

{% capture adamss %}{% author_link "Douglas Adams" possessive %}{% endcapture %}
{% capture hitchhikers_guide %}{% book_link "The Hitchhiker's Guide to the Galaxy" %}{% endcapture %}
{% capture hitchhikers_guide_short %}{% book_link "The Hitchhiker's Guide to the Galaxy" link_text="Hitchhiker's Guide" %}{% endcapture %}

{{ this_book }} is a shaggy dog story about Malachi Constant, who stumbles
through absurd adventures as he bounces back and forth from Earth to Mars to
Venus, back to Earth, and finally to Titan. It asks big questions about what it
means to have freewill, what is the purpose of life, and the role of religion.
But I didn't particularly enjoy it.

After 319 pages, we learn that humanity, our entire history, is a just
gigantic, Rube Goldberg--style process designed to deliver a small replacement
part for a space ship stranded on Titan. There is no deeper meaning to life,
there is only the meaning you make and the love you share with others. I agree
with that message! But I didn't like the framing story around it, and I didn't
like the characters. Reading it felt like I was just slogging through to get
to the end.

The theme is the same one that {{ banks }} explores over and over, first in {{
consider_phlebas }}, then {{ look_to_windward }}, and finally {{ hydrogen }}.
The difference is that I (mostly) enjoyed the characters and the meaningless
story they were going through in those books. Here, I never did.

I think {{ the_authors_lastname_possessive }} writing is just too
straightforward for my tastes. I have a weakness for books that are a bit of a
puzzle. I love {{ echopraxia }}, where the narrator has no idea what's going
on; {{ absalom_absalom }}, with its page-long sentences and a story that
repeats and reshapes itself each time you hear it; {{ sound_and_the_fury }},
with its nonlinear chapters told by Benji. I had a lot of fun in {{ hyperion
}}, chasing down different echoes of the key themes and motifs. By contrast,
{{ the_authors_lastname }} lays out the whole story and his thesis right from
the start, and then makes you read through it.

{{ this_book }} clearly influenced {{ adamss }} {{ hitchhikers_guide
}}. Marvin the depressed android is very similar to the depressed robot Salo.
Both books follow a character bumbling unwillingly through absurd adventures
that turns out to be pointless. {{ this_book }} has all of humanity created to
help deliver a pointless message while {{ hitchhikers_guide_short }} has the
pointless computation of the meaning of life. The difference is I found {{
hitchhikers_guide_short }} to be **hilarious**, and I didn't laugh once at {{
this_book }}.
