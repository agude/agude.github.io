---
date: 2026-06-22 21:47:57 -0700
title: Count Zero
book_authors: William Gibson
series: Sprawl
book_number: 2
is_anthology: false
rating: 5
image: /books/covers/count_zero.jpg
wikidata_qid: Q2384854
isbn: 978-0-87795-793-7
date_published: 1986-03
same_as_urls:
  - "https://www.wikidata.org/wiki/Q2384854"
  - "https://en.wikipedia.org/wiki/Count_Zero"
  - "https://openlibrary.org/works/OL27256W"
  - "https://www.isfdb.org/cgi-bin/title.cgi?2195"
  - "https://www.britannica.com/topic/Count-Zero"
  - "https://www.librarything.com/work/2445"
  - "https://www.google.com/search?kgmid=/m/01z439"
---

{% book_link page.title %}, by {% author_link page.book_authors link=false %},
is the second book in {% series_text page.series link=false %}. It follows
three strangers---a teenage hacker on his first run, a mercenary hired to
extract a defecting scientist, and an art dealer tracking down mysterious
boxes---as they're pulled into a struggle between zaibatsus, the ultra-rich,
and something stranger.

{% capture this_book %}{% book_link page.title %}{% endcapture %}
{% capture the_author %}{% author_link page.book_authors link=false %}{% endcapture %}
{% capture the_authors %}{% author_link page.book_authors link=false possessive %}{% endcapture %}
{% capture author_last_name_text %}{{ page.book_authors | split: " " | last }}{% endcapture %}
{% capture the_authors_lastname %}{% author_link page.book_authors link=false link_text=author_last_name_text %}{% endcapture %}
{% capture the_authors_lastname_possessive %}{% author_link page.book_authors link=false link_text=author_last_name_text possessive %}{% endcapture %}
{% capture the_author_link %}{% author_link page.book_authors %}{% endcapture %}
{% capture the_authors_link %}{% author_link page.book_authors possessive %}{% endcapture %}
{% capture the_authors_lastname_link %}{% author_link page.book_authors link_text=author_last_name_text %}{% endcapture %}
{% capture the_authors_lastname_possessive_link %}{% author_link page.book_authors link_text=author_last_name_text possessive %}{% endcapture %}

{% capture this_series %}{% series_text page.series %}{% endcapture %}
{% capture this_series_no_the %}{% series_link "Sprawl" %} series{% endcapture %}

{% capture neuromancer %}{% book_link "Neuromancer" %}{% endcapture %}
{% capture mona_lisa_overdrive %}{% book_link "Mona Lisa Overdrive" %}{% endcapture %}

{% capture stross %}{% author_link "Charles Stross" %}{% endcapture %}
{% capture strosss %}{% author_link "Charles Stross" possessive %}{% endcapture %}
{% capture stross_lastname %}{% author_link "Charles Stross" link_text="Stross" %}{% endcapture %}
{% capture strosss_lastname %}{% author_link "Charles Stross" link_text="Stross" possessive %}{% endcapture %}
{% capture accelerando %}{% book_link "Accelerando" %}{% endcapture %}

{% capture bradbury %}{% author_link "Ray Bradbury" %}{% endcapture %}
{% capture bradburys %}{% author_link "Ray Bradbury" possessive %}{% endcapture %}
{% capture bradbury_lastname %}{% author_link "Ray Bradbury" link_text="Bradbury" %}{% endcapture %}
{% capture bradburys_lastname %}{% author_link "Ray Bradbury" link_text="Bradbury" possessive %}{% endcapture %}
{% capture fahrenheit_451 %}{% book_link "Fahrenheit 451" %}{% endcapture %}

{% capture alex %}{% author_link "A. N. Alex" %}{% endcapture %}
{% capture alexs %}{% author_link "A. N. Alex" possessive %}{% endcapture %}
{% capture alex_lastname %}{% author_link "A. N. Alex" link_text="Alex" %}{% endcapture %}
{% capture alexs_lastname %}{% author_link "A. N. Alex" link_text="Alex" possessive %}{% endcapture %}
{% capture a_mote_in_shadow %}{% book_link "A Mote in Shadow" %}{% endcapture %}

{% capture stephenson %}{% author_link "Neal Stephenson" %}{% endcapture %}
{% capture stephensons %}{% author_link "Neal Stephenson" possessive %}{% endcapture %}
{% capture stephenson_lastname %}{% author_link "Neal Stephenson" link_text="Stephenson" %}{% endcapture %}
{% capture stephensons_lastname %}{% author_link "Neal Stephenson" link_text="Stephenson" possessive %}{% endcapture %}
{% capture snow_crash %}{% book_link "Snow Crash" %}{% endcapture %}

{% capture hubbard %}{% author_link "L. Ron Hubbard" %}{% endcapture %}
{% capture hubbard_lastname %}{% author_link "L. Ron Hubbard" link_text="Hubbard" %}{% endcapture %}

{% capture williams %}{% author_link "Walter Jon Williams" %}{% endcapture %}
{% capture williamss %}{% author_link "Walter Jon Williams" possessive %}{% endcapture %}
{% capture williams_lastname %}{% author_link "Walter Jon Williams" link_text="Williams" %}{% endcapture %}
{% capture williamss_lastname %}{% author_link "Walter Jon Williams" link_text="Williams" possessive %}{% endcapture %}
{% capture metropolitan_series %}{% series_link "Metropolitan" %}{% endcapture %}
{% capture city_on_fire %}{% book_link "City on Fire" %}{% endcapture %}

{% capture simmons %}{% author_link "Dan Simmons" %}{% endcapture %}
{% capture simmonss %}{% author_link "Dan Simmons" possessive %}{% endcapture %}
{% capture simmons_lastname %}{% author_link "Dan Simmons" link_text="Simmons" %}{% endcapture %}
{% capture simmonss_lastname %}{% author_link "Dan Simmons" link_text="Simmons" possessive %}{% endcapture %}
{% capture cantos %}{% series_link "Hyperion Cantos" %}{% endcapture %}
{% capture hyperion %}{% book_link "Hyperion" %}{% endcapture %}

{% capture wolfe %}{% author_link "Gene Wolfe" %}{% endcapture %}
{% capture wolfes %}{% author_link "Gene Wolfe" possessive %}{% endcapture %}
{% capture wolfe_lastname %}{% author_link "Gene Wolfe" link_text="Wolfe" %}{% endcapture %}
{% capture wolfes_lastname %}{% author_link "Gene Wolfe" link_text="Wolfe" possessive %}{% endcapture %}
{% capture botns %}{% series_link "The Book of the New Sun" %}{% endcapture %}
{% capture the_shadow_of_the_torturer %}{% book_link "The Shadow of the Torturer" %}{% endcapture %}

{% capture watts %}{% author_link "Peter Watts" %}{% endcapture %}
{% capture wattss %}{% author_link "Peter Watts" possessive %}{% endcapture %}
{% capture watts_lastname %}{% author_link "Peter Watts" link_text="Watts" %}{% endcapture %}
{% capture wattss_lastname %}{% author_link "Peter Watts" link_text="Watts" possessive %}{% endcapture %}
{% capture firefall %}{% series_link "Firefall" %}{% endcapture %}
{% capture echopraxia %}{% book_link "Echopraxia" %}{% endcapture %}

{% capture banks %}{% author_link "Iain M. Banks" %}{% endcapture %}
{% capture bankss %}{% author_link "Iain M. Banks" possessive %}{% endcapture %}
{% capture banks_lastname %}{% author_link "Iain M. Banks" link_text="Banks" %}{% endcapture %}
{% capture bankss_lastname %}{% author_link "Iain M. Banks" link_text="Banks" possessive %}{% endcapture %}
{% capture matter %}{% book_link "Matter" %}{% endcapture %}

{% capture black_mirror %}{% tv_show_title "Black Mirror" %}{% endcapture %}
{% capture ds9 %}{% tv_show_title "Deep Space Nine" %}{% endcapture %}
{% capture soylent_green %}{% movie_title "Soylent Green" %}{% endcapture %}
{% capture the_matrix %}{% movie_title "The Matrix" %}{% endcapture %}

I've been on a bit of a cyberpunk kick recently. I started {{ snow_crash }},
then paused and picked up {{ neuromancer }} to build the context I'd need to
understand {{ stephensons_lastname }} satire. That diversion taught me I
**love** {{ the_authors_lastname_possessive }} writing, so I was excited to
pick up {{ this_series }} again.

### Power Revisited

{{ this_book }} takes place 8 years after {{ neuromancer }}. It has the same
fast pacing and ideas about power, but it _feels_ more real. The characters
are smaller, just trying to survive in a newly transhuman world. Bobby
Newmark, the eponymous _Count Zero_, is just a teen who _hopes_ to be a cowboy
someday; his first run almost kills him. Case in {{ neuromancer }} was _also_
a loser---he's a druggy trying to get the street to kill him because he's too
scared to kill himself---but he _is_ a cowboy, he's good at his job, a vital
part of the team. He's an anti-hero whereas Bobby isn't even that. Marly
Krushkova doesn't have augmented vision or blades in her fingers; she sells
art. Turner, the emotionally damaged mercenary, is the closest to a bad-ass
who would have fit in {{ neuromancer }}. But {{ the_authors_lastname }} sets
it up brilliantly: he gives Turner's team backstories, a meticulous plan...
and then blows it away. Everyone's gone, none of their planning mattered. The
characters in {{ this_book }} spend a lot of time in the dirt instead of in
orbit: hiding in abandoned malls, crawling through the Appalachian mountains,
hanging out in the projects. It makes the world feel alive in a way it didn't
in {{ neuromancer }}.

{{ neuromancer }} focused on power and its cost, taking us inside the
Tessier-Ashpool dynasty to show how a pursuit of power destroyed their
humanity. {{ this_book }} views the same power from the outside. The zaibatsus
tower over the plot, so high up they can't see the people they're crushing.
Above them is the world's richest man, Josef Virek, dying of some fast-growing
cancer and playing the zaibatsus against each other, trying to find a way to
"jump" to the next evolutionary step. He has already lost his humanity, even
before the jump, as {{ the_authors_lastname }} makes clear when Marly meets
Virek's simstim avatar:

> And, for an instant, she stared directly into those soft blue eyes and knew,
> with an instinctive mammalian certainty, that the exceedingly rich were no
> longer even remotely human.

But the heroes, the zaibatsus, and Virek are all human-scale power, even if
they've left their humanity behind. Wintermute and Neuromancer were also on
this scale: they were comprehensible. But at the end of {{ neuromancer }} they
merged, and then shattered into incomprehensible, all-powerful things that
live in cyberspace. {{ the_authors_lastname }} handles that incomprehensible
power the way humans have for millennia: religion. The fragments of the AI
appear to the humans as [Loa][lwa] from [Haitian Vodou][vodou]. And they
behave the same way, possessing mortals and riding them.

[lwa]: https://en.wikipedia.org/wiki/Lwa
[vodou]: https://en.wikipedia.org/wiki/Haitian_Vodou

### Punk Influenced

{{ this_book }} deepens the connection between {{
the_authors_lastname_possessive }} {{ this_series_no_the }} and {{
stephensons_lastname }} {{ snow_crash }}. I had thought {{ stephenson }} took
{{ neuromancer }} and added mysticism, but now I see it was in {{
the_authors_lastname_possessive }} work all along. Angela's brain was modified
to allow her to connect to the divine, similar to Enki's nam-shub. She speaks
in Haitian Creole when communing with the divine, which other characters liken
to speaking in tongues, just as Rife's followers do. Both use religion as a
parallel system to technology. There are some smaller similarities too: the
pontoon town off LA is like the raft, the slamhound is similar to the rat
thing, the orthodox Scientologists with {{ hubbard_lastname }} as saint are
just like the Pearly Gates franchise with Jesus, Elvis, and Reverend Wayne.

{{ this_book }} reminded me of some other works. Virek's autonomous wealth,
sometimes at war with itself, was like the corporations-as-code in {{
strosss_lastname }} {{ accelerando }} executing their owners' (and then their
own) intent independently. Protagonists who don't understand what's going on,
at the mercy of forces far greater than themselves, is something {{
wattss_lastname }} {{ echopraxia }} and {{ alexs_lastname }} {{
a_mote_in_shadow }} also do. The enzyme addiction that keeps zaibatsu
employees loyal is like Ketracel-white from {{ ds9 }}. A continually growing
villain whose size confines them to water is similar to the megatherians from
{{ wolfes_lastname }} {{ botns }}. Turner's Bushido ethic matches Colonel
Kassad's in {{ simmonss_lastname }} {{ hyperion }}. The krill-based food and
collapsed food chain is similar to {{ soylent_green }}. Bobby riding with
Angela and the Loa through cyberspace, doing things normal cowboys can't,
reads as a proto-Neo from {{ the_matrix }}. Turner's extraction team, with a
cowboy riding shotgun to handle cyberspace, mirrors the mages riding shotgun
in {{ williamss_lastname }} {{ metropolitan_series }} series. The dog robot
that blows up Turner in the first few pages reminded me of Metalhead from {{
black_mirror }} or the Hound from {{ bradburys_lastname }} {{ fahrenheit_451
}}. {{ the_authors_lastname_possessive }} trick of making you invest in a
story that he rips out from under you is one {{ banks_lastname }} later uses
in {{ matter }}, where after hundreds of pages the medieval power struggle
gets swatted away by a cosmic horror.

I'm always nervous picking up the second book of an author I just discovered,
worried they'll break my heart. {{ this_book }} put those fears to rest. {{
the_author }} writes such short, energetic prose that sweeps me along, and his
character work is extraordinary: everyone feels different, but alive. I'm
looking forward to {{ mona_lisa_overdrive }}.
