---
date: 2025-06-06 18:34:00 -0700
title: Tintin in the Congo
book_authors: Hergé
series: The Adventures of Tintin
book_number: 2
rating: 1
image: /books/covers/tintin_in_the_congo.jpg
---

<cite class="book-title">{{ page.title }}</cite>, by <span
class="author-name">{{ page.book_authors }}</span>, is the second book in the
<span class="book-series">{{ page.series }}</span>. In it, Tintin travels to
the Belgian Congo and uncovers a diamond-smuggling ring.

{% capture this_book %}<cite class="book-title">{{ page.title }}</cite>{% endcapture %}
{% capture the_author %}<span class="author-name">{{ page.book_authors }}</span>{% endcapture %}
{% capture the_authors_lastname %}<span class="author-name">{{ page.book_authors | split: " " | last }}</span>{% endcapture %}
{% capture the_authors %}{% author_link page.book_authors possessive %}{% endcapture %}
{% capture the_author_link %}{% author_link page.book_authors %}{% endcapture %}
{% capture this_series %}{% series_text page.series %}{% endcapture %}

{% capture tt1 %}{% book_link "Tintin in the Land of the Soviets" %}{% endcapture %}
{% capture tt16 %}{% book_link "Destination Moon" %}{% endcapture %}
{% capture tt17 %}{% book_link "Explorers on the Moon" %}{% endcapture %}

I read Tintin as a kid but never got a chance to read {{ this_book }}---it
hadn't been published in America. When I started reading the series to my
kids---starting with {{ tt16 }} and {{ tt17 }}---I realized I could finally
track down the controversial book now that the internet exists. And no, I'm
not going to read this one to my kids.

The book was first written in 1930, and {{ the_author }} rewrote and redrew it
in 1946, taking the opportunity to sanitize it a bit by removing the more
overt colonial elements. Even so, the revised version is still **incredibly
racist**. The Congolese are drawn in [blackface][blackface], portrayed as
lazy, easily fooled, and supercilious.

[blackface]: https://en.wikipedia.org/wiki/Blackface

The story is simple---just Tintin getting into trouble after trouble---and
only develops an overarching plot at the very end. It's a far cry from the
more complex stories in the later books. Since the only characters are Tintin
and Snowy, they talk to each other a lot more, although it's not clear Tintin
actually understands his dog. Snowy takes on most of the slapstick, a role
later filled by Haddock, Calculus, and Thomson and Thompson.

The "rules" of the world aren't fully settled yet, either, and things are a
lot crazier than in the later books. At one point, Tintin shoots a monkey and
wears its skin as a disguise. In another, he makes a slingshot out of rubber
trees and uses it to knock out an African buffalo. It feels like a [Looney
Tunes][lt] cartoon rather than the semi-realistic adventure series it
eventually becomes.

[lt]: https://en.wikipedia.org/wiki/Looney_Tunes

It's interesting to read something so clearly out of its time, but it's not
good. Hopefully, {{ tt1 }}, another book that wasn't published in America when
I was little, turns out better.
