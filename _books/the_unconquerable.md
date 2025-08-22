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

{% capture evans %}{% author_link "Linda Evans" %}{% endcapture %}
{% capture hollingsworth %}{% author_link "Robert R. Hollingsworth" %}{% endcapture %}
{% capture weber %}{% author_link "David Weber" %}{% endcapture %}

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

{% capture laumer %}{% author_link "Keith Laumer" %}{% endcapture %}
{% capture laumers %}{% author_link "Keith Laumer" possessive %}{% endcapture %}
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
{% capture liar %}{% short_story_link "Liar!" %}{% endcapture %}

{% capture wellss %}{% author_link "H. G. Wells" possessive %}{% endcapture %}
{% capture war %}{% short_story_link "The War of the Worlds" %}{% endcapture %}

{{ this_book }} follows {{ bolo10 }} and contains sequels to {{ lost_legion }}
and {{ camelot }}. As the second book in the anthology, the authors and editor
are starting to get more comfortable with the setting. This gives them the
confidence to tell different types of stories, like {{ sir_kendricks_lady }}
where the Bolo can't solve the problem, and {{ endings }} where the Bolo does
little more than talk.

It also gives them the freedom to invent things not seen in {{ laumers }}
earlier works: {{ bolo1 }}, {{ bolo2 }}, and {{ bolo3 }}. We see new enemies
and conflicts, including the first story with the apocalyptic Last War between
the Concordiat and the Melconians that destroys both. We see new Bolos,
including our first glimpse of a Mk. XXXIII, and new ideas about them, like
that some can read emotion.

{{ this_book }} reads like a tighter version of {{ bolo10 }}, with a bit more
experimentation. The next volume, {{ bolo12 }}, changes the formula further by
using just a few authors---{{ evans }}, {{ hollingsworth }}, and {{ weber
}}---and giving each multiple stories, before {{ bolo13 }} returns to the
many-authors format and continues some of the stories started here.

### {% short_story_title "Ancestral Voices" %}
<div class="written-by">by {{ author_stirling }}</div>
{% rating_stars 4 %}

A sequel to {{ lost_legion }} from {{ bolo10 }}, this story finds the U.S.
Army unit still trying to make its way home. This time they encounter a
volcanologist who uses his instruments to control a volcano. With this power,
he convinces the locals that he is the sixth coming of Montezuma and that they
need to restore the Aztec Empire, including human sacrifices.

This story is mostly an action-packed romp, but there's nuance too: the "good"
soldiers must steal and extort local villages to survive, while the "bad"
Aztecs live in a prosperous valley, safe from the chaos of the collapsing
world.

It vaguely reminds me of {{ conrads }} {{ heart }}, with the outsider who
convinces a native tribe that he is a demigod, complete with atrocities.

### {% short_story_title "Sir Kendrick's Lady" %}
<div class="written-by">by {{ author_lewitt }}</div>
{% rating_stars 4 %}

A sequel to {{ camelot }}, this story follows Abigail, a teenage girl growing
up on Camelot. Like most kids, she's bored and dreams of running away. At
first, it feels like a typical "you don't appreciate what you have" story, but
two twists change that:

1. The children who run away are actually being trafficked into slavery by the
   spacers guild.
2. The Bolo is almost completely powerless to help.

It's a fresh take on a standard story, and it highlights the kind of horror
that you can't solve with a well-aimed Hellbore blast.

### {% short_story_title "You're It" %}
<div class="written-by">by {{ author_meier }}</div>
{% rating_stars 5 %}

A vaguely East-Asian human Empire attacks the Concordiat and wipes out the
planet's defenders, except for one damaged Bolo. A lone technician has to
reach it without getting caught and killed by the empire's knock-off Bolos.
The story's title is based on tag, but it's much more hide-and-seek, with the
technician masking his heat signature using mud, like Arnold in {{ predator
}}, and later hiding in a giant snail carcass, a little like Luke in {{ empire
}}.

{{ author_meier }} tries to give the imperial general some depth, portraying
him as a "good" officer in a "bad" system, but it feels like the
rehabilitation of Rommel from {{ operation_desert_fox }}. He even has a
[Luger][luger].

[luger]: https://en.wikipedia.org/wiki/Luger_pistol

{{ youre_it }} is a really well-written story: suspenseful, with satisfying
action and villains who get the end they deserve. Like {{ sir_kendricks_lady
}}, there is some darkness in the pulpy action: suicide-bomber children and
slave labor camps.

It might also be the first story with a Bolo named after a woman, though {{
lost_legion }} and {{ ancestral_voices }} had a female-voiced Bolo, but one
too primitive to be "people" like LRS "Laura" is.

### {% short_story_title "Shared Experience" %}
<div class="written-by">by {{ author_stasheff }}</div>
{% rating_stars 1 %}

A Bolo experiences the deaths of his comrades as they fight off Harpies and
egg-shaped ships. Meanwhile, two humans flirt as they try to survive.

{{ author_stasheff }} writes in a flat style: "The Bolo did this. The Harpies
did that." It's boring, it's too long, and it misses what really makes Bolo
stories work: treating them as characters. Here, Titan and the other Bolos
feel more like scenery, just like in the weakest stories in {{ bolo1 }}.

One small detail: this is the first story to mention that people enter a Bolo
from underneath, between the treads. Previously, crews always had to climb up
the outside.

### {% short_story_title "The Murphosensor Bomb" %}
<div class="written-by">by {{ author_wehrstein }}</div>
{% rating_stars 5 %}

Bolos have started failing in the middle of combat, shutting themselves down
just as the fighting reaches its peak. The Psychotronics Department is
humanity's only hope to debug the problem, and they'll have to do it before
the Djann invasion arrives.

This story blends action, mystery, and strong characters. There is MAX, the
empathetic Bolo---directly inspired by {{ asimovs }} {{ liar }}---who helps
crack the case. And there's Benazir Ali, the brilliant young tech slightly in
over her head. In the end, the problem turns out to be a computer virus
planted with the help of a traitor, a bit like {{ the_legacy_of_leonidas }}.

The Octopod mechs the Djann use are a little like the tripods from {{ wellss
}} {{ war }}, as is how humanity is helpless against their assault.

### {% short_story_title "Legacy" %}
<div class="written-by">by {{ author_johnson }}</div>
{% rating_stars 4 %}

In the distant future, humanity has evolved beyond war and violence, making
them an easy target for the Hryxi, who hunt them down planet by planet. The
last humans take shelter in a cave on Earth and discover a mothballed Bolo.
Not a lot happens, and we don't get a resolution, but the story is still
hopeful: as long as a single Bolo exists, humanity has a chance, no matter the
odds. We also get a glimpse at new technology, like thought-controlled
nanobots, and a human merging their personality with that of the Bolo.

### {% short_story_title "Endings" %}
<div class="written-by">by {{ author_forstchen }}</div>
{% rating_stars 5 %}

The last Melconians escape their dying homeworld and found an agrarian colony
far away. But they were tracked, and one of the last surviving Bolos, the Mk.
XXXIII Sherman, arrives with a single mission: eradicate them. Told mostly
from the point of view of humanity's former enemies, this story does a good
job of exploring the cost of war and vengeance. And it even manages to work in
some great battles as the former Melconian warriors try to buy time for their
people.
