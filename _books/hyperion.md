---
date: 2025-09-20
title: Hyperion
book_authors: Dan Simmons
series: Hyperion Cantos
book_number: 1
is_anthology: true
rating: 5
image: /books/covers/hyperion.jpg
awards:
  - hugo
  - locus
---

<cite class="book-title">{{ page.title }}</cite> is <span
class="author-name">{{ page.book_authors }}</span>'s masterpiece. It is the
first book in his <span class="book-series">{{ page.series }}</span>. It
follows seven pilgrims as they travel to the time tombs on Hyperion to
petition the god-like Shrike.

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

{% comment %} Foundational Works for the Review {% endcomment %}

{% capture fall_hyperion %}{% book_link "The Fall of Hyperion" %}{% endcapture %}

{% capture keats %}{% author_link "John Keats" %}{% endcapture %}
{% capture keatss %}{% author_link "John Keats" possessive %}{% endcapture %}
{% capture keats_lastname %}{% author_link "John Keats" link_text="Keats" %}{% endcapture %}
{% capture keats_lastname_possessive %}{% author_link "John Keats" link_text="Keats" possessive %}{% endcapture %}
{% capture hyperion_keats %}{% book_link "Hyperion" author="John Keats" %}{% endcapture %}

{% capture chaucer %}{% author_link "Geoffrey Chaucer" %}{% endcapture %}
{% capture chaucers %}{% author_link "Geoffrey Chaucer" possessive %}{% endcapture %}
{% capture canterbury %}{% book_link "The Canterbury Tales" %}{% endcapture %}

{% comment %} Iain M. Banks (The Culture etc.) {% endcomment %}

{% capture banks %}{% author_link "Iain M. Banks" %}{% endcapture %}
{% capture bankss %}{% author_link "Iain M. Banks" possessive %}{% endcapture %}
{% capture player_of_games %}{% book_link "The Player of Games" %}{% endcapture %}
{% capture look_to_windward %}{% book_link "Look to Windward" %}{% endcapture %}
{% capture consider_phlebas %}{% book_link "Consider Phlebas" %}{% endcapture %}
{% capture surface_detail %}{% book_link "Surface Detail" %}{% endcapture %}
{% capture hydrogen_sonata %}{% book_link "The Hydrogen Sonata" %}{% endcapture %}

{% comment %} Other Science Fiction Authors & Works {% endcomment %}

{% capture clarke %}{% author_link "Arthur C. Clarke" %}{% endcapture %}
{% capture clarkes %}{% author_link "Arthur C. Clarke" possessive %}{% endcapture %}

{% capture conrad %}{% author_link "Joseph Conrad" %}{% endcapture %}
{% capture conrads %}{% author_link "Joseph Conrad" possessive %}{% endcapture %}
{% capture heart_of_darkness %}{% book_link "Heart of Darkness" %}{% endcapture %}

{% capture haldeman %}{% author_link "Joe Haldeman" %}{% endcapture %}
{% capture haldemans %}{% author_link "Joe Haldeman" possessive %}{% endcapture %}
{% capture forever_war %}{% book_link "The Forever War" %}{% endcapture %}

{% capture wells %}{% author_link "Martha Wells" %}{% endcapture %}
{% capture wellss %}{% author_link "Martha Wells" possessive %}{% endcapture %}
{% capture murderbot %}{% book_link "The Murderbot Diaries" %}{% endcapture %}

{% capture vance %}{% author_link "Jack Vance" %}{% endcapture %}
{% capture vances %}{% author_link "Jack Vance" possessive %}{% endcapture %}
{% capture dying_earth %}{% book_link "The Dying Earth" %}{% endcapture %}

{% capture hamilton %}{% author_link "Peter F. Hamilton" %}{% endcapture %}
{% capture hamiltons %}{% author_link "Peter F. Hamilton" possessive %}{% endcapture %}
{% capture judas_unchained %}{% book_link "Judas Unchained" %}{% endcapture %}

{% capture brunner %}{% author_link "John Brunner" %}{% endcapture %}
{% capture brunners %}{% author_link "John Brunner" possessive %}{% endcapture %}
{% capture stand_on_zanzibar %}{% book_link "Stand on Zanzibar" %}{% endcapture %}

{% capture card %}{% author_link "Orson Scott Card" %}{% endcapture %}
{% capture cards %}{% author_link "Orson Scott Card" possessive %}{% endcapture %}
{% capture enders_game %}{% book_link "Ender's Game" %}{% endcapture %}

{% capture strugatsky %}{% author_link "Arkady and Boris Strugatsky" %}{% endcapture %}
{% capture strugatskys %}{% author_link "Arkady and Boris Strugatsky" possessive %}{% endcapture %}

{% capture le_guin %}{% author_link "Ursula K. Le Guin" %}{% endcapture %}
{% capture le_guins %}{% author_link "Ursula K. Le Guin" possessive %}{% endcapture %}
{% capture left_hand_of_darkness %}{% book_link "The Left Hand of Darkness" %}{% endcapture %}

{% capture keyes %}{% author_link "Daniel Keyes" %}{% endcapture %}
{% capture keyess %}{% author_link "Daniel Keyes" possessive %}{% endcapture %}
{% capture flowers_for_algernon %}{% book_link "Flowers for Algernon" %}{% endcapture %}

{% capture gibson %}{% author_link "William Gibson" %}{% endcapture %}
{% capture gibsons %}{% author_link "William Gibson" possessive %}{% endcapture %}
{% capture johnny_mnemonic %}{% book_link "Johnny Mnemonic" %}{% endcapture %}
{% capture neuromancer %}{% book_link "Neuromancer" %}{% endcapture %}

{% capture orwell %}{% author_link "George Orwell" %}{% endcapture %}
{% capture orwells %}{% author_link "George Orwell" possessive %}{% endcapture %}
{% capture nineteen_eighty_four %}{% book_link "Nineteen Eighty-Four" %}{% endcapture %}

{% capture tchaikovsky %}{% author_link "Adrian Tchaikovsky" %}{% endcapture %}
{% capture tchaikovskys %}{% author_link "Adrian Tchaikovsky" possessive %}{% endcapture %}
{% capture shards_of_earth %}{% book_link "Shards of Earth" %}{% endcapture %}

{% capture adams %}{% author_link "Douglas Adams" %}{% endcapture %}
{% capture adamss %}{% author_link "Douglas Adams" possessive %}{% endcapture %}
{% capture hitchhikers_guide %}{% book_link "The Hitchhiker's Guide to the Galaxy" %}{% endcapture %}

{% capture burroughs %}{% author_link "Edgar Rice Burroughs" %}{% endcapture %}
{% capture burroughss %}{% author_link "Edgar Rice Burroughs" possessive %}{% endcapture %}
{% capture john_carter %}{% book_link "A Princess of Mars" %}{% endcapture %}

{% capture hg_wells %}{% author_link "H. G. Wells" %}{% endcapture %}
{% capture hg_wellss %}{% author_link "H. G. Wells" possessive %}{% endcapture %}
{% capture time_machine %}{% book_link "The Time Machine" %}{% endcapture %}

{% capture chandler %}{% author_link "Raymond Chandler" %}{% endcapture %}
{% capture chandlers %}{% author_link "Raymond Chandler" possessive %}{% endcapture %}

{% comment %} Classic & Literary Authors {% endcomment %}

{% capture bible %}{% book_link "The Bible" %}{% endcapture %}
{% capture genesis %}{% short_story_link "The Book of Genesis" %}{% endcapture %}

{% capture twain %}{% author_link "Mark Twain" %}{% endcapture %}
{% capture twains %}{% author_link "Mark Twain" possessive %}{% endcapture %}
{% capture huckleberry_finn %}{% book_link "Adventures of Huckleberry Finn" %}{% endcapture %}

{% capture doyle %}{% author_link "Arthur Conan Doyle" %}{% endcapture %}
{% capture doyles %}{% author_link "Arthur Conan Doyle" possessive %}{% endcapture %}
{% capture sherlock_holmes %}{% book_link "The Adventures of Sherlock Holmes" %}{% endcapture %}

{% capture shakespeare %}{% author_link "William Shakespeare" %}{% endcapture %}
{% capture shakespeares %}{% author_link "William Shakespeare" possessive %}{% endcapture %}
{% capture romeo_and_juliet %}{% book_link "Romeo and Juliet" %}{% endcapture %}

{% capture beowulf %}{% book_link "Beowulf" %}{% endcapture %}

{% capture kierkegaard %}{% author_link "Søren Kierkegaard" %}{% endcapture %}
{% capture kierkegaards %}{% author_link "Søren Kierkegaard" possessive %}{% endcapture %}
{% capture fear_and_trembling %}{% book_link "Fear and Trembling" %}{% endcapture %}

{% comment %} Games & Movies {% endcomment %}

{% capture disco_elysium %}<cite class="game-title">Disco Elysium</cite>{% endcapture %}

{% capture space_odyssey %}<cite class="movie-title">2001: A Space Odyssey</cite>{% endcapture %}
{% capture terminator %}<cite class="movie-title">The Terminator</cite>{% endcapture %}

I didn't love {{ this_book }} when [I first read it][first_read] about two
years ago. It is a book with deep intertextuality, influenced heavily by {{
keatss }} {{ hyperion_keats }}, but also {{ chaucers }} {{ canterbury }}. {{
author_last_name_text }} uses that classic pilgrimage structure as a frame to
present six different stories, each one a pastiche of a different genre. But I
missed almost all of that the first time, instead distracted by lasers and
barbarians and a god-like Shrike encrusted in blades.

[first_read]: #previous-review

### Themes

The primary theme of {{ keatss }} {{ hyperion_keats }} is the inevitability of
change, particularly in the fall of old order. In his poem, this is
exemplified by the [Titans being overthrown by the Olympians][titanomachy]. {{
the_author }} repeats this theme in his {{ this_book }}, most obviously in the
looming destruction of humanity and their replacement by either the AIs of the
TechnoCore or the Ousters, but also in various other places in each Pilgram's
story.

[titanomachy]: https://en.wikipedia.org/wiki/Titanomachy

{{ keats_lastname }} explores several other themes in his work as well: the
relationship between beauty, truth, and power; the nature of knowledge and
suffering; and the role of the poet. {{ author_last_name_text }} adopts these
themes as well.

### Tales

There are seven pilgrims, but only six live to tell their tales. {{ the_author
}} uses each to explore a different genre, but also to explore the {{
keats_lastname_possessive }} themes in different settings and at different
scales.

#### {% short_story_title "The Priest's Tale" %}

#### {% short_story_title "The Soldier's Tale" %}

#### {% short_story_title "The Poet's Tale" %}

#### {% short_story_title "The Scholar's Tale" %}

#### {% short_story_title "The Detective's Tale" %}

#### {% short_story_title "The Consul's Tale" %}


{% comment %}

==============
The Old Review
==============

Previous rating and date
date: 2023-10-17
rating: 4

{% endcomment %}
<details markdown="1">
  <summary>
    <h2 class="book-review-headline">Previous Review</h2>
  </summary>
{% rating_stars 4 %}

{{ this_book }} was not at all the book I expected. To give you an idea of how
much I misjudged it, about a third of the way through I would have rated it
two stars and almost put it down, about two-thirds of the way through I was
solidly at three stars, and by the end I was up to four. It was not the
all-time great I was promised, but it was very good.

It is told as the tale of six different pilgrims traveling to the planet
Hyperion to visit the Shrike, a cruel, death-god-like figure. {{ this_book }}
is very much {{ canterbury }} in space. At first the stories seem unconnected,
but as the pilgrims travel and tell their tales we realize they are all
connected, and they reveal a hint at the wider universe that the book takes
place in. The book ends "suddenly" but the sequel, {{ fall_hyperion }}, picks
up right where {{ this_book }} leaves off.

[tales]: https://en.wikipedia.org/wiki/The_Canterbury_Tales

A theme that runs through the book is "the old gods replaced by the new",
based on {{ keatss }} {{ hyperion_keats }} poem about the [Greek Titans
falling to the new Gods of Olympus][titanomachy]. We see this with the Humans
and the AI TechnoCore, the humans and the Ousters (a breakaway post-human
faction), the Scholar and the Old Testament God, and Catholicism and the new
religions.

### {% short_story_title "The Priest's Tale" %}
{% rating_stars 2 %}

I think this story is supposed to be carried by the mystery, but it didn't
hook me. Not as much a horror story as I assumed halfway through, it's still a
little too far into the genre for me.

### {% short_story_title "The Soldier's Tale" %}
{% rating_stars 5 %}

A story with action, mystery, and our first really good look at both the
Ousters and the Shrike.

### {% short_story_title "The Poet's Tale" %}
{% rating_stars 3 %}

Starts off slow, but the payoff is good. Silenus, the poet, is a spoiled
annoying character, but the way he comes to believe that he has set the Shrike
loose with his writing is exciting.

### {% short_story_title "The Scholar's Tale" %}
{% rating_stars 5 %}

Emotional, heartbreaking. In the Scholar's Tale we learn why Sol Weintraub
brought a two-week old baby---one getting younger all the time---on the deadly
pilgrimage.

### {% short_story_title "The Detective's Tale" %}
{% rating_stars 5 %}

This story gives us a great look at the TechnoCore: the artificial
intelligences that seceded from humanity but are still tightly involved in our
affairs. The story hints that the TechnoCore's three factions---the stables,
the volatiles, and the ultimates---are engineering the coming war over
Hyperion. The end is a bit too 1980s cyberpunk (dodging code phages in the
neon cyberweb!), but the characters and history are compelling.

### {% short_story_title "The Consul's Tale" %}
{% rating_stars 4 %}

The final tale starts off as a love story between a planet-bound woman and a
space-faring man who, because of relativity, ages much slower. But at the very
end the story twists and it becomes a tale of revolution. It explains why and
how the Consul intentionally set the entire Hyperion crisis in motion.
</details>
