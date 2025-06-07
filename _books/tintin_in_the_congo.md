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
class="author-name">{{ page.book_authors }}</span>, is the second book in
the <span class="book-series">{{ page.series }}</span>. In it, Tintin travels
to the Belgian Congo and discovers a diamond smuggling ring.

{% capture this_book %}<cite class="book-title">{{ page.title }}</cite>{% endcapture %}
{% capture the_author %}<span class="author-name">{{ page.book_authors }}</span>{% endcapture %}
{% capture the_authors_lastname %}<span class="author-name">{{ page.book_authors | split: " " | last }}</span>{% endcapture %}
{% capture the_authors %}{% author_link page.book_authors possessive %}{% endcapture %}
{% capture the_author_link %}{% author_link page.book_authors %}{% endcapture %}
{% capture this_series %}{% series_text page.series %}{% endcapture %}

{% capture tt1 %}{% book_link "Tintin in the Land of the Soviets" %}{% endcapture %}
{% capture tt16 %}{% book_link "Destination Moon" %}{% endcapture %}
{% capture tt17 %}{% book_link "Explorers on the Moon" %}{% endcapture %}

I read Tintin as a child, but never got a chance to read either {{ this_book
}}  because it had not been published in America. As I started reading the
series to my kids---starting with {{ tt16 }} and {{ tt17 }}---I realized I had
a chance to finally find the controversial book now that the internet exists.
And no, I'm not going to read this one to my kids.

The book was first written in 1930, and {{ the_author }} re-wrote and re-drew
it in 1946, taking the opportunity to sanitize it a bit by removing the more
overt colonial aspects. This revised version is still it is **incredibly
racist**. The Congolese are draw in [blackface][blackface], they are lazy, and
easily fooled.

[blackface]: https://en.wikipedia.org/wiki/Blackface

The story is simple---just Tintin getting into trouble after trouble---and
only developing an overarching plot at the very end, a far cry from the more
complicated plots found in the later books. Because the only characters are
Tintin and Snowy, they talk to each other a lot more, although it's not clear
Tintin understands his dog, and Snowy does the brunt of the slapstick, a role
later taken on by Haddock, Calculus, and Thomson and Thompson.

It's interesting to read something so clearly out of its time, but it's not
good. Hopefully {{ tt1 }}, another book not published in America when I was
little, will be better.
