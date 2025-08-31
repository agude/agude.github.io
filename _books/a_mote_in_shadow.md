---
date: 2025-08-30
title: A Mote in Shadow
book_authors: A. N. Alex
series: null
book_number: 1
rating: 5
image: /books/covers/a_mote_in_shadow.jpg
---

<cite class="book-title">{{ page.title }}</cite> is <span
class="author-name">{{ page.book_authors }}</span>'s debut novel. It's the
story of two down-on-their-luck outsiders: exobiologist Chaeyoung No, who
doesn't believe the academic consensus on why there is no extraterrestrial
life; and a space hauler, Frederik Obialo, who will ignore all the warning
signs when taking a job if it helps him get closer to his dream of providing a
permanent home for his daughter.

{% capture this_book %}<cite class="book-title">{{ page.title }}</cite>{% endcapture %}
{% capture the_author %}<span class="author-name">{{ page.book_authors }}</span>{% endcapture %}
{% capture the_authors %}<span class="author-name">{{ page.book_authors }}</span>'s{% endcapture %}
{% capture author_last_name_text %}{{ page.book_authors | split: " " | last }}{% endcapture %}
{% capture the_authors_lastname %}<span class="author-name">{{ page.book_authors | split: " " | last }}</span>{% endcapture %}
{% capture the_authors_lastname_possessive %}<span class="author-name">{{ page.book_authors | split: " " | last }}</span>'s{% endcapture %}
{% capture the_author_link %}{% author_link page.book_authors %}{% endcapture %}
{% capture the_authors_link %}{% author_link page.book_authors possessive %}{% endcapture %}
{% capture the_authors_lastname_link %}{% author_link page.book_authors link_text=author_last_name_text %}{% endcapture %}
{% capture the_authors_lastname_possessive_link %}{% author_link page.book_authors link_text=author_last_name_text possessive %}{% endcapture %}
{% capture this_series %}{% series_text page.series %}{% endcapture %}

{% capture clancys %}{% author_link "Tom Clancy" possessive %}{% endcapture %}

{% capture echopraxia %}{% book_link "Echopraxia" %}{% endcapture %}

{% capture suns %}{% book_link "House of Suns" %}{% endcapture %}

{% capture shards %}{% book_link "Shards of Earth" %}{% endcapture %}

{% capture sneakers %}<cite class="movie-title">Sneakers</cite>{% endcapture %}

I think I would describe {{ this_book }} as a "hard sci-fi, techno-thriller".
It feels like {{ clancys }} work, but seen not from the operator or spy-side,
but from the point of view of the civilians dragged unwittingly into the
conflict. It reminds me of {{ echopraxia }} because, like Daniel Brüks,
Chaeyoung and Frederik are the two characters with the least information about
what is happening, but they're the point of view the story is told from.

The characters are great. I was hoping that Chaeyoung and Vis would make it
through and be reunited. I wanted to see Frederik make it back to his
daughter. And I **hated** the villians, Sato and Ninnya Blanca. They're so
overpowering that they make you scared and tense whenever they're in the
story; and the sense of relief you get when the "good guys" who can stand up
to them arrive is...

...but there are some signs of unfinished reworks. Occasionally it felt
like either a sentence or two were left out, or sentence was rewritten and
both versions made it in. Still, it never made me cringe the way {{ suns }} or
{{ shards }} did.

The worldbuilding is unique and deep, but it's not piled on for no reason. The
way that society is structured so heavily on top of unbreakable quantum
encryption makes sense, but also leaves them vulnerable to the alien
technology they find in the book: Closed timelike curve computers that can
break any encryption.
