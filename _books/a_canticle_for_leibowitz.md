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
{% capture the_authors_lastname_possessive %}<span class="author-name">{{ page.book_authors | split: " " | last }}</span>'s{% endcapture %}
{% capture the_author_link %}{% author_link page.book_authors %}{% endcapture %}
{% capture the_authors_link %}{% author_link page.book_authors possessive %}{% endcapture %}
{% capture the_authors_lastname_link %}{% author_link page.book_authors link_text="Miller" %}{% endcapture %}
{% capture the_authors_lastname_possessive_link %}{% author_link page.book_authors link_text="Miller" possessive %}{% endcapture %}
{% capture this_series %}{% series_text page.series %}{% endcapture %}

{% capture s1 %}{% short_story_link "Fiat Homo" %}{% endcapture %}
{% capture s2 %}{% short_story_link "Fiat Lux" %}{% endcapture %}
{% capture s3 %}{% short_story_link "Fiat Voluntas Tua" %}{% endcapture %}

{% capture rur %}{% book_link "R.U.R." %}{% endcapture %}

{% capture fallout %}<cite class="video-game-title">Fallout</cite>{% endcapture %}
{% capture warhammer %}<cite class="table-top-game-title">Warhammer 40,000</cite>{% endcapture %}

{% capture anathem %}{% book_link "Anathem" %}{% endcapture %}
{% capture stephensons %}{% author_link "Neal Stephenson" possessive link_text="Stephenson" %}{% endcapture %}

{% capture colder_war %}{% book_link "A Colder War" %}{% endcapture %}
{% capture stross %}{% author_link "Charles Stross" possessive link_text="Stross" %}{% endcapture %}

{% capture hyperion %}{% book_link "Hyperion" %}{% endcapture %}
{% capture simmons %}{% author_link "Dan Simmons" possessive link_text="Simmons" %}{% endcapture %}

{% capture wolfe %}{% author_link "Gene Wolfe" possessive link_text="Wolfe" %}{% endcapture %}
{% capture new_sun %}{% series_link "The Book of the New Sun" %}{% endcapture %}

{% capture john_christopher %}{% author_link "John Christopher" possessive link_text="Christopher" %}{% endcapture %}
{% capture tripods %}{% series_link "The Tripods" %}{% endcapture %}

{% capture laumer %}{% author_link "Keith Laumer" possessive link_text="Laumer" %}{% endcapture %}
{% capture bolo %}{% book_link "Bolo" %}{% endcapture %}

### {% short_story_title "Fiat Homo" %}



### {% short_story_title "Fiat Lux" %}

The "humans are servants how overthrew their masters" is a direct reference to
{{ rur }}


### {% short_story_title "Fiat Voluntas Tua" %}


{{ the_authors_lastname }} continues the theme of conflict between the realm
of man and the realm of God, much more obviously. Abbot Zerchi spends pages
arguing with a doctor about whether people should be allowed government
euthanasia after they receive a fatal dose of radiation. The Abbot, following
Catholic doctrine, says no under any circumstances. Zerchi eventually has the
argument again with a woman and her child who are dying of radiation poising.
Knowing as we do now that {{ the_authors_lastname }} eventually committed
suicide, the argument reads a lot more like him trying to use his own faith to
convince himself.

At the end, the nuclear war resumes and Zerchi is trapped when the Church
collapses. The two-headed mutant Mrs. Grales finds him, except her
child-head---Rachel---is in control. He realizes that she is born without sin
when she rejects his attempt to baptizer her, and instead administers the
[Eucharist][eucharist] to him.

Argument:

1. She is a new eve, (created from the body) like Mary. Abbot prays using Mary's prair. Born without sin.
2. She is christ like, virgin birth. Final judgement necesitated by humanity
   showing it can't be trusted.
3. Birth from Grales's shoulder sort of mirrors athena. Both are virginal.
   Rachel has a sort of naturalistic knoweldge and church connection, while
   Athena connects more closely with the scientists who doomed the world, and
   the secular power.

and that "Now he knew what she was". I interpret Rachel as the [Second
Coming][second_coming]. For the entire book, the [wandering
jew][wandering_jew] Benjamin has been trapped on earth until Jesus returns,
and he is last seen in the narrative just before Rachael wakens. Rachel is a
virgin birth, for she sprouts from Mrs. Grales instead of being there from the
start. The temptation of Zerchi to give in on euthanasia, and indeed being put
in a situation where he himself is dying in pain, can be interpreted as the
[apostasy][apostasy] the Church expects to proceed Jesus's return.

[eucharist]: https://en.wikipedia.org/wiki/Eucharist
[new_eve]: https://en.wikipedia.org/wiki/New_Eve
[second_coming]: https://en.wikipedia.org/wiki/Second_Coming
[wandering_jew]: https://en.wikipedia.org/wiki/Wandering_Jew
[apostasy]: https://en.wikipedia.org/wiki/Apostasy

### Other Works

You can see the influence of {{ this_book }} all over. In The Brotherhood of
Steel in {{ fallout }} are similar to the Order, preserving technology after a
nuclear war. In the Adeptus Mechanicus from {{ warhammer }}, who use sacred
rituals to preserve technology, and who like Abbot Zerchi, refer to AI as
"abominable". A religious order preserving knowledge is also the key plot
point in {{ stephensons }} {{ anathem }}.
