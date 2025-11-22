---
date: 2025-11-16
title: A Canticle for Leibowitz
book_authors: Walter M. Miller Jr.
series: Saint Leibowitz
book_number: 1
is_anthology: true
rating: 4
image: /books/covers/a_canticle_for_leibowitz.jpg
awards:
  - hugo
---

<cite class="book-title">{{ page.title }}</cite>, by <span
class="author-name">{{ page.book_authors }}</span>, is the first book in the
<span class="book-series">{{ page.series }}</span> series.

{% capture this_book %}<cite class="book-title">{{ page.title }}</cite>{% endcapture %}
{% capture the_author %}<span class="author-name">{{ page.book_authors }}</span>{% endcapture %}
{% capture the_authors %}<span class="author-name">{{ page.book_authors }}</span>'s{% endcapture %}
{% capture the_authors_lastname %}<span class="author-name">Miller</span>{% endcapture %}
{% capture the_authors_lastname_possessive %}<span class="author-name">Miller</span>'s{% endcapture %}
{% capture the_author_link %}{% author_link page.book_authors %}{% endcapture %}
{% capture the_authors_link %}{% author_link page.book_authors possessive %}{% endcapture %}
{% capture the_authors_lastname_link %}{% author_link page.book_authors link_text="Miller" %}{% endcapture %}
{% capture the_authors_lastname_possessive_link %}{% author_link page.book_authors link_text="Miller" possessive %}{% endcapture %}

{% capture s1 %}{% short_story_link "Fiat Homo" %}{% endcapture %}
{% capture s2 %}{% short_story_link "Fiat Lux" %}{% endcapture %}
{% capture s3 %}{% short_story_link "Fiat Voluntas Tua" %}{% endcapture %}

{% capture darfsteller %}{% book_link "The Darfsteller" %}{% endcapture %}

{% capture bible %}{% book_link "Bible" %}{% endcapture %}

{% capture fallout %}<cite class="video-game-title">Fallout</cite>{% endcapture %}
{% capture warhammer %}<cite class="table-top-game-title">Warhammer 40,000</cite>{% endcapture %}

{% capture rur %}{% book_link "R.U.R." %}{% endcapture %}
{% capture capek %}{% author_link "Karel Čapek" %}{% endcapture %}

{% capture anathem %}{% book_link "Anathem" %}{% endcapture %}
{% capture stephensons %}{% author_link "Neal Stephenson" possessive link_text="Stephenson" %}{% endcapture %}

{% capture colder_war %}{% book_link "A Colder War" %}{% endcapture %}
{% capture strosss %}{% author_link "Charles Stross" possessive link_text="Stross" %}{% endcapture %}

{% capture hyperion %}{% book_link "Hyperion" %}{% endcapture %}
{% capture simmonss %}{% author_link "Dan Simmons" possessive %}{% endcapture %}

{% capture wolfes %}{% author_link "Gene Wolfe" possessive %}{% endcapture %}
{% capture new_sun %}{% series_link "The Book of the New Sun" %}{% endcapture %}

{% capture christophers %}{% author_link "John Christopher" possessive link_text="Christopher" %}{% endcapture %}
{% capture tripods %}{% series_link "The Tripods" %}{% endcapture %}
{% capture sword %}{% series_link "Sword of the Spirits" %}{% endcapture %}

{% capture laumers %}{% author_link "Keith Laumer" possessive link_text="Laumer" %}{% endcapture %}
{% capture bolo %}{% book_link "Bolo" %}{% endcapture %}

{% capture stirlings %}{% author_link "S. M. Stirling" possessive link_text="Stirling" %}{% endcapture %}
{% capture ancestral_voices %}{% short_story_link "Ancestral Voices" %}{% endcapture %}
{% capture the_sixth_sun %}{% short_story_link "The Sixth Sun" %}{% endcapture %}

{% capture qntms %}{% author_link "qntm" possessive %}{% endcapture %}
{% capture anti %}{% book_link "There Is No Antimemetics Division" %}{% endcapture %}

{{ this_book }} is a fix-up by {{ the_authors_lastname }} consisting of three
parts: {{ s1 }}, {{ s2 }}, and {{ s3 }}. It follows the monks of Albertian
Order of Leibowitz as the preserve the remains of mankind's knowledge after an
atomic war.

The major theme of the book is the cyclical nature of history, and the
question of "Are we doomed to repeat it?" Other themes are the conflict between
faith and reason, the double-edged sword of knowledge, and the nature of
suffering and sin.

It is an _explicitly_ Catholic book, if that wasn't clear from the fact that
it is about monks. In that way, it reminds me a lot of {{ wolfes }} {{ new_sun
}} and {{ simmonss }} {{ hyperion }}. All three authors mix Catholic theology
with science fiction, but it goes deeper than that, bringing in a shared
Catholic worldview: the Church remains a central institution, pain and
suffering are a core focus, and their far-future worlds feel ancient and
burdened by the past.

[fall]: https://en.wikipedia.org/wiki/Fall_of_man

### {% short_story_title "Fiat Homo" %}

Hundreds of years after the "Flame Deluge" destroyed civilization, a young
novice named Brother Francis Gerard discovers a fallout shelters containing
relics---a shopping list, a blueprint, etc.---from his order's founder: the
Blessed Leibowitz. Abbot Arkos worries the serendipitous discovers timing will
disrupt Leibowitz's canonization, but can't dissuade Gerard's obsession with
the relics. Gerard spends 15 years creating an illuminated version of the
blueprint, before having it stolen on his journey to New Rome to witness the
beatification of Leibowitz. Gerard is killed by the mutants on the way home.

In this section we see the start of the cycle of civilization again. We also
see the smaller scale cycles {{ the_authors_lastname }} works into his
stories: Gerard's repeated encounters with the Buzzards, who finally eat him,
and the way the [Wandering Jew][wandering_jew] both starts and ends the
chapter.

[wandering_jew]: https://en.wikipedia.org/wiki/Wandering_Jew

### {% short_story_title "Fiat Lux" %}

Hundreds of years later, humans are starting to build empires again. Thon
Taddeo, scientist and heir to the Texarkana kingdom, visits the Abbey to study
the Memorabilia. Some monks are also studying the old texts, and use them to
invent an arc lamp. Abbot Dom Paulo is caught between the rise of secular
power and knowledge, and the mission his brotherhood has upheld for hundreds
of years.

The clearest theme is the tension between religion and science, with the
Monks not full trusting the Thon, nor their own Brother Kornhoer who invents
the lamp. The theme also shows up with the church preparing to physically
defend itself from the state which looks to use it as a fort in their conquest
of the planes.

In this section, Taddeo wonders if humans are the servants of a higher race
that created them, based on his reading a piece from the Memorabilia, a
reference to the play {{ rur }} by {{ capek }}.[^robot]

[^robot]: {{ rur }} is the origin of the word "Robot".

### {% short_story_title "Fiat Voluntas Tua" %}

In the far future, humanity has once again conquered the atom and is on the
brink of war, taking us back full circle to the beginning of the book. Abbot
Zerchi prepares some of the brothers for a trip to human colonies in the stars
to preserve the order while waiting for nuclear annihilation on Earth.

{{ the_authors_lastname }} continues the theme of conflict between the realm
of man and the realm of God, much more obviously. Abbot Zerchi spends pages
arguing with a doctor about whether people should be allowed government
euthanasia after they receive a fatal dose of radiation. The Abbot, following
Catholic doctrine, says no under any circumstances. Zerchi eventually has the
argument again with a woman and her child who are dying of radiation poising.
Knowing as we do now that {{ the_authors_lastname }} eventually committed
suicide, the argument reads more like him trying to use his faith to convince
himself.

At the end, the nuclear war resumes and Zerchi is trapped when the Church
collapses. The two-headed mutant Mrs. Grales finds him, except her
child-head---Rachel---is in control. He realizes that she is born without sin
when she rejects his attempt to baptizer her, and instead administers the
[Eucharist][eucharist] to him.

[eucharist]: https://en.wikipedia.org/wiki/Eucharist

Rachel is an interesting character, despite how short her time in the story
is. She is a [new Eve][new_eve], representing the start of the cycle once
again. And as such she is clearly a [Mary][mary] figure. Zerchi recognizes
this and begins praying the [Magnificat][magnificat]---the canticle Mary spoke
when she visited Elizabeth in the {{ bible }}. She is also a Christ-like
figure. She was born of Mrs. Grales alone. Humanity's temptation to give into
euthanasia, and Zerchi himself trapped an dying in agony, can be interpreted
as the [Apostasy][apostasy] that Catholics think will proceed [Jesus's
return][second_coming]. She arrives right before humanity destroys itself
again, necessitating the [final judgment][last_judgment].

[new_eve]: https://en.wikipedia.org/wiki/New_Eve
[mary]: https://en.wikipedia.org/wiki/Mary,_mother_of_Jesus
[magnificat]: https://en.wikipedia.org/wiki/Magnificat
[apostasy]: https://en.wikipedia.org/wiki/Apostasy
[second_coming]: https://en.wikipedia.org/wiki/Second_Coming
[last_judgment]: https://en.wikipedia.org/wiki/Last_Judgment

In a way, Rachel also reminds me of Athena. Both sprout from their parent,
both are virginal, and both are symbols of knowledge. But while Athena is tied
to civilization and war---she is born fully clothed and armed---Rachel is a
being of "primal innocence" and represents a return to Eden.[^eden] Once again
it is the theme of secular verse spiritual knowledge, and Rachel signals the
end of the age of Athena.

[^eden]:
    > He did not ask why God would choose to raise up a creature of primal
    > innocence from the shoulder of Mrs. Grales, or why God gave to it the
    > preternatural gifts of Eden---those gifts which Man had been trying to
    > seize by brute force again from Heaven since first he lost them.

### Other Works

{{ the_authors_lastname_possessive }} asks "Are we doomed to repeat history?"
{{ this_book }}'s answer is "yes". Man first fell when they were [banished
from Eden][fall], after the serpent promised Adam and Eve knowledge of good
and evil. The second was the "Flame Deluge", the nuclear war, the scoured the
earth right before the novel takes place. And the third time is at the end of
the book when humanity loses Earth.

You can see the influence of {{ this_book }} all over. In The Brotherhood of
Steel in {{ fallout }} are similar to the Order, preserving technology after a
nuclear war. In the Adeptus Mechanicus from {{ warhammer }}, who use sacred
rituals to preserve technology, and who like Abbot Zerchi, refer to AI as
"abominable". A religious order preserving knowledge is also the key plot
point in {{ stephensons }} {{ anathem }}.

Mad Bear in {{ s2 }} reminds me of The Lord of the Mountain from {{ stirlings
}} {{ ancestral_voices }} and {{ the_sixth_sun }}. The general
post-apocalyptic fantasy reminded me of {{ christophers }} {{ sword }}. The
dread of the coming nuclear war in {{ s3 }} reminded me of {{ strosss }} {{
colder_war }}.

I really enjoyed {{ this_book }}. I'll be reading {{
the_authors_lastname_possessive }} {{ darfsteller }}, which was included in
the same volume, shortly. It's a novella about machines replacing humans in
the arts, which couldn't be more timely with the release of Generative AI.
Also planning to read the new version of {{ qntms }} {{ anti }} which just
released. I'm looking forward to it!
