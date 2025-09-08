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
doesn't believe the academic consensus on why no extraterrestrial life has
been found; and space hauler Frederik Obialo, who ignores every warning sign
if it means getting closer to his dream of giving his daughter a permanent
home.

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

{{ this_book }} is a "hard sci-fi techno-thriller". It feels like {{ clancys
}} work, but not from the operator or spy perspective, it's told from the view
of civilians dragged into the conflict. The plot is hard to follow, but I
think that's the point: Chaeyoung and Frederik have no idea why governments
and mercenary groups keep hiring them, double-crossing them, or holding them
hostage.[^plot] They're a lot like Daniel Brüks in {{ echopraxia }}---the ones
who understand the least about what's really going on.

[^plot]:
    ### Chaeyoung's Storyline:

    Chaeyoung, an exobiologist, is hired by Acheron Private Capital Group to
    investigate the Mu Herculis system. Her expedition discovers an alien
    derelict but is ambushed by the rival mercenary outfit, Grayson Services
    Group. Chaeyoung and her love interest, Vis, are captured together.
    Grayson takes them to a secret base where they are forced to work on
    advanced faster-than-light drives. Vis is recused by Uniter Planet Navy
    Shades. Chaeyoung and the two other captive physicists (Mimo and Ali) are
    moved to the planetoid Tritonis Prime, where they are forced to
    reverse-engineering a powerful alien artifact: a Closed Time-like Curve
    Computer (CTCC), likely built by a second, more advanced alien species.

    In a desperate sabotage attempt, Mimo triggers an explosion that unleashes
    a xenoform plague from the CTCC: a self-replicating ferrofluid that
    transforms victims into monstrous creatures. Chaeyoung escapes the chaos
    and is rescued by the Shades, who she convinces to destroy the
    installation. The Shades go rogue after learning their leader is going to
    be blamed, and Chaeyoung joins them.

    ### Frederik's Storyline:

    Meanwhile, the covert United Planets unit, the Shades, use a front company
    to hire freighter captain Frederik Obialo. His mission is to transport
    their operatives and a rescued VIP (Vis) to a safe house. His ship, the
    _Ergo Infinitum_, is ambushed by Grayson operatives who attach themselves
    to the hull during a cargo pickup. The crew manage to warn the safe house,
    leading to a firefight that destroys it but ends with a few Shades,
    including one named Omolara, making it to the ship. Omolara gives Vis a
    prototype CTCC (built by the physicists before their capture).

    The crew is then betrayed by one of their own, Kirk, who disables their
    ship and hands them over to Grayson's warship, the _Delightful Death_. The
    warship is suddenly attacked by metallic, crystalline aliens, possibly
    drawn to the CTCC. In the chaos, Frederik, the survivors of his crew, and
    the Shades escape in a shuttle.

The character writing is excellent. I was rooting for Chaeyoung and Vis,
hoping they'd survive and reunite. I wanted Frederik to make it back to his
daughter. And the villains, Sato and Ninya Blanca, were so evil I **hated**
them. Their presence was overpowering, I felt scared and tense whenever they
showed up, imagining what atrocity they were about to commit.

But there are signs of unfinished edits. Sometimes it felt like a sentence or
two was missing, or that both an old and a new version of a sentence ended up
in the draft. Still, it never made me cringe the way {{ suns }} or {{ shards
}} did.

The worldbuilding is unique and deep, but not overdone. The way society is
structured around unbreakable quantum encryption makes sense, but it also
leaves them vulnerable to the alien tech they discover: Closed timelike curve
computers that can break any encryption. That plot point reminded me of {{
sneakers }}, with the black box that could hack anything.
