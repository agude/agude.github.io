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

I would describe {{ this_book }} as a "hard sci-fi, techno-thriller". It feels
like {{ clancys }} work, but seen not from the operator or spy-side, but from
the point of view of the civilians dragged unwittingly into the conflict. The
story is hard to follow, but I think that's intentional: the main
characters---Chaeyoung and Frederik---don't understand why multiple different
governments and mercenary groups are hiring them, double-crossing them, and
holding them hostage. They're a lot like Daniel Bruks in {{ echopraxia }} in
that they know the least about what's going on.

### Plot

The plot, mostly so I can piece it together for myself is:

Chaeyoung is hired by Archeon Private Capital Group, an arms manufacture, to
explore a solar system that she believes is the origin of some alien life;
APCG knows that there is an alien spaceship there. The team finds the ship,
but is ambushed and captured by Grayson Service Group. Grayson wants the
physicist Vis-viva to work on their secret improved FTL drive, but after
undetected sabotage by the scientists moves them to a new project. Before the
scientists can be moved, Vis is rescued by United Planet's intelligence
division's deniable special forces, the Shades.

Grayson takes the two remaining physicists and Chaeyoung to a small planet
with alien ruins, including alien Closed Time-like Curve Computers. The
scientists are forced to reverse engineer the CTCCs, and eventually do. Then
there is a catestrophic explosion, probably planned by the scientists, that
kills one of them and infects the other with some alien virus. The virus
spreads and Grayson is soon fighting against alien zombies. The
un-contamonated Grayson employees escape to the Surface with Chaeyoung. She
wins some trust and uses it to send a distress call, which is answered by the
UP Shades. She convinces them to go destroy the alien site, which they do at
great cost. The leader of the Shades is infected, but doesn't become a zombie
because Chaeyoung uses some other alien tech on her. When the Shades and
Chaeyoung are picked up, they realize the UP is going to pin this disaster on
the Shades' leader, and so Chaeyoung joins the Shades and they all escape.

Meanwhile, the team that ex-filtrated Vis needs transport to a safehouse and
hires Frederik and his crew. When they stop at a station to pickup supplies,
Grayson commandos space-walk from the station and attach to the hull of the
ship, where they later ambush the crew and take control, executing most of the
UP team. As they approach the safehouse, Frederik gets off a warning message
that alerts the Shades. A firefight between the shades on the safehouse and
the Grayson forces on the ship commences, destroying the safehouse and
damaging the ship. Two Shades make it across to the ship and are able to take
it back from Grayson. But the crew is betrayed by one of their own who leaves
them standard, where Grayson's warship can pick them up.

The crew, one remaining Shade, one commando, and Vis are taken prisoner. But
the Graysons warship is ambushed by an Alien ship and it's liquid metal crew.
The aliens are winning, but Grayson is able to nuke their ship. Vis has a CTCC
which she brought with here, and maybe was taken when she was rescued, which
she uses to take over the Grayson warship. The good guys escape and the ship
explodes, destroying the last aliens.

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
