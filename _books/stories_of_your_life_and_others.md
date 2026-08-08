---
date: 2026-08-03 18:56:46 -0700
title: Stories of Your Life and Others
book_authors: Ted Chiang
series: null
book_number: 1
is_anthology: true
rating: 3
image: /books/covers/stories_of_your_life_and_others.jpg
wikidata_qid: Q3045861
isbn: 978-0-7653-0418-6
date_published: 2002-07
awards:
  - hugo
  - locus
  - nebula
same_as_urls:
  - "https://www.wikidata.org/wiki/Q3045861"
  - "https://en.wikipedia.org/wiki/Stories_of_Your_Life_and_Others"
  - "https://openlibrary.org/works/OL6216050W"
  - "https://www.isfdb.org/cgi-bin/title.cgi?40036"
  - "https://www.librarything.com/work/28008"
  - "https://www.google.com/search?kgmid=/m/09rts5s"
---

{% book_link page.title %}, by {% author_link page.book_authors link=false %},
is a collection of eight short stories and novellas.

Every story is different, very different, but they all _feel_ the same.

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

{% capture tower_of_babylon %}{% short_story_link "Tower of Babylon" %}{% endcapture %}
{% capture understand %}{% short_story_link "Understand" %}{% endcapture %}
{% capture division_by_zero %}{% short_story_link "Division by Zero" %}{% endcapture %}
{% capture story_of_your_life %}{% short_story_link "Story of Your Life" %}{% endcapture %}
{% capture seventy_two_letters %}{% short_story_link "Seventy-Two Letters" %}{% endcapture %}
{% capture the_evolution_of_human_science %}{% short_story_link "The Evolution of Human Science" %}{% endcapture %}
{% capture hell_is_the_absence_of_god %}{% short_story_link "Hell Is the Absence of God" %}{% endcapture %}
{% capture liking_what_you_see %}{% short_story_link "Liking What You See: A Documentary" %}{% endcapture %}

{% capture martin %}{% author_link "George R. R. Martin" %}{% endcapture %}
{% capture martins %}{% author_link "George R. R. Martin" possessive %}{% endcapture %}
{% capture martin_lastname %}{% author_link "George R. R. Martin" link_text="Martin" %}{% endcapture %}
{% capture martins_lastname %}{% author_link "George R. R. Martin" link_text="Martin" possessive %}{% endcapture %}
{% capture a_song_of_ice_and_fire %}{% series_link "A Song of Ice and Fire" %}{% endcapture %}

{% capture pkd_full %}{% author_link "Philip K. Dick" %}{% endcapture %}
{% capture pkd_fulls %}{% author_link "Philip K. Dick" possessive %}{% endcapture %}
{% capture pkd %}{% author_link "Philip K. Dick" link_text="PKD" %}{% endcapture %}
{% capture pkds %}{% author_link "Philip K. Dick" link_text="PKD" possessive %}{% endcapture %}
{% capture dick_lastname %}{% author_link "Philip K. Dick" link_text="Dick" %}{% endcapture %}
{% capture dicks_lastname %}{% author_link "Philip K. Dick" link_text="Dick" possessive %}{% endcapture %}

{% capture simmons %}{% author_link "Dan Simmons" %}{% endcapture %}
{% capture simmonss %}{% author_link "Dan Simmons" possessive %}{% endcapture %}
{% capture simmons_lastname %}{% author_link "Dan Simmons" link_text="Simmons" %}{% endcapture %}
{% capture simmonss_lastname %}{% author_link "Dan Simmons" link_text="Simmons" possessive %}{% endcapture %}
{% capture hyperion %}{% book_link "Hyperion" %}{% endcapture %}
{% capture the_scholars_tale %}{% short_story_link "The Scholar's Tale" %}{% endcapture %}

{% capture kierkegaard %}{% author_link "Søren Kierkegaard" %}{% endcapture %}
{% capture kierkegaards %}{% author_link "Søren Kierkegaard" possessive %}{% endcapture %}
{% capture kierkegaard_lastname %}{% author_link "Søren Kierkegaard" link_text="Kierkegaard" %}{% endcapture %}
{% capture kierkegaards_lastname %}{% author_link "Søren Kierkegaard" link_text="Kierkegaard" possessive %}{% endcapture %}
{% capture fear_and_trembling %}{% book_link "Fear and Trembling" %}{% endcapture %}

{% capture bradbury %}{% author_link "Ray Bradbury" %}{% endcapture %}
{% capture bradburys %}{% author_link "Ray Bradbury" possessive %}{% endcapture %}
{% capture bradbury_lastname %}{% author_link "Ray Bradbury" link_text="Bradbury" %}{% endcapture %}
{% capture bradburys_lastname %}{% author_link "Ray Bradbury" link_text="Bradbury" possessive %}{% endcapture %}
{% capture fahrenheit_451 %}{% book_link "Fahrenheit 451" %}{% endcapture %}

{% capture banks %}{% author_link "Iain M. Banks" %}{% endcapture %}
{% capture bankss %}{% author_link "Iain M. Banks" possessive %}{% endcapture %}
{% capture banks_lastname %}{% author_link "Iain M. Banks" link_text="Banks" %}{% endcapture %}
{% capture bankss_lastname %}{% author_link "Iain M. Banks" link_text="Banks" possessive %}{% endcapture %}
{% capture culture %}{% series_link "Culture" %}{% endcapture %}
{% capture matter %}{% book_link "Matter" %}{% endcapture %}
{% capture consider_phlebas %}{% book_link "Consider Phlebas" %}{% endcapture %}
{% capture phlebas %}{% book_link "Consider Phlebas" link_text="Phlebas" %}{% endcapture %}
{% capture look_to_windward %}{% book_link "Look to Windward" %}{% endcapture %}
{% capture windward %}{% book_link "Look to Windward" link_text="Windward" %}{% endcapture %}
{% capture use_of_weapons %}{% book_link "Use of Weapons" %}{% endcapture %}

{% capture keyes %}{% author_link "Daniel Keyes" %}{% endcapture %}
{% capture keyess %}{% author_link "Daniel Keyes" possessive %}{% endcapture %}
{% capture keyes_lastname %}{% author_link "Daniel Keyes" link_text="Keyes" %}{% endcapture %}
{% capture keyess_lastname %}{% author_link "Daniel Keyes" link_text="Keyes" possessive %}{% endcapture %}
{% capture flowers_for_algernon %}{% book_link "Flowers for Algernon" %}{% endcapture %}
{% capture algernon %}{% book_link "Flowers for Algernon" link_text="Algernon" %}{% endcapture %}

{% capture watts %}{% author_link "Peter Watts" %}{% endcapture %}
{% capture wattss %}{% author_link "Peter Watts" possessive %}{% endcapture %}
{% capture watts_lastname %}{% author_link "Peter Watts" link_text="Watts" %}{% endcapture %}
{% capture wattss_lastname %}{% author_link "Peter Watts" link_text="Watts" possessive %}{% endcapture %}
{% capture firefall %}{% series_link "Firefall" %}{% endcapture %}
{% capture blindsight %}{% book_link "Blindsight" %}{% endcapture %}

{% capture wells %}{% author_link "Martha Wells" %}{% endcapture %}
{% capture wellss %}{% author_link "Martha Wells" possessive %}{% endcapture %}
{% capture wells_lastname %}{% author_link "Martha Wells" link_text="Wells" %}{% endcapture %}
{% capture wellss_lastname %}{% author_link "Martha Wells" link_text="Wells" possessive %}{% endcapture %}
{% capture murderbot %}{% series_link "The Murderbot Diaries" link_text="Murderbot" %}{% endcapture %}
{% capture the_murderbot_diaries %}{% series_link "The Murderbot Diaries" %}{% endcapture %}

{% capture stephenson %}{% author_link "Neal Stephenson" %}{% endcapture %}
{% capture stephensons %}{% author_link "Neal Stephenson" possessive %}{% endcapture %}
{% capture stephenson_lastname %}{% author_link "Neal Stephenson" link_text="Stephenson" %}{% endcapture %}
{% capture stephensons_lastname %}{% author_link "Neal Stephenson" link_text="Stephenson" possessive %}{% endcapture %}
{% capture snow_crash %}{% book_link "Snow Crash" %}{% endcapture %}

{% capture stross %}{% author_link "Charles Stross" %}{% endcapture %}
{% capture strosss %}{% author_link "Charles Stross" possessive %}{% endcapture %}
{% capture stross_lastname %}{% author_link "Charles Stross" link_text="Stross" %}{% endcapture %}
{% capture strosss_lastname %}{% author_link "Charles Stross" link_text="Stross" possessive %}{% endcapture %}
{% capture a_colder_war %}{% short_story_link "A Colder War" %}{% endcapture %}

{% capture gibson %}{% author_link "William Gibson" %}{% endcapture %}
{% capture gibsons %}{% author_link "William Gibson" possessive %}{% endcapture %}
{% capture gibson_lastname %}{% author_link "William Gibson" link_text="Gibson" %}{% endcapture %}
{% capture gibsons_lastname %}{% author_link "William Gibson" link_text="Gibson" possessive %}{% endcapture %}
{% capture sprawl %}{% series_link "Sprawl" %}{% endcapture %}
{% capture neuromancer %}{% book_link "Neuromancer" %}{% endcapture %}
{% capture count_zero %}{% book_link "Count Zero" %}{% endcapture %}
{% capture burning_chrome %}{% book_link "Burning Chrome" %}{% endcapture %}
{% capture the_winter_market %}{% short_story_link "The Winter Market" %}{% endcapture %}

{% capture qntm %}{% author_link "qntm" %}{% endcapture %}
{% capture qntms %}{% author_link "qntm" possessive %}{% endcapture %}
{% capture lena %}{% short_story_link "Lena" %}{% endcapture %}
{% capture there_is_no_antimemetics_division %}{% book_link "There Is No Antimemetics Division" %}{% endcapture %}
{% capture antimemetics %}{% book_link "There Is No Antimemetics Division" link_text="Antimemetics" %}{% endcapture %}

{% capture borges %}{% author_link "Jorge Luis Borges" %}{% endcapture %}
{% capture borgess %}{% author_link "Jorge Luis Borges" possessive %}{% endcapture %}
{% capture borges_lastname %}{% author_link "Jorge Luis Borges" link_text="Borges" %}{% endcapture %}
{% capture borgess_lastname %}{% author_link "Jorge Luis Borges" link_text="Borges" possessive %}{% endcapture %}

{% capture vonnegut %}{% author_link "Kurt Vonnegut" %}{% endcapture %}
{% capture vonneguts %}{% author_link "Kurt Vonnegut" possessive %}{% endcapture %}
{% capture vonnegut_lastname %}{% author_link "Kurt Vonnegut" link_text="Vonnegut" %}{% endcapture %}
{% capture vonneguts_lastname %}{% author_link "Kurt Vonnegut" link_text="Vonnegut" possessive %}{% endcapture %}
{% capture harrison_bergeron %}{% short_story_link "Harrison Bergeron" %}{% endcapture %}

{% capture eva %}{% tv_show_title "Neon Genesis Evangelion" %}{% endcapture %}

### {% short_story_title "Tower of Babylon" %}

{% rating_stars 4 %}

{{ tower_of_babylon }} assumes ancient cosmology is correct and treats the
construction of the [Tower of Babel][babel] as a real mega-project. It is a
simple story told about a group of miners climbing the tower to dig their way
into heaven, and I really enjoyed the details {{ the_authors_lastname }}
includes about the tower, how the people on each level lived, and the journey
the miners make.

[babel]: https://en.wikipedia.org/wiki/Tower_of_Babel

During the story, the guide tells the narrator about a time when a star
crashed into the tower. This idea of stars as literal, physical objects moving
past the characters reminded me of {{ bankss_lastname }} novel {{ matter }},
with its rollstars that roll on tracks set in the ceiling of each level of
Sursamen. It made me realize that {{ banks_lastname }} also based his
shellworlds on [Ptolemaic cosmology][geo], utilizing giant towers to support
the heavens, a world made of concentric shells, and stars on tracks.

[geo]: https://en.wikipedia.org/wiki/Geocentrism

### {% short_story_title "Understand" %}

{% rating_stars 2 %}

In {{ understand }}, a brain-damaged man is given an experimental treatment
that continuously increases his intelligence until he can see the patterns
behind everything, and discovers another super-intelligence that's been
watching him. It's a response to {{ keyess_lastname }} {{ flowers_for_algernon
}}, but without the eventual slide that adds emotional weight.

When I read this story I had not yet figured out {{
the_authors_lastname_possessive }} writing pattern, and so I kept second
guessing where the story was going. I was sure the protagonist was delusional
but no, the doctors really are trying to trick him, the CIA really is
watching. It's my main critique of {{ the_authors }} writing: his proof-like
structure makes it hard to be taken by surprise.

### {% short_story_title "Division by Zero" %}

{% rating_stars 3 %}

### {% short_story_title "Story of Your Life" %}

{% rating_stars 4 %}

### {% short_story_title "Seventy-Two Letters" %}

{% rating_stars 2 %}

{{ seventy_two_letters }} takes as its assumption that the world _actually_
works roughly how 17th-century scientists and mystics thought it did. Golems
are real and animated by a Kabbalistic name (the titular 72 letters).
Reproduction happens not via sperm and egg but via homunculus already in a
man's body when he is born. And the human race is 5 generations from
extinction.

This story has a lot of interesting branches: golems as replacement for
skilled labor, and the objection the golem making guild has to golems making
golems; the way in which names are factored and studied to create new ones;
the coming end of the world; the interplay between the politics of the poor
and the gentry. But {{ the_authors_lastname }} is only interested in them in
how they allow the story to unfold, not in really exploring their
consequences. That's why I didn't like this story. It makes ill use of its
amazing ideas.

The golems reminded me of modern large language models. Both take instructions
and carry them out in a manner that only humans could before, and as the
golems improve they start replacing humans at skilled crafts. We might be
starting to see the same thing with our own language golems, piles of words
given thought, as they completely replace manual programming.

I've read a lot of stories where the authors use mysticism to make technology
unknowable: {{ gibsons_lastname }} voodoo loa as a framework for AIs in {{
count_zero }}, {{ stephensons_lastname }} Sumerian language-virus in {{
snow_crash }}, {{ strosss_lastname }} weaponized Cthulhu in {{ a_colder_war
}}. Here {{ the_authors_lastname }} does the opposite: he takes mysticism and
treats it as a technology. Names as programming and math; golems as machines.

### {% short_story_title "The Evolution of Human Science" %}

{% rating_stars 3 %}

### {% short_story_title "Hell Is the Absence of God" %}

{% rating_stars 5 %}

In my review of {{ bradburys_lastname }} {{ fahrenheit_451 }}, I said: "Some
of my favorite books have structures that reinforce their themes." {{
hell_is_the_absence_of_god }} was my favorite story in {{ this_book }} because
it subverts {{ the_authors_lastname_possessive }} formula, and in doing so it
reinforces the theme of the work.

The axiom in this story is "God is real, His acts are quantifiable". {{
the_authors_lastname }} takes this where it leads: angelic visitations are
treated like weather and reported on the news; statistics on who is damned and
who ascends are tracked; people flock to places where angels often emerge
hoping for miracles. Neil Fisk's wife was killed in a visitation and ascended
to heaven. Neil doesn't love God, and so knows he won't be reunited with her.
But he also knows that if you view Heaven's light when an angel emerges, you
are rewritten to unconditionally love God, and always ascend to heaven. He
sets out to see it.

Neil's reliance on the quantifiable system of God is similar to Sol Weintraub
from {{ simmonss_lastname }} {{ hyperion }}. Sol is an academic expert on
God's covenant and on {{ kierkegaard_lastname_possessive }} {{
fear_and_trembling }}. He is intellectually ready for the exact problem he
finds himself in, yet when a god-like entity demands the sacrifice of his
daughter Rachel, all of Sol's theological mastery is useless. He cannot
outdebate the absolute. Neil tries the same, reasoning: if A (see the light),
then B (love God), then C (salvation).

Neil succeeds in glimpsing Heaven's light, comes to love God unconditionally,
and is sent to Hell anyway. {{ the_authors_lastname }} breaks the chain of
logic he so steadfastly followed in the rest of the stories, and in doing so
shows you that God isn't just, God isn't kind, God---even in a world where you
think you can write down rules that he follows---is Sovereign.

This story, with it's natural disaster-like angels, reminded me of {{ eva }}
where angels are alien, terrifying; an extinction level threat. It's also
similar to {{ strosss_lastname }} {{ a_colder_war }} in how it takes cosmic
and grounds it in the real world. And in {{ count_zero }}, {{ gibson_lastname
}} uses religion as a framework for incomprehensible power; {{
the_authors_lastname }} instead makes religion comprehensible and turns it
into engineering. <!-- Do I need this here and in 72? Probably just in 72 with
a mention about it here also? -->

### {% short_story_title "Liking What You See: A Documentary" %}

{% rating_stars 3 %}
