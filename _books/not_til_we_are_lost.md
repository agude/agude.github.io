---
date: 2025-08-20
title: Not Till We Are Lost
book_authors: Dennis E. Taylor
series: Bobiverse
book_number: 5
is_anthology: false
rating: 4
image: /books/covers/not_till_we_are_lost.jpg
---

<cite class="book-title">{{ page.title }}</cite>, by <span
class="author-name">{{ page.book_authors }}</span>, is the fifth book in the
<span class="book-series">{{ page.series }}</span> series.

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

{% capture bob1 %}{% book_link "We Are Legion (We Are Bob)" %}{% endcapture %}
{% capture bob2 %}{% book_link "For We Are Many" %}{% endcapture %}
{% capture bob3 %}{% book_link "All These Worlds" %}{% endcapture %}
{% capture bob4 %}{% book_link "Heaven's River" %}{% endcapture %}

{% capture faulkner %}{% author_link "William Faulkner" link_text="Faulkner" %}{% endcapture %}

{% capture blindsight %}{% book_link "Blindsight" %}{% endcapture %}
{% capture echopraxia %}{% book_link "Echopraxia" %}{% endcapture %}

{{ this_book }} is a huge improvement over {{ bob4 }} because {{
the_authors_lastname }} went back to the rapid-fire, multiple  interweaving
storyline style he originated in {{ bob1 }}, {{ bob2 }}, and {{ bob3 }}. The
change in style was my biggest complaint about the last book, so it is good to
be back.

There were a lot of storylines, most interesting to me were:

- The creation of the Skippy AI, Thoth, and it's desperate escape. Is it a
  rogue AI bent on destruction, or just a prisoner escaping it's jailers? It
  helped the Bobs discover wormholes, but it has also outsmarted them at every
  turn like the transhumans manipulating the humans in {{ blindsight }} and {{
  echopraxia }}.

- The vanished Pan Galactic Federation and the tour of their worlds. It was
  great to see fantastic natural events like the antimatter fountain, the
  various abandoned worlds, and the annoying archivist AI. And I didn't see
  the end of the galaxy coming, even though in hindsight it was foreshadowed.

- The rise of FAITH and other anti-Bob, authoritarian parties. With the
  modern, second rise of fascism these parts of the story feel much closer to
  home. I'm looking forward to seeing how the Bobs handle saving the humans
  from the Nemesis galaxy when they don't want to be saved.

I've said before that I value not being able to predict the storyline before
it happens, but that {{ this_series }} doesn't bother me even though the
stories are simple. {{ the_author }} is getting a little better there.
Although I could predict the rough shape of some of the stories---the Skippy AI is
going to escape, the disappeared Federation

I enjoyed this book a lot. As I said to a friend when recommending {{
this_series }} recently: "It's not {{ faulkner }}, but it's a lot of fun". Fun
is what I come to this series for, and {{ this_book }} delivers. I'm waiting
patiently for the forthcoming sixth book in the series.
