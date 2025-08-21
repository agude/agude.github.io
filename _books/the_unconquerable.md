---
date: 2025-08-11
title: The Unconquerable
book_authors:
  - S. M. Stirling
  - S. N. Lewitt
  - Shirley Meier
  - Christopher Stasheff
  - Karen Wehrstein
  - Todd Johnson
  - William R. Forstchen
series: Bolo
book_number: 11
is_anthology: true
rating: 4
image: /books/covers/bolos_book_2_the_unconquerable_1st_edition.jpg
---

<cite class="book-title">{{ page.title }}</cite> is the eleventh book in the
<span class="book-series">{{ page.series }}</span> series. It's an anthology
of Bolo stories written by seven different authors.

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

{% capture author_stirling %}{% author_link "S. M. Stirling" %}{% endcapture %}
{% capture author_lewitt %}{% author_link "S. N. Lewitt" %}{% endcapture %}
{% capture author_meier %}{% author_link "Shirley Meier" %}{% endcapture %}
{% capture author_stasheff %}{% author_link "Christopher Stasheff" %}{% endcapture %}
{% capture author_wehrstein %}{% author_link "Karen Wehrstein" %}{% endcapture %}
{% capture author_johnson %}{% author_link "Todd Johnson" %}{% endcapture %}
{% capture author_forstchen %}{% author_link "William R. Forstchen" %}{% endcapture %}

{% comment %}From anthologies 1{% endcomment %}
{% capture lost_legion %}{% short_story_link "Lost Legion" %}{% endcapture %}
{% capture camelot %}{% short_story_link "Camelot" %}{% endcapture %}
{% capture the_legacy_of_leonidas %}{% short_story_link "The Legacy of Leonidas" %}{% endcapture %}
{% capture ploughshare %}{% short_story_link "Ploughshare" %}{% endcapture %}
{% capture ghosts %}{% short_story_link "Ghosts" %}{% endcapture %}
{% capture the_ghost_of_resartus %}{% short_story_link "The Ghost of Resartus" %}{% endcapture %}
{% capture operation_desert_fox %}{% short_story_link "Operation Desert Fox" %}{% endcapture %}
{% capture as_our_strength_lessens %}{% short_story_link "As Our Strength Lessens" %}{% endcapture %}

{% comment %}From anthologies 2{% endcomment %}
{% capture ancestral_voices %}{% short_story_link "Ancestral Voices" %}{% endcapture %}
{% capture sir_kendricks_lady %}{% short_story_link "Sir Kendrick's Lady" %}{% endcapture %}
{% capture youre_it %}{% short_story_link "You're It" %}{% endcapture %}
{% capture shared_experience %}{% short_story_link "Shared Experience" %}{% endcapture %}
{% capture the_murphosensor_bomb %}{% short_story_link "The Murphosensor Bomb" %}{% endcapture %}
{% capture legacy %}{% short_story_link "Legacy" %}{% endcapture %}
{% capture endings %}{% short_story_link "Endings" %}{% endcapture %}

{% capture bolo1 %}{% book_link "Bolo: Annals of the Dinochrome Brigade" %}{% endcapture %}
{% capture bolo2 %}{% book_link "Rogue Bolo" %}{% endcapture %}
{% capture bolo3 %}{% book_link "The Stars Must Wait" %}{% endcapture %}
{% capture bolo4 %}{% book_link "Bolo Brigade" %}{% endcapture %}
{% capture bolo5 %}{% book_link "Bolo Rising" %}{% endcapture %}
{% capture bolo6 %}{% book_link "Bolo Strike" %}{% endcapture %}
{% capture bolo7 %}{% book_link "The Road to Damascus" %}{% endcapture %}
{% capture bolo8 %}{% book_link "Bolo!" %}{% endcapture %}
{% capture bolo9 %}{% book_link "Old Soldiers" %}{% endcapture %}
{% capture bolo10 %}{% book_link "Honor of the Regiment" %}{% endcapture %}
{% capture bolo11 %}{% book_link "The Unconquerable" %}{% endcapture %}
{% capture bolo12 %}{% book_link "The Triumphant" %}{% endcapture %}
{% capture bolo13 %}{% book_link "Last Stand" %}{% endcapture %}
{% capture bolo14 %}{% book_link "Old Guard" %}{% endcapture %}
{% capture bolo15 %}{% book_link "Cold Steel" %}{% endcapture %}

{% capture conrads %}{% author_link "Joseph Conrad" possessive %}{% endcapture %}
{% capture heart %}{% book_link "Heart of Darkness" %}{% endcapture %}

{% capture predator %}<cite class="movie-title">Predator</cite>{% endcapture %}
{% capture empire %}<cite class="movie-title">The Empire Strikes Back</cite>{% endcapture %}

{% capture asimovs %}{% author_link "Isaac Asimov" possessive %}{% endcapture %}
{% capture heart %}{% short_story_link "Liar!" %}{% endcapture %}

### {% short_story_title "Ancestral Voices" %}
<div class="written-by">by {{ author_stirling }}</div>
{% rating_stars 4 %}

A sequel to {{ lost_legion }} from {{ bolo10 }}, the U.S. Army unit is still
trying to make it home. This time they run into a volcanologist who can
control the local volcano with his scientific instruments. He uses this power
to convince the locals that he is the sixth coming of Montezuma, and that the
gods wants them to reinstate the Aztec Empire, complete with human sacrifices.

This story is mostly just an action packed romp, but there is a little nuance
with the "good" soldiers being forced to steal and extort local villages to
survive, and the "bad" Aztecs living in an prosperous valley, safe from the
chaos of the collapsing world.

This story very vaguely reminds me of {{ conrads }} {{ heart }}, with the
outside who convinces a native tribe that he is a demigod.

### {% short_story_title "Sir Kendrick's Lady" %}
<div class="written-by">by {{ author_lewitt }}</div>
{% rating_stars 4 %}

A sequel to {{ camelot }}, this story follows Abigail, a teenaged girl growing
up on Camelot. Like all young people there, she's bored and dreams of running
away. It feels like it's going to be a standard "you don't appreciate what you
have" story, but there are two twists:

1. It turns out all the children running away are actually being traffic into
   slavery by the spacers guild.
2. The Bolo is almost completely unable to help.

It's a fresh take on a standard story, and an interesting look into the types
of horrible problems that you can't solve with a well aimed Hellbore blast.

### {% short_story_title "You're It" %}
<div class="written-by">by {{ author_meier }}</div>
{% rating_stars 5 %}

A vaguely East-Asian human Empire has attacked the Concordinate and wiped out
the planet's defenders except for one, damaged Bolo. A lone technician is
trying to make it to the Bolo without getting caught and killed by the
empire's knock-off tanks. Although the title is based on tag, it's much more
hide and seek, with the technician camouflaging his heat signature using mud
like Arnold in {{ predator }}, and later hiding in a giant snail carcass, a
little like Luke in {{ empire }}.

Like {{ sir_kendricks_lady }}, there is some darkness in the pulpy action:
children suicide bombers and slave labor.

{{ author_meier }} tries to make the imperial general sympathetic by giving
him some scenes where... TODO

It feels a little like rehabilitation of Rommel from {{ operation_desert_fox
}} in that it portrays the imperial general as a "good" guy working in a "bad"
system; he even has a [Luger][luger].

[luger]: https://en.wikipedia.org/wiki/Luger_pistol

{{ youre_it }} is just a really well written story, with the right blend of
suspense, action, and the bad guys meeting fitting ends. I think this is also
the first story with a Bolo named after a woman, although {{ lost_legion }}
and {{ ancestral_voices }} has a Bolo with a woman's voice.

### {% short_story_title "Shared Experience" %}
<div class="written-by">by {{ author_stasheff }}</div>
{% rating_stars 1 %}

A Bolo experiences the deaths of his comrades as they fight off Harpies and
egg-shaped ships. Meanwhile, two humans flirt as they try to survive.

{{ author_stasheff }} writes in the narrative style without any dialogue for
the first half of the book: "The Bolo did this. The Harpies did that." It's
boring. And it's too long. Bolos work best as characters, as we learned in
from {{ bolo1 }}, and Titan and his fellow Bolos are scenery for most of this
story.

One fun fact: this is the first story where it explains that people enter a
Bolo from the under-side between the treads; in all the previous stories
people have had to climb up the Bolo.

### {% short_story_title "The Murphosensor Bomb" %}
<div class="written-by">by {{ author_wehrstein }}</div>
{% rating_stars 5 %}

### {% short_story_title "Legacy" %}
<div class="written-by">by {{ author_johnson }}</div>
{% rating_stars 4 %}

Set in the distant future, humanity has evolved beyond war and violence, and
so the Hryxi are hunting them down planet by planet with no resistance. The
last remaining humans take shelter in a cave on Earth, only to discover a
mothballed Bolo. Not a lot happens, and we don't get a resolution, still the
story is hopeful: as long as one Bolo exists, humanity has a chance, no matter
the odds. We also get a glimpse at the new technology, like thought controlled
nanobots, that is exciting.

### {% short_story_title "Endings" %}
<div class="written-by">by {{ author_forstchen }}</div>
{% rating_stars 5 %}
