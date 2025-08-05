---
date: 2025-07-31
title: Lords of Uncreation
book_authors: Adrian Tchaikovsky
series: The Final Architecture
book_number: 3
rating: 3
image: /books/covers/lords_of_uncreation.jpg
---

<cite class="book-title">{{ page.title }}</cite>, by <span
class="author-name">{{ page.book_authors }}</span>, is the third book in the
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

{% capture fa1 %}{% book_link "Shards of Earth" %}{% endcapture %}
{% capture fa2 %}{% book_link "Eyes of the Void" %}{% endcapture %}

{% capture borg %}<cite class="tv-show-title">Star Trek</cite>'s <cite class="tv-show-title">I, Borg</cite>{% endcapture %}

{% capture wells %}{% author_link "H. G. Wells" %}{% endcapture %}
{% capture war %}{% book_link "The War of the Worlds" %}{% endcapture %}

{% capture martines %}{% author_link "Arkady Martine" possessive %}{% endcapture %}
{% capture memory %}{% book_link "A Memory Called Empire" %}{% endcapture %}

{% capture vinges %}{% author_link "Vernor Vinge" possessive %}{% endcapture %}
{% capture fire %}{% book_link "A Fire Upon the Deep" %}{% endcapture %}

{% capture bankss %}{% author_link "Iain M. Banks" possessive %}{% endcapture %}
{% capture culture %}{% book_link "The Culture series" %}{% endcapture %}
{% capture surface %}{% book_link "Surface Detail" %}{% endcapture %}

{% capture bioshock %}<cite class="">BioShock</cite>{% endcapture %}

{% capture cards %}{% author_link "Orson Scott Card" possessive %}{% endcapture %}
{% capture ender %}{% book_link "Ender's Game" %}{% endcapture %}
{% capture speaker %}{% book_link "Speaker for the Dead" %}{% endcapture %}

{% capture hamiltons %}{% author_link "Peter F. Hamilton" possessive %}{% endcapture %}
{% capture judas %}{% book_link "Judas Unchained" %}{% endcapture %}

{% capture kurvitzs %}{% author_link "Robert Kurvitz" possessive %}{% endcapture %}
{% capture disco %}{% book_link "Disco Elysium" %}{% endcapture %}

{% capture benfords %}{% author_link "Gregory Benford" possessive %}{% endcapture %}
{% capture eater %}{% book_link "Eater" %}{% endcapture %}

{% capture clarkes %}{% author_link "Arthur C. Clarke" possessive %}{% endcapture %}
{% capture childhood %}{% book_link "Childhood's End" %}{% endcapture %}

{% capture baums %}{% author_link "L. Frank Baum" possessive %}{% endcapture %}
{% capture wizard %}{% book_link "The Wizard of Oz" %}{% endcapture %}

{% capture asimovs %}{% author_link "Isaac Asimov" possessive %}{% endcapture %}
{% capture last_question %}{% book_link "The Last Question" %}{% endcapture %}

{% capture adamss %}{% author_link "Douglas Adams" possessive %}{% endcapture %}
{% capture hitchhikers %}{% book_link "The Hitchhiker's Guide to the Galaxy" %}{% endcapture %}

{% capture picnic %}{% book_link "Roadside Picnic" %}{% endcapture %}
{% capture bolo11 %}{% book_link "The Unconquerable" %}{% endcapture %}
{% capture hyperion %}{% book_link "Hyperion" %}{% endcapture %}

The story of the {{ this_series }} has always been its main draw. {{ this_book
}} is my favorite of the series because it focuses the most on the story. The
writing has improved a little as well---I didn't find my self sigh or writing
down particularly bad sentences as I did with {{ fa1 }} and {{ fa2 }}---and
even my least favorite characters have some redemption.

But the book is far from perfect. It moves too slowly. A third of the book is
spent reigniting the human civil war when I was ready to instead face to
Originators. Idris has been reduced to whining about destroying the
Architects. His argument---that humanity shouldn't fight back---was more
interesting when I first saw it in works like {{ ender }}, {{ speaker }}, and {{
borg }}, but its is tiring now just as it was in {{ judas }}. Not every book
has to grapple with who the real bad guys are, sometimes it can just be the
guys committing genocide against humanity.

This book reminded me of a bunch of others:

- Like {{ martines }} {{ memory }}, territories in {{ this_book }} are defined
  as contagious via Throughways connections, not their actual location.
  Both the Parthenon and Teixcalaanli have a list they read off all those who
  died in combat.

- The giant Hegemonic ring around a star is like rings around Harmonious
  Repose in {{ vinges }} {{ fire }}.

- The human arks, where the rich plan to escape civilization with their
  underclass of servants, reminds me Rapture from {{ bioshock }}.

- Thinking as pollution that distorts space in like the Pale in {{ disco }}.

- The Architects as "thought and complex distortions in Unspace" are like
  Eater from {{ eater }}.

- When the originators project themselves into the Eye, they are seen by each
  viewer as something they're terrified of, which reminded my of how the
  Overlords look like Devils in {{ childhood }}. And the fact that they're
  bluffing reminds me of the euphonious wizards in {{ wizard }}.

- That the Originators attack Solace by telling her how insignificant she is
  reminds me of the Total Perspective Vortex in {{ hitchhikers }}.

- Solace's fighting only in her mind reminded me of the virtual War in Heaven
  from {{ surface }}. The Host being a ship loosely composed of scales
  reminded me of Culture ships being mostly fields.

- The Originators being refugees from a previous universe reminds me of {{
  last_question }}.

I'm glad to be done with {{ this_series }}. They had some interesting ideas,
but should have been shorter, more focused, and with a few more polish passes
on the writing. On next to {{ picnic }} and {{ bolo11 }}, before picking up {{
hyperion }} again for book club.
