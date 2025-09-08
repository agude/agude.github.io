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
    ### Chaeyoung's Storyline:

    Chaeyoung, an exobiologist, is hired by Acheron Private Capital Group to
    investigate the Mu Herculis system. Her expedition discovers an alien
    derelict but is ambushed by the rival mercenary outfit, Grayson Services
    Group. Chaeyoung and her love interest, Vis, are captured together.
    Grayson takes them to a secret base where they are forced to work on
    advanced faster-than-light drives. Vis is recused by Uniter Planet Navy
    Shades. Chaeyoung and the two other captive physicists (Mimo and Ali) are
    moved to the planetoid **Tritonis Prime**, where they are forced to
    reverse-engineering a powerful alien artifact: a Closed Time-like Curve
    Computer (CTCC), likely built by a second, more advanced alien species.

    In a desperate sabotage attempt, one of the physicists, Mimo, triggers an
    explosion that unleashes a xenoform plague from the CTCC. The plague is a
    self-replicating ferrofluid that transforms its victims into monstrous
    creatures. Chaeyoung manages to escape the chaos and is eventually rescued
    from the surface by the Shades, who she convinces to destroy the
    instilation. The Shades go rogue after learning their leader is going to
    be blamed for the mess and Chaeyoung joins them.

    ### Frederik's Storyline:

    Meanwhile, the covert United Planets special operations unit, the Shades,
    use a front company to hire freighter captain Frederik Obialo. His initial
    mission is to transport their operatives and a rescued VIP (Vis) to a safe
    house. Frederik's ship, the _Ergo Infinitum_, is ambushed by Grayson
    operatives who attach themselves to the vessel's hull during a cargo
    pickup. The crew are able to warn the safe house and a fire fight kicks
    off, destorying the safe house, but ending with a few Shades, including
    Omolara, making it to the ship and taking it back. Omolara gives Vis a
    prototype CTCC (built by the physicists before their capture).

    The crew is then betrayed by one of their own, Kirk, who disables their
    ship and hands them over to Grayson's warship, the _Delightful Death_. The
    warship is then attacked by a different species of metallic, crystalline
    aliens, possibly drawn to the CTCC technology. In the ensuing chaos,
    Frederik, the surviving members of his crew, and the Shades manage to
    escape in a small shuttle.

The character writing is great. I was rooting for Chaeyoung and Vis, hoping
they would make it through and be reunited. I wanted to see Frederik make it
back to his daughter. And the villains, Sato and Ninya Blanca, were so evil; I
**hated** them. Their presence was so overpowering that they made you scared
and tense whenever they're in the story.

But there are some signs of unfinished reworks. Occasionally it felt like
either a sentence or two were left out, or sentence was rewritten and both the
new and old versions made it in. Still, it never made me cringe the way {{
suns }} or {{ shards }} did.

The worldbuilding is unique and deep, but it's not piled on for no reason. The
way that society is structured so heavily on top of unbreakable quantum
encryption makes sense, but also leaves them vulnerable to the alien
technology they find in the book: Closed timelike curve computers that can
break any encryption.
