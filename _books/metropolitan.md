---
date: 2025-04-28
title: Metropolitan
book_author: Walter Jon Williams
series: Metropolitan
book_number: 1
rating: 4
image: /books/covers/metropolitan.jpg
---

<cite class="book-title">{{ page.title }}</cite>, by <span
class="author-name">{{ page.book_author }}</span>, is the first <span
class="book-series">{{ page.series }}</span> book.


{% capture this_book %}<cite class="book-title">{{ page.title }}</cite>{% endcapture %}
{% capture the_author %}<span class="author-name">{{ page.book_author }}</span>{% endcapture %}
{% capture the_authors_lastname %}<span class="author-name">{{ page.book_author | split: " " | last }}</span>{% endcapture %}
{% capture the_authors %}{% author_link page.book_author possessive %}{% endcapture %}
{% capture the_author_link %}{% author_link page.book_author %}{% endcapture %}

{% capture city %}{% book_link "City on Fire" %}{% endcapture %}

{% capture jacksons %}{% author_link "Robert Jackson Bennett" possessive %}{% endcapture %}
{% capture tainted %}{% book_link "The Tainted Cup" %}{% endcapture %}

{% capture wolfes %}{% author_link "Gene Wolfe" possessive %}{% endcapture %}
{% capture wolfes_short %}{% author_link "Gene Wolfe" possessive link_text="Wolfe" %}{% endcapture %}
{% capture torturer %}{% book_link "The Shadow of the Torturer" %}{% endcapture %}

{% capture brunners %}{% author_link "John Brunner" possessive %}{% endcapture %}
{% capture stand_on_zanzibar %}{% book_link "Stand on Zanzibar" %}{% endcapture %}

{% capture martines %}{% author_link "Arkady Martine" possessive %}{% endcapture %}
{% capture empire %}{% book_link "A Memory Called Empire" %}{% endcapture %}

{% capture brins %}{% author_link "David Brin" possessive %}{% endcapture %}
{% capture startide %}{% book_link "Startide Rising" %}{% endcapture %}

{{ this_book }} is an urban fantasy book, set in a city that covers the Earth.
The structure, mass, and geometric layout of the city naturally generates
plasm, an electricity-like substance that mages need to cast spells. It is set
in the far far future, like {{ wolfes }} {{ torturer }}, although unlike {{
wolfes_short }} work the world still has modern-ish technology like
skyscrapers, subways, computers, and cars and magic is not mystical but
systematized like a technology.

The story is a familiar one: Aiah, her family, and her people are refugees
from the destruction of their own metropolis. They are people of color living
as second class citizens in a white world. They are preyed upon of by both the
government and organized crime. Aiah was able to escape poverty and
precariously climb into the middle class, but this leaves her resented by both
society as an minority risen too high above her station and by her family that
feels abandoned.

It's a story that would fit right in in 1980s New York; and that's what it
feels like, a story set in am immigrant neighborhood in Brooklyn. Except Aiah
is a mage. A ten story tall flaming woman destroys Wall Street. Ghosts live in
the power lines. A glowing shield encompassed the Earth trapping humanity.

The best thing about {{ this_book }} is the subtle world building scattered
throughout the story, much like {{ jacksons }} {{ tainted }}. The plot itself
builds steadily, with Aiah first figuring out how to profit off a illegal
plasm well while hiding it from the authorities, and is soon dragged into
a revolution to reshape the order of the world.

The characters were the weakest part, although they're still well written.
Aiah makes a bunch of selfish decisions, which is consistent With her
character, but made it so I didn't not enjoy spending a lot of time with her.
There is a wide cast of supporting characters, some of whom are a little
cliched, but most of whom are interesting and engaging.

One of the themes of the book is freedom and what you're willing to do to
achieve it. Aiah feels trapped in her dead-end job that doesn't quite pay the
bills and is willing to steal palsm to escape. Constantine rebels against the
oppressive governments of the city. Humanity is trapped on Earth by the
shield. There is a peregrine falcon and flying motif that accompanies the
theme of freedom.

{{ this_book }} reminded me of some books I've read recently:

- The separation of the books subsections with in-world advertisements is
  like the various in-world chapters that separated the narrative chapters in
  {{ brunners }} {{ stand_on_zanzibar }}.

- Aiah's work uses pneumatic tubes to physically send messages, like the
  infofiches in {{ martines }} {{ empire }}.

- The uplifted dolphins fighting in the revolution---although probably
  actually modified humans---reminds me of the uplifted dolphins in {{ brins
  }} {{ startide }}.

- The mix of magic, tech, and revolution reminded me of <cite
  class="video-game-title">Final Fantasy VI</cite>.

- The phone with ghostly voices in the background reminded me of the intercom
  in <cite class="video-game-title">Disco Elysium</cite> with entroponetic
  interference.

- The final battle, with both attack helicopters and mages, reminded me of
  roleplaying game <cite class="table-top-game-title">Shadowrun</cite>.

{{ the_author }} left a lot of open questions---like what is the shield and
why was it put in place?---and there are interesting characters yet to explore
like the hanged man and <!-- TODO: Who is the old researcher at the paslm
authority? -->, which I hope are explored in {{ city }}.
