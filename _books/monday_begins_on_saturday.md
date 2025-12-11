---
date: 2025-12-07
title: Monday Begins on Saturday
book_authors:
  - Arkady Strugatsky
  - Boris Strugatsky
book_number: 1
rating: 3
image: /books/covers/monday_begins_on_saturday.jpg
---

<cite class="book-title">{{ page.title }}</cite>, by brothers <span
class="author-name">{{ page.book_authors[0] | split: " " | first }}</span> and
<span class="author-name">{{ page.book_authors[1] }}</span>, is a Soviet
sci-fi novel about scientist-magicians working in the National Institute for
the Technology of Witchcraft and Thaumaturgy (NITWITT), where they study
fairy tale creatures.

{% capture this_book %}<cite class="book-title">{{ page.title }}</cite>{% endcapture %}
{% capture the_authors %}<span class="author-name">{{ page.book_authors[0] | split: " " | first }}</span> and <span class="author-name">{{ page.book_authors[1] }}</span>{% endcapture %}
{% capture the_authors_first_only %}<span class="author-name">{{ page.book_authors[0] | split: " " | first }}</span> and <span class="author-name">{{ page.book_authors[1] | split: " " | first }}</span>{% endcapture %}
{% capture the_authors_possessive %}<span class="author-name">{{ page.book_authors[0] | split: " " | first }}</span> and <span class="author-name">{{ page.book_authors[1] }}</span>'s{% endcapture %}
{% capture boris %}<span class="author-name">{{ page.book_authors[1] }}</span>{% endcapture %}

{% capture picnic %}{% book_link "Roadside Picnic" %}{% endcapture %}

{% capture dan_simmons %}{% author_link "Dan Simmons" %}{% endcapture %}
{% capture dan_simmonss %}{% author_link "Dan Simmons" possessive %}{% endcapture %}
{% capture simmons %}{% author_link "Dan Simmons" link_text="Simmons" %}{% endcapture %}
{% capture simmonss %}{% author_link "Dan Simmons" link_text="Simmons" possessive %}{% endcapture %}
{% capture hyperion %}{% book_link "Hyperion" %}{% endcapture %}

{% capture hg_wells %}{% author_link "H.G. Wells" %}{% endcapture %}
{% capture hg_wellss %}{% author_link "H.G. Wells" possessive %}{% endcapture %}
{% capture wells %}{% author_link "H.G. Wells" link_text="Wells" %}{% endcapture %}
{% capture wellss %}{% author_link "H.G. Wells" link_text="Wells" possessive %}{% endcapture %}
{% capture the_time_machine %}{% book_link "The Time Machine" %}{% endcapture %}

{% capture lewis_carroll %}{% author_link "Lewis Carroll" %}{% endcapture %}
{% capture lewis_carrolls %}{% author_link "Lewis Carroll" possessive %}{% endcapture %}
{% capture carroll %}{% author_link "Lewis Carroll" link_text="Carroll" %}{% endcapture %}
{% capture carrolls %}{% author_link "Lewis Carroll" link_text="Carroll" possessive %}{% endcapture %}
{% capture alices_adventures_in_wonderland %}{% book_link "Alice's Adventures in Wonderland" %}{% endcapture %}

{% capture terry_pratchett %}{% author_link "Terry Pratchett" %}{% endcapture %}
{% capture terry_pratchetts %}{% author_link "Terry Pratchett" possessive %}{% endcapture %}
{% capture pratchett %}{% author_link "Terry Pratchett" link_text="Pratchett" %}{% endcapture %}
{% capture pratchetts %}{% author_link "Terry Pratchett" link_text="Pratchett" possessive %}{% endcapture %}
{% capture discworld %}{% series_link "Discworld" %}{% endcapture %}

{% capture jorge_luis_borges %}{% author_link "Jorge Luis Borges" %}{% endcapture %}
{% capture jorge_luis_borgess %}{% author_link "Jorge Luis Borges" possessive %}{% endcapture %}
{% capture borges %}{% author_link "Jorge Luis Borges" link_text="Borges" %}{% endcapture %}
{% capture borgess %}{% author_link "Jorge Luis Borges" link_text="Borges" possessive %}{% endcapture %}
{% capture the_library_of_babel %}{% short_story_link "The Library of Babel" %}{% endcapture %}

{% capture iain_m_banks %}{% author_link "Iain M. Banks" %}{% endcapture %}
{% capture iain_m_bankss %}{% author_link "Iain M. Banks" possessive %}{% endcapture %}
{% capture banks %}{% author_link "Iain M. Banks" link_text="Banks" %}{% endcapture %}
{% capture bankss %}{% author_link "Iain M. Banks" link_text="Banks" possessive %}{% endcapture %}
{% capture excession %}{% book_link "Excession" %}{% endcapture %}

{% capture mark_twain %}{% author_link "Mark Twain" %}{% endcapture %}
{% capture mark_twains %}{% author_link "Mark Twain" possessive %}{% endcapture %}
{% capture twain %}{% author_link "Mark Twain" link_text="Twain" %}{% endcapture %}
{% capture twains %}{% author_link "Mark Twain" link_text="Twain" possessive %}{% endcapture %}
{% capture a_connecticut_yankee %}{% book_link "A Connecticut Yankee in King Arthur's Court" %}{% endcapture %}

{% capture bram_stoker %}{% author_link "Bram Stoker" %}{% endcapture %}
{% capture bram_stokers %}{% author_link "Bram Stoker" possessive %}{% endcapture %}
{% capture stoker %}{% author_link "Bram Stoker" link_text="Stoker" %}{% endcapture %}
{% capture stokers %}{% author_link "Bram Stoker" link_text="Stoker" possessive %}{% endcapture %}
{% capture dracula %}{% book_link "Dracula" %}{% endcapture %}

{% capture erle_stanley_gardner %}{% author_link "Erle Stanley Gardner" %}{% endcapture %}
{% capture erle_stanley_gardners %}{% author_link "Erle Stanley Gardner" possessive %}{% endcapture %}
{% capture gardner %}{% author_link "Erle Stanley Gardner" link_text="Gardner" %}{% endcapture %}
{% capture gardners %}{% author_link "Erle Stanley Gardner" link_text="Gardner" possessive %}{% endcapture %}
{% capture perry_mason %}{% series_link "Perry Mason" %}{% endcapture %}

{% capture ernest_hemingway %}{% author_link "Ernest Hemingway" %}{% endcapture %}
{% capture ernest_hemingways %}{% author_link "Ernest Hemingway" possessive %}{% endcapture %}
{% capture hemingway %}{% author_link "Ernest Hemingway" link_text="Hemingway" %}{% endcapture %}
{% capture hemingways %}{% author_link "Ernest Hemingway" link_text="Hemingway" possessive %}{% endcapture %}

{% capture leo_tolstoy %}{% author_link "Leo Tolstoy" %}{% endcapture %}
{% capture leo_tolstoys %}{% author_link "Leo Tolstoy" possessive %}{% endcapture %}
{% capture tolstoy %}{% author_link "Leo Tolstoy" link_text="Tolstoy" %}{% endcapture %}
{% capture tolstoys %}{% author_link "Leo Tolstoy" link_text="Tolstoy" possessive %}{% endcapture %}

{% capture charles_dickens %}{% author_link "Charles Dickens" %}{% endcapture %}
{% capture charles_dickenss %}{% author_link "Charles Dickens" possessive %}{% endcapture %}
{% capture dickens %}{% author_link "Charles Dickens" link_text="Dickens" %}{% endcapture %}
{% capture dickenss %}{% author_link "Charles Dickens" link_text="Dickens" possessive %}{% endcapture %}

{% capture isaac_asimov %}{% author_link "Isaac Asimov" %}{% endcapture %}
{% capture isaac_asimovs %}{% author_link "Isaac Asimov" possessive %}{% endcapture %}
{% capture asimov %}{% author_link "Isaac Asimov" link_text="Asimov" %}{% endcapture %}
{% capture asimovs %}{% author_link "Isaac Asimov" link_text="Asimov" possessive %}{% endcapture %}

{% capture ray_bradbury %}{% author_link "Ray Bradbury" %}{% endcapture %}
{% capture ray_bradburys %}{% author_link "Ray Bradbury" possessive %}{% endcapture %}
{% capture bradbury %}{% author_link "Ray Bradbury" link_text="Bradbury" %}{% endcapture %}
{% capture bradburys %}{% author_link "Ray Bradbury" link_text="Bradbury" possessive %}{% endcapture %}

{% capture qntm %}{% author_link "qntm" %}{% endcapture %}
{% capture qntms %}{% author_link "qntm" possessive %}{% endcapture %}
{% capture there_is_no_antimemetics_division %}{% book_link "There Is No Antimemetics Division" %}{% endcapture %}

{% capture katsuhiro_otomo %}{% author_link "Katsuhiro Otomo" %}{% endcapture %}
{% capture katsuhiro_otomos %}{% author_link "Katsuhiro Otomo" possessive %}{% endcapture %}
{% capture otomo %}{% author_link "Katsuhiro Otomo" link_text="Otomo" %}{% endcapture %}
{% capture otomos %}{% author_link "Katsuhiro Otomo" link_text="Otomo" possessive %}{% endcapture %}
{% capture akira %}{% book_link "Akira" %}{% endcapture %}

{% capture charles_stross %}{% author_link "Charles Stross" %}{% endcapture %}
{% capture charles_strosss %}{% author_link "Charles Stross" possessive %}{% endcapture %}
{% capture stross %}{% author_link "Charles Stross" link_text="Stross" %}{% endcapture %}
{% capture strosss %}{% author_link "Charles Stross" link_text="Stross" possessive %}{% endcapture %}
{% capture the_laundry_files %}{% series_link "The Laundry Files" %}{% endcapture %}
{% capture a_colder_war %}{% short_story_link "A Colder War" %}{% endcapture %}

{{ this_book }} is like a light-hearted version of {{ qntms }} {{
there_is_no_antimemetics_division }}, or {{ strosss }} {{ the_laundry_files }}
or {{ a_colder_war }}. It follows scientists working in NITWITT as they study
Maxwell's Demons, {{ dracula }}, magic wands, and dragons while dealing with
Soviet bureaucracy. That should be the _perfect_ story for me! I love the
genre of "bureaucrats dealing with the supernatural", and I've worked at LBL
and CERN, the sort of giant research institutes this book is lampooning. But
while I find the ideas and characters to be interesting, there wasn't really a
plot to go along with it. {{ boris }} said they had the concept for the book
for a long time but that they struggled "to think of a story or a plot for the
adventure".[^boris] I don't think they ever managed.

[^boris]:
    > We came up with the idea of a story about wizards, witches,
    > sorcerers, and magicians a long time ago, at the end of the 1950s.
    > To begin with we had no idea of what might happen in it; all we knew
    > was that the heroes would be characters from the fairy tales,
    > legends, myths, and ghost stories of all cultures and times. And
    > that their adventures would take place against the backdrop of a
    > research institute with all its foibles, well known to one of us
    > from his own personal experience, and to the other from the many
    > stories recounted to him by his academic friends. We spent a long
    > time gathering together jokes and nicknames and amusing
    > characteristics for our future characters, and wrote them all down
    > on separate scraps of paper (which, as always happens, were later
    > lost). But no real advance took place; we were never able to think
    > of a story or a plot for the adventure.

    From {% citation author_last="Strugatsky" author_first="Boris"
    work_title="Afterword" container_title="Monday Begins on Saturday" %}

{{ this_book }} contains three vignettes, which are loosely connected. The
third one, in which they solve the mystery of the director A-Janus/S-Janus who
is one person in two bodies is the one I enjoyed most. The first one, where
the narrator discovers and joins NITWITT, has the least plot.

{{ this_book }} shares themes and motifs with {{ the_authors_possessive }} {{
picnic }}. One is the focus on happiness. NITWITT's mission is to discover and
perfect human happiness, and in {{ picnic }} Red's wish at the end of the book
is for "HAPPINESS, FREE, FOR EVERYONE, AND LET NO ONE BE FORGOTTEN!"

There is an optimise in {{ this_book }}, perhaps reflecting when it was
written just at the end of the liberalizing Khrushchev thaw, which is absent
in {{ picnic }}, written during the Soviet stagnation in the 70s. We see this
clearly in each books handling of the inhuman. In {{ this_book }} doubles and
other creatures are curious but harmless, while in {{ picnic }}, Arthur and
Dina are soulless dolls.
