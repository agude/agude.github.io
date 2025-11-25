---
date: 2025-11-24
title: The Darfsteller
book_authors: Walter M. Miller Jr.
book_number: 1
is_anthology: false
rating: null
image: /books/covers/the_darfsteller.jpg
awards:
  - hugo
---

<cite class="book-title">{{ page.title }}</cite>, by <span
class="author-name">{{ page.book_authors }}</span>, is a novelette about an
actor who is replaced by machines, and how he struggles to give up life in the
theater.

{% capture this_book %}<cite class="book-title">{{ page.title }}</cite>{% endcapture %}
{% capture the_author %}<span class="author-name">{{ page.book_authors }}</span>{% endcapture %}
{% capture the_authors %}<span class="author-name">{{ page.book_authors }}</span>'s{% endcapture %}
{% capture author_last_name_text %}Miller{% endcapture %}
{% capture the_authors_lastname %}<span class="author-name">Miller</span>{% endcapture %}
{% capture the_authors_lastname_possessive %}<span class="author-name">Miller</span>'s{% endcapture %}
{% capture the_author_link %}{% author_link page.book_authors %}{% endcapture %}
{% capture the_authors_link %}{% author_link page.book_authors possessive %}{% endcapture %}
{% capture the_authors_lastname_link %}{% author_link page.book_authors link_text=author_last_name_text %}{% endcapture %}
{% capture the_authors_lastname_possessive_link %}{% author_link page.book_authors link_text=author_last_name_text possessive %}{% endcapture %}

{% capture roald_dahl %}{% author_link "Roald Dahl" %}{% endcapture %}
{% capture roald_dahls %}{% author_link "Roald Dahl" possessive %}{% endcapture %}
{% capture dahl_lastname %}{% author_link "Roald Dahl" link_text="Dahl" %}{% endcapture %}
{% capture dahls_lastname %}{% author_link "Roald Dahl" possessive link_text="Dahl" %}{% endcapture %}
{% capture grammatizator %}{% short_story_link "The Great Automatic Grammatizator" from_book="Someone Like You" %}{% endcapture %}

{% capture fritz_leiber %}{% author_link "Fritz Leiber" %}{% endcapture %}
{% capture fritz_leibers %}{% author_link "Fritz Leiber" possessive %}{% endcapture %}
{% capture leiber_lastname %}{% author_link "Fritz Leiber" link_text="Leiber" %}{% endcapture %}
{% capture leibers_lastname %}{% author_link "Fritz Leiber" possessive link_text="Leiber" %}{% endcapture %}
{% capture the_silver_eggheads %}{% book_link "The Silver Eggheads" %}{% endcapture %}

{% capture stanislaw_lem %}{% author_link "Stanislaw Lem" %}{% endcapture %}
{% capture stanislaw_lems %}{% author_link "Stanislaw Lem" possessive %}{% endcapture %}
{% capture lem_lastname %}{% author_link "Stanislaw Lem" link_text="Lem" %}{% endcapture %}
{% capture lems_lastname %}{% author_link "Stanislaw Lem" possessive link_text="Lem" %}{% endcapture %}
{% capture the_cyberiad %}{% book_link "The Cyberiad" %}{% endcapture %}
{% capture trurls_electronic_bard %}{% short_story_link "Trurl's Electronic Bard" from_book="The Cyberiad" %}{% endcapture %}

{% capture jg_ballard %}{% author_link "J.G. Ballard" %}{% endcapture %}
{% capture jg_ballards %}{% author_link "J.G. Ballard" possessive %}{% endcapture %}
{% capture ballard_lastname %}{% author_link "J.G. Ballard" link_text="Ballard" %}{% endcapture %}
{% capture ballards_lastname %}{% author_link "J.G. Ballard" possessive link_text="Ballard" %}{% endcapture %}
{% capture studio_5_the_stars %}{% short_story_link "Studio 5, The Stars" from_book="Vermilion Sands" %}{% endcapture %}

{% capture kurt_vonnegut %}{% author_link "Kurt Vonnegut" %}{% endcapture %}
{% capture kurt_vonneguts %}{% author_link "Kurt Vonnegut" possessive %}{% endcapture %}
{% capture vonnegut_lastname %}{% author_link "Kurt Vonnegut" link_text="Vonnegut" %}{% endcapture %}
{% capture vonneguts_lastname %}{% author_link "Kurt Vonnegut" possessive link_text="Vonnegut" %}{% endcapture %}
{% capture player_piano %}{% book_link "Player Piano" %}{% endcapture %}

{{ this_book }} is named after the neologism "Darfsteller", which is probably
a portmanteau of the German words "Darsteller" for "actor" and "Darf" meaning
"allowed to". In the book it means roughly a method actor who must internalize
the role to play it and can't be given outside direction. It is paired against
the "Schauspieler", also a German word meaning roughly "actor", who is
directed how to act. It serves as a linguistic focus for main tension in the
plot: what role humans still have in art when a machine can do their job
better.

The main character, Ryan Thornier, is a former actor and now janitor at a
theater where robots have replaced all the human actors because the audience
prefers it. The AI Maestro that controls the performance tailors them to the
audience reaction and specifically in a way that doesn't challenge their
beliefs or make them think too hard.

[wiki]: https://en.wikipedia.org/wiki/The_Darfsteller

{{ this_book }} is interesting because it is one of the few works of science
fiction that envisions robots and AI taking over creative jobs, instead of
manual labor and logical/numeric work. It's an actuality that seems all the
more possible today with the rise of [generative AI][gen_ai], and the [push
back it is getting from artists][ai_art].

[gen_ai]: {% link topics/generative-ai.md %}
[ai_art]: {% post_url 2023-01-30-ai_artists_and_technology %}

{{ the_authors_lastname_possessive }} answer is: for commercial art, what
makes money is what will win. That no single person can fight against the
tide, and that they will each do what they think they need to to survive.
