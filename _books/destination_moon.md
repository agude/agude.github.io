---
date: 2025-06-02
title: Destination Moon
book_authors: Hergé
series: The Adventures of Tintin
book_number: 16
rating: 4
image: /books/covers/destination_moon.jpg
---

<cite class="book-title">{{ page.title }}</cite>, by <span
class="author-name">{{ page.book_authors }}</span>, is the sixteenth book in
the <span class="book-series">{{ page.series }}</span>. It is the first book
in a two-part series as Tintin, Haddock, and Calculus prepare to fly to the
moon.

{% capture this_book %}<cite class="book-title">{{ page.title }}</cite>{% endcapture %}
{% capture the_author %}<span class="author-name">{{ page.book_authors }}</span>{% endcapture %}
{% capture the_authors_lastname %}<span class="author-name">{{ page.book_authors | split: " " | last }}</span>{% endcapture %}
{% capture the_authors %}{% author_link page.book_authors possessive %}{% endcapture %}
{% capture the_author_link %}{% author_link page.book_authors %}{% endcapture %}
{% capture this_series %}{% series_text page.series %}{% endcapture %}

{% capture tt17 %}{% book_link "Explorers on the Moon" %}{% endcapture %}

{{ this_series }} reminds me of my childhood. My father read the series as a
kid, and he read them to me and my siblings when we were growing up. Now I'm
reading them---the same stack of worn books that my father bought us---to my
children. So far, they're enjoying it!

The art in {{ this_book }} is beautiful. The precision of {{ the_authors }}
[_ligne claire_][lc] style is put to good use in drawing highly detailed,
accurate to life backgrounds---from sweeping mountain vistas, to scientific
equipment like the atomic pile, to the iconic red and white rocket featured on
the cover.

[lc]: https://en.wikipedia.org/wiki/Ligne_claire

The plot is a little slow. There is some good slapstick humor with Captain
Haddock and Calculus, but Thomson and Thompson are more subdued (but the kids
loved the skeleton gag!). And there is _a lot_ of text. {{ the_author }}
wanted this story to be realistic, and part of that was having the characters
explain in detail how the rocket and all the associated science works. The
antagonists are carefully developed, and feel like a real threat with their
various successes in spying on---and sabotaging---the effort.

Just like my siblings, my children also loved it! We're moving right on to {{
tt17 }}.
