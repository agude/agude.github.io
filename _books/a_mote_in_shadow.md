---
date: 2025-08-30
title: A Mote in Shadow
book_authors: A. N. Alex
series: null
book_number: 1
rating: 5
image: /books/covers/a_mote_in_shadow.jpg
---

<cite class="book-title">{{ page.title }}</cite> is <span
class="author-name">{{ page.book_authors }}</span>'s debut novel. It's the
story of two down-on-their-luck outsiders: exobiologist Chaeyoung No, who
doesn't believe the academic consensus on why there is no extraterrestrial
life; and a space hauler, Frederik Obialo, who will ignore all the warning
signs when taking a job if it helps him get closer to his dream of providing a
permanent home for his daughter.

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

{% capture clancys %}{% author_link "Tom Clancy" possessive %}{% endcapture %}

{% capture echopraxia %}{% book_link "Echopraxia" %}{% endcapture %}

{% capture suns %}{% book_link "House of Suns" %}{% endcapture %}

{% capture shards %}{% book_link "Shards of Earth" %}{% endcapture %}

{% capture sneakers %}<cite class="movie-title">Sneakers</cite>{% endcapture %}

{{ this_book }} as a "hard sci-fi, techno-thriller". It feels like {{ clancys
}} work, seen not from the operator or spy-side but from the point of view of
the civilians dragged unwittingly into the conflict. The story is hard to
follow, but I think that's intentional: the main characters---Chaeyoung and
Frederik---don't understand why multiple different governments and mercenary
groups are hiring them, double-crossing them, or holding them hostage.[^plot]
They're a lot like Daniel Brüks in {{ echopraxia }} in that they know the
least about what's going on.

[^plot]:
    Because the two main characters don't know what's going on, the plot can
    be a bit hard to piece together. My best effort is:

    Chaeyoung is hired by Archeon Private Capital Group to investigate a solar
    system and discovers aliens. They're ambushed and captured by mercenaries
    from Grayson Service Group who use Vis---Chaeyoung's love interest---to
    study improved FTL drives. Vis is rescued by special operatives, the
    Shades, from the United Planets. Chaeyoung is left behind and Grayson
    takes her to Tritonis Prime, where the same aliens as earlier had a base.
    She and two physicist are forced to reverse engineer a Closed Time-like
    Curve Computer (CTCC), probably built by a second alien species. In an
    attempt to sabotage the effort, one of the physicist blows up the lab,
    releasing an alien plague that turns people into Zombies. Chaeyoung
    escapes to the surface with some Grayson personel and is rescued by the
    Shades.

    Meanwhile, the United Planets hire Frederik to take Vis to a safe house.
    They're attacked by Grayson operatives who attach themselves to the ship
    during a cargo pickup, but are able to fight back and warn the Shades at
    the safe house. The Shades take back the ship, and bring a prototype CTCC
    on board built by the physicists before they were captured by Grayson, but
    they're all betrayed by Kirk, one of the crew. Grayson's warship captures
    them, but is itself attacked by metalic aliens, probably a different type
    of alien than the ones Chaeyoung found, maybe the same ones that made the
    alien CTCC. Frederik, some of his crew, and some of the Shades escape.
    Chaeyoung decides to join the shades, who go rogue after it's clear the
    United Planets are going to blame their leader for the fiasco.

### Writing

The characters are great. I was hoping that Chaeyoung and Vis would make it
through and be reunited. I wanted to see Frederik make it back to his
daughter. And I **hated** the villains, Sato and Ninya Blanca. They're so
overpowering that they make you scared and tense whenever they're in the
story; and the sense of relief you get when the "good guys" who can stand up
to them arrive is...

...but there are some signs of unfinished reworks. Occasionally it felt
like either a sentence or two were left out, or sentence was rewritten and
both versions made it in. Still, it never made me cringe the way {{ suns }} or
{{ shards }} did.

The worldbuilding is unique and deep, but it's not piled on for no reason. The
way that society is structured so heavily on top of unbreakable quantum
encryption makes sense, but also leaves them vulnerable to the alien
technology they find in the book: Closed timelike curve computers that can
break any encryption.
