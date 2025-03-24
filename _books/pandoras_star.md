---
date: 2023-08-23
title: Pandora's Star
book_author: Peter F. Hamilton
series: Commonwealth Saga
book_number: 1
rating: 5
image: /books/covers/pandoras_star.jpg
---

I couldn't put <cite class="book-title">{{ page.title }}</cite> down! It is a
sci-fi book that reads more like a thriller. There were always new mysteries
that just a few more pages promised the answers to.

{% capture this_book %}<cite class="book-title">{{ page.title }}</cite>{% endcapture %}
{% capture the_author %}<span class="author-name">{{ page.book_author }}</span>{% endcapture %}
{% capture the_authors %}{% include author_link.html name=page.book_author possessive=true %}{% endcapture %}
{% capture this_series %}{% include series_link.html series=page.series %}{% endcapture %}

{% capture hamiltons %}<span class="author-name">Hamilton</span>'s{% endcapture %}
{% capture judas_unchained %}{% include book_link.html title="Judas Unchained" %}{% endcapture %}

The book takes place in a universe where trains running through interstellar
wormholes are the main form of transportation. It deals with themes of:

- _Inequality_, which is rampant, with the richest families (called dynasties)
  owning entire planets.

- _Life, death, and the self_, since Humans can't really die because everyone
  has a memory backups that can be loaded into a new clone. Some of the
  characters struggle with the idea that the clone is not really them
  (something I agree with) but this is sort of glossed over in the book.

- _Family_, since people don't die, families are huge but less tightly-bound.
  Marriages last a few decades and people know they'll end before they begin.
  And of course the largest companies are the dynasties themselves.

But it doesn't really linger on these questions; it's an action movie in book
form.

The main plot kicks off when a star suddenly disappears. The humans, being
curious, decide to find out why. This forces the human Commonwealth to build
their first real starships. Given that the title is "Pandora" you would
rightfully guess that humanity's curiosity is costly: they unleash an
aggressive alien species that launches a genocidal war against the unprepared
Commonwealth.

The book is **LONG** but the story keeps moving. The cast is huge which makes
the universe feel big, but also means that sometimes it's hundreds and
hundreds of pages before you return to a story thread that ended on a
cliffhanger. The various plot lines all feel related although you can't see
exactly how yet. The ending is abrupt, but that's because {{ this_book }} is
the first half of the {{ this_series }}, which concludes in {{ judas_unchained
}}.
