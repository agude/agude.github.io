---
date: 2026-07-24 13:48:00 -0700
title: Burning Chrome
book_authors:
  - William Gibson
  - John Shirley
  - Bruce Sterling
  - Michael Swanwick
series: Sprawl
book_number: 0
is_anthology: true
rating: 4
image: /books/covers/burning_chrome.jpg
wikidata_qid: Q1068344
isbn: 978-0-87795-780-5
date_published: 1986-04
same_as_urls:
  - "https://www.wikidata.org/wiki/Q1068344"
  - "https://en.wikipedia.org/wiki/Burning_Chrome_%28short_story_collection%29"
  - "https://www.isfdb.org/cgi-bin/title.cgi?36850"
  - "https://www.britannica.com/topic/Burning-Chrome"
  - "https://openlibrary.org/works/OL27254W"
  - "https://www.google.com/search?kgmid=/m/09v2svh"
---

{% book_link page.title %} is a collection of short stories by {% author_link
page.book_authors[0] link=false %}.

{% capture this_book %}{% book_link page.title %}{% endcapture %}
{% capture the_author %}{% author_link page.book_authors[0] link=false %}{% endcapture %}
{% capture the_authors %}{% author_link page.book_authors[0] link=false possessive %}{% endcapture %}
{% capture author_last_name_text %}{{ page.book_authors[0] | split: " " | last }}{% endcapture %}
{% capture the_authors_lastname %}{% author_link page.book_authors[0] link=false link_text=author_last_name_text %}{% endcapture %}
{% capture the_authors_lastname_possessive %}{% author_link page.book_authors[0] link=false link_text=author_last_name_text possessive %}{% endcapture %}
{% capture the_author_link %}{% author_link page.book_authors[0] %}{% endcapture %}
{% capture the_authors_link %}{% author_link page.book_authors[0] possessive %}{% endcapture %}
{% capture the_authors_lastname_link %}{% author_link page.book_authors[0] link_text=author_last_name_text %}{% endcapture %}
{% capture the_authors_lastname_possessive_link %}{% author_link page.book_authors[0] link_text=author_last_name_text possessive %}{% endcapture %}

{% capture shirley %}{% author_link page.book_authors[1] %}{% endcapture %}
{% capture sterling %}{% author_link page.book_authors[2] %}{% endcapture %}
{% capture swanwick %}{% author_link page.book_authors[3] %}{% endcapture %}

{% capture johnny_mnemonic %}{% short_story_link "Johnny Mnemonic" %}{% endcapture %}
{% capture the_gernsback_continuum %}{% short_story_link "The Gernsback Continuum" %}{% endcapture %}
{% capture fragments_of_a_hologram_rose %}{% short_story_link "Fragments of a Hologram Rose" %}{% endcapture %}
{% capture the_belonging_kind %}{% short_story_link "The Belonging Kind" %}{% endcapture %}
{% capture hinterlands %}{% short_story_link "Hinterlands" %}{% endcapture %}
{% capture red_star_winter_orbit %}{% short_story_link "Red Star, Winter Orbit" %}{% endcapture %}
{% capture new_rose_hotel %}{% short_story_link "New Rose Hotel" %}{% endcapture %}
{% capture the_winter_market %}{% short_story_link "The Winter Market" %}{% endcapture %}
{% capture dogfight %}{% short_story_link "Dogfight" %}{% endcapture %}
{% capture burning_chrome %}{% short_story_link "Burning Chrome" %}{% endcapture %}

{% capture this_series %}{% series_text page.series %}{% endcapture %}
{% capture sprawl %}{% series_link "Sprawl" %}{% endcapture %}
{% capture sprawl_trilogy %}the {% series_link page.series %} trilogy{% endcapture %}
{% capture neuromancer %}{% book_link "Neuromancer" %}{% endcapture %}
{% capture count_zero %}{% book_link "Count Zero" %}{% endcapture %}
{% capture mona_lisa_overdrive %}{% book_link "Mona Lisa Overdrive" %}{% endcapture %}

{% capture brunner %}{% author_link "John Brunner" %}{% endcapture %}
{% capture brunners %}{% author_link "John Brunner" possessive %}{% endcapture %}
{% capture brunner_lastname %}{% author_link "John Brunner" link_text="Brunner" %}{% endcapture %}
{% capture brunners_lastname %}{% author_link "John Brunner" link_text="Brunner" possessive %}{% endcapture %}
{% capture stand_on_zanzibar %}{% book_link "Stand on Zanzibar" %}{% endcapture %}

{% capture brin %}{% author_link "David Brin" %}{% endcapture %}
{% capture brins %}{% author_link "David Brin" possessive %}{% endcapture %}
{% capture brin_lastname %}{% author_link "David Brin" link_text="Brin" %}{% endcapture %}
{% capture brins_lastname %}{% author_link "David Brin" link_text="Brin" possessive %}{% endcapture %}
{% capture startide_rising %}{% book_link "Startide Rising" %}{% endcapture %}

{% capture liu_cixin %}{% author_link "Liu Cixin" %}{% endcapture %}
{% capture liu_cixins %}{% author_link "Liu Cixin" possessive %}{% endcapture %}
{% capture liu_cixin_lastname %}{% author_link "Liu Cixin" link_text="Liu" %}{% endcapture %}
{% capture liu_cixins_lastname %}{% author_link "Liu Cixin" link_text="Liu" possessive %}{% endcapture %}
{% capture the_three_body_problem %}{% book_link "The Three-Body Problem" %}{% endcapture %}

{% capture williams %}{% author_link "Walter Jon Williams" %}{% endcapture %}
{% capture williamss %}{% author_link "Walter Jon Williams" possessive %}{% endcapture %}
{% capture williams_lastname %}{% author_link "Walter Jon Williams" link_text="Williams" %}{% endcapture %}
{% capture williamss_lastname %}{% author_link "Walter Jon Williams" link_text="Williams" possessive %}{% endcapture %}
{% capture city_on_fire %}{% book_link "City on Fire" %}{% endcapture %}

{% capture bradbury %}{% author_link "Ray Bradbury" %}{% endcapture %}
{% capture bradburys %}{% author_link "Ray Bradbury" possessive %}{% endcapture %}
{% capture bradbury_lastname %}{% author_link "Ray Bradbury" link_text="Bradbury" %}{% endcapture %}
{% capture bradburys_lastname %}{% author_link "Ray Bradbury" link_text="Bradbury" possessive %}{% endcapture %}
{% capture the_toynbee_convector %}{% book_link "The Toynbee Convector" %}{% endcapture %}

{% capture l_neil_smith %}{% author_link "L. Neil Smith" %}{% endcapture %}
{% capture l_neil_smiths %}{% author_link "L. Neil Smith" possessive %}{% endcapture %}
{% capture l_neil_smith_lastname %}{% author_link "L. Neil Smith" link_text="Smith" %}{% endcapture %}
{% capture l_neil_smiths_lastname %}{% author_link "L. Neil Smith" link_text="Smith" possessive %}{% endcapture %}
{% capture the_probability_broach %}{% book_link "The Probability Broach" %}{% endcapture %}

{% capture fall %}{% author_link "Isabel Fall" %}{% endcapture %}
{% capture falls %}{% author_link "Isabel Fall" possessive %}{% endcapture %}
{% capture fall_lastname %}{% author_link "Isabel Fall" link_text="Fall" %}{% endcapture %}
{% capture falls_lastname %}{% author_link "Isabel Fall" link_text="Fall" possessive %}{% endcapture %}
{% capture attack_helicopter %}{% book_link "I Sexually Identify as an Attack Helicopter" %}{% endcapture %}

{% capture disco_elysium %}{% book_link "Disco Elysium" %}{% endcapture %}

{% capture stephenson %}{% author_link "Neal Stephenson" %}{% endcapture %}
{% capture stephensons %}{% author_link "Neal Stephenson" possessive %}{% endcapture %}
{% capture stephenson_lastname %}{% author_link "Neal Stephenson" link_text="Stephenson" %}{% endcapture %}
{% capture stephensons_lastname %}{% author_link "Neal Stephenson" link_text="Stephenson" possessive %}{% endcapture %}
{% capture snow_crash %}{% book_link "Snow Crash" %}{% endcapture %}

{% capture arkady_strugatsky %}{% author_link "Arkady Strugatsky" %}{% endcapture %}
{% capture boris_strugatsky %}{% author_link "Boris Strugatsky" %}{% endcapture %}
{% capture arkady_and_boris_strugatsky %}{% author_link "Arkady Strugatsky" link_text="Arkady" %} and {% author_link "Boris Strugatsky" %}{% endcapture %}
{% capture arkady_and_boris_strugatskys %}{% author_link "Arkady Strugatsky" link_text="Arkady" %} and {% author_link "Boris Strugatsky" possessive %}{% endcapture %}
{% capture roadside_picnic %}{% book_link "Roadside Picnic" %}{% endcapture %}

{% capture banks %}{% author_link "Iain M. Banks" %}{% endcapture %}
{% capture bankss %}{% author_link "Iain M. Banks" possessive %}{% endcapture %}
{% capture banks_lastname %}{% author_link "Iain M. Banks" link_text="Banks" %}{% endcapture %}
{% capture bankss_lastname %}{% author_link "Iain M. Banks" link_text="Banks" possessive %}{% endcapture %}

{% capture stross %}{% author_link "Charles Stross" %}{% endcapture %}
{% capture strosss %}{% author_link "Charles Stross" possessive %}{% endcapture %}
{% capture stross_lastname %}{% author_link "Charles Stross" link_text="Stross" %}{% endcapture %}
{% capture strosss_lastname %}{% author_link "Charles Stross" link_text="Stross" possessive %}{% endcapture %}
{% capture a_colder_war %}{% book_link "A Colder War" %}{% endcapture %}
{% capture accelerando %}{% book_link "Accelerando" %}{% endcapture %}

{% capture the_state_of_the_art %}{% book_link "The State of the Art" %}{% endcapture %}
{% capture cleaning_up %}{% short_story_link "Cleaning Up" %}{% endcapture %}

{% capture qntm %}{% author_link "qntm" %}{% endcapture %}
{% capture qntms %}{% author_link "qntm" possessive %}{% endcapture %}
{% capture lena %}{% short_story_link "Lena" %}{% endcapture %}

{% capture watts %}{% author_link "Peter Watts" %}{% endcapture %}
{% capture wattss %}{% author_link "Peter Watts" possessive %}{% endcapture %}
{% capture watts_lastname %}{% author_link "Peter Watts" link_text="Watts" %}{% endcapture %}
{% capture wattss_lastname %}{% author_link "Peter Watts" link_text="Watts" possessive %}{% endcapture %}
{% capture blindsight %}{% book_link "Blindsight" %}{% endcapture %}
{% capture echopraxia %}{% book_link "Echopraxia" %}{% endcapture %}
{% capture firefall %}{% series_link "Firefall" %}{% endcapture %}

{{ this_book }} was published after {{ neuromancer }} and {{ count_zero }},
but most of the stories were written before, and it shows in three ways:

First, the prose in the {{ sprawl_trilogy }} is light, sparse, almost poetic.
{{ the_authors_lastname }} doesn't tell you everything, he gives you just
enough to leave an impression and trusts your mind to fill in the rest. These
early works are much heavier, the prose slower, the descriptions longer, but
you can see him finding his voice: by {{ new_rose_hotel }} his prose is
stripped down and lean.

Second, many of the ideas and themes {{ the_authors_lastname }} expands in his
novels were first tested out in these short stories. This is clearest in the
{{ sprawl }} short stories---{{ johnny_mnemonic }}, {{ new_rose_hotel }}, {{
burning_chrome }}---but almost every story has some piece that was reused.

Third, nearly every story is narrated by a man watching a woman with more
agency than he has: she drives the action, she gets what she wants, and more
often than not she leaves the man behind. Johnny is passively dragged along by
Molly. The narrator recounts how Sandii burned him while he waits to die.
Casey is left coming to terms with Lise's upload. We only see the women
through others' eyes. But by the novels, {{ the_authors_lastname }} allows
them to tell their own stories---Molly, Marly, Angela, Mona, and Kumiko all
get their own chapters.

### {% short_story_title "Johnny Mnemonic" %}

{% rating_stars 4 %}

{{ johnny_mnemonic }} is an early {{ sprawl }} story featuring Johnny---a man
able to store proprietary data in his head---and Molly---the street samurai
from {{ neuromancer }} and {{ mona_lisa_overdrive }}. The Yakuza want Johnny
dead because his mind contains their stolen data, and Molly is excited about
the opportunity to test her enhancements against a vat-grown ninja. Unlike
other stories in this book, this one is a direct prequel. Molly is one of the
main characters in the trilogy; Johnny is mentioned as part of her backstory.

This story also introduces the theme that appears again and again in the {{
sprawl }}: what do you sacrifice and what do you lose when you modify
yourself. Johnny makes a living storing people's secrets but has no control
over what is put there. Molly has gained strength, speed, but as we see in {{
neuromancer }} it comes at a high cost.

{{ johnny_mnemonic }} starts to get at the weirdness of the sprawl. It's not
all rain-slicked streets and towering zaibatsu and neon lights in cyberspace;
it's also heroin-addicted uplifted dolphins (two years before {{
brins_lastname }} {{ startide_rising }}), ninjas with monomolecular wire in
their thumbs, and outcasts who implant animal teeth and live up in the rafters
of the geodesic domes. It's something {{ the_authors_lastname }} learned from
{{ brunners_lastname }} {{ stand_on_zanzibar }}: the weirdness makes the
future feel more real.

### {% short_story_title "The Gernsback Continuum" %}

{% rating_stars 3 %}

{{ the_authors_lastname }} doesn't write horror, but much of what he writes is
horrifying. {{ the_gernsback_continuum }} is an inversion of his normal horror
in three ways. {{ the_authors_lastname }} usually looks at a possible future;
here he looks back at a future that never arrived. The horror is normally in
the details---puppet shops, fast-growing custom-tailored cancers---so
commonplace the prose hardly has time for them. Here absolutely nothing is
grim; everything is seamless, smooth, fast, interchangeable. And the squalor
is usually the disease, the thing that's wrong with the world. Here it's the
cure, with porn, bad television, and the ugly real world the only things that
can break the spell.

But the prose is clunky, the characters don't matter. It's a story all about
the _idea_ and that's not enough for me.

### {% short_story_title "Fragments of a Hologram Rose" %}

{% rating_stars 3 %}

{{ the_authors_lastname_possessive }} first published story. It's built around
the idea that a fragment of a hologram gives you the whole picture still. {{
the_authors_lastname }} gives us fragments of Parker's life, and of his
ex-girlfriend's via ASP---a precursor idea to simstim---and lets us form the
picture. This is the exact style I love in the {{ sprawl_trilogy }}, but he
doesn't quite land it here.

There's a small, throwaway bit about ASP stars becoming more androgynous
because viewers can't adapt to different-gender recordings. It reminded me of
{{ falls_lastname }} {{ attack_helicopter }}, where Barb changes her gender to
fly better.

### {% short_story_title "The Belonging Kind" %}

<div class="written-by">by {{ the_author_link }} and {{ shirley }}</div>
{% rating_stars 2 %}

A bizarre tale about a species that subsists on alcohol and uses human form as
camouflage. The main character is a linguist who can't make small talk, but
after becoming obsessed with one of the creatures, becomes one himself and
starts to blend in. A throwaway idea and little else.

### {% short_story_title "Hinterlands" %}

{% rating_stars 5 %}

{{ hinterlands }} is the best story in {{ this_book }}. It perfectly balances
the sense of wonder and dread I love in science fiction. It's about surrogates
at a space station. Their job is to rendezvous with astronauts returning
through the wormhole, most of whom kill themselves immediately, but some of
whom share transformative knowledge before their insanity gets to them.

{{ the_authors_lastname }} beautifully incorporates both the trauma the
surrogates feel as they have to bond with people who are going to die, and
also the guilt and loss they feel at having tried to go through the wormhole
and been rejected, for all surrogates are failed wormhole explorers.

Only a few other books have balanced wonder and dread in the way this story
does: {{ arkady_and_boris_strugatskys }} {{ roadside_picnic }}, of course,
which this story is influenced by; {{ strosss_lastname }} {{ a_colder_war }};
{{ wattss_lastname }} {{ firefall }}; {{ disco_elysium }}.

### {% short_story_title "Red Star, Winter Orbit" %}

<div class="written-by">by {{ the_author_link }} and {{ sterling }}</div>
{% rating_stars 3 %}

This story takes place on a decaying, soon-to-be-abandoned Soviet space
station. They won the Cold War, went to the Moon, to Mars, and now everything
is crumbling. It's almost an alternative history of the {{ sprawl }}, where
instead of Japan winning and the Zaibatsus taking over, the Soviets did and
then collapsed.

Reggae shows up briefly in this story, and a few others. {{
the_authors_lastname }} used Afro-Caribbean culture throughout the {{
sprawl_trilogy }}: the Rastafarian Zion cluster in {{ neuromancer }} and the
Haitian Vodou Loa in {{ count_zero }}.

### {% short_story_title "New Rose Hotel" %}

{% rating_stars 5 %}

### {% short_story_title "The Winter Market" %}

{% rating_stars 4 %}

Another story that reads like something from the {{ sprawl }} but isn't. Casey
is a stim editor (another simstim precursor) who discovers a disabled artist,
Lise. People love her work because she's trapped in her body, and it's the
same feelings, but amplified, that the down-and-out populace feels. She uses
Casey to become a star, giving her the opportunity to upload her mind and
escape her body. There is an irony there: her body is what made her art, and
she casts it aside.

This story asks "is the upload still Lise?"; Casey doesn't think so, and
dreads talking to her after it happens, fearful she'll convince him otherwise.
It's the same idea that shows up in the {{ sprawl }} novels---with Dixie
Flatline, the Count and Angie---and in works like {{ qntms }} {{ lena }}.
Rubin, an artist who builds things out of _gomi_, is another prototype: he
becomes Slick from {{ mona_lisa_overdrive }}.

### {% short_story_title "Dogfight" %}

<div class="written-by">by {{ the_author_link }} and {{ swanwick }}</div>
{% rating_stars 3 %}

The third and final collaboration in this collection, {{ dogfight }}, is about
a drifter who cheats his way to winning at video games. In the process he
destroys a disabled veteran's only source of meaning in life, and ruins his
fledgling relationship. It's an inversion of the women-with-agency pattern in
the rest of {{ this_book }}.

The story isn't based in the {{ sprawl }}, but it reads as another prototype
with reflex-improving drugged-out fighter pilots, personal holographic
projections like those used by Riviera in {{ neuromancer }}, and punishments
that involve changing your personality like Slick in {{ mona_lisa_overdrive
}}.

### {% short_story_title "Burning Chrome" %}

{% rating_stars 4 %}

This story is a straightforward heist: Bobby Quine and Automatic Jack burn
Chrome, a mob-connected fixer, and redistribute her money. But behind the
simple story are ideas that would be revisited in the {{ sprawl }} novels:
it's the first place {{ the_authors_lastname }} describes cyberspace, as a
neon-lit geometric world you can jack into and steal a billion dollars. Rikki,
Bobby's muse, needs Zeiss Ikon eyes so she can be a star; she sells her body
at Chrome's puppet shop in order to fund them. It's the starkest version of
the trade we've seen in the collection and it presages the trade we learn
Molly made in {{ neuromancer }}. And this story gives us one of the most
famous of {{ the_authors_lastname_possessive }} lines: "The street finds its
own uses for things".
