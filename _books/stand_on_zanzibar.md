---
date: 2025-03-01
title: Stand on Zanzibar
book_author: John Brunner
series: null
book_number: 1
rating: 2
image: /books/covers/stand_on_zanzibar.jpg
awards:
  - hugo
---

<cite class="book-title">{{ page.title }}</cite>, by <span
class="author-name">{{ page.book_author }}</span>, is a Hugo-winning, New Wave
science fiction novel that explores overpopulation, corporate power, and
societal collapse.

{% capture this_book %}<cite class="book-title">{{ page.title }}</cite>{% endcapture %}
{% capture the_author %}<span class="author-name">{{ page.book_author }}</span>{% endcapture %}
{% capture the_authors %}{% author_link page.book_author possessive %}{% endcapture %}
{% capture the_author_link %}{% author_link page.book_author %}{% endcapture %}

{% capture botns %}{% series_link "The Book of the New Sun" %}{% endcapture %}
{% capture make_room_make_room %}{% book_link "Make Room! Make Room!" %}{% endcapture %}
{% capture harry_harrisons %}{% author_link "Harry Harrison" possessive %}{% endcapture %}
{% capture the_population_bomb %}{% book_link "The Population Bomb" %}{% endcapture %}
{% capture paul_ehrlich %}{% author_link "Paul R. Ehrlich" %}{% endcapture %}
{% capture anne_ehrlich %}{% author_link "Anne Howland Ehrlich" %}{% endcapture %}
{% capture blindsight %}{% book_link "Blindsight" %}{% endcapture %}
{% capture peter_watts %}{% author_link "Peter Watts" %}{% endcapture %}
{% capture mission_of_gravity %}{% book_link "Mission of Gravity" %}{% endcapture %}
{% capture hal_clement %}{% author_link "Hal Clement" %}{% endcapture %}
{% capture gun_with_occasional_music %}{% book_link "Gun, with Occasional Music" %}{% endcapture %}
{% capture jonathan_lethem %}{% author_link "Jonathan Lethem" %}{% endcapture %}
{% capture nineteen_eighty_four %}{% book_link "1984" %}{% endcapture %}
{% capture george_orwell %}{% author_link "George Orwell" %}{% endcapture %}
{% capture brave_new_world %}{% book_link "Brave New World" %}{% endcapture %}
{% capture aldous_huxley %}{% author_link "Aldous Huxley" %}{% endcapture %}
{% capture mind_of_my_mind %}{% book_link "Mind of My Mind" %}{% endcapture %}
{% capture octavia_butlers %}{% author_link "Octavia E. Butler" possessive %}{% endcapture %}
{% capture the_claw_of_the_conciliator %}{% book_link "The Claw of the Conciliator" %}{% endcapture %}
{% capture gene_wolfe %}{% author_link "Gene Wolfe" %}{% endcapture %}
{% capture the_three_body_problem %}{% book_link "The Three-Body Problem" %}{% endcapture %}
{% capture liu_cixin %}{% author_link "Liu Cixin" %}{% endcapture %}
{% capture snow_crash %}{% book_link "Snow Crash" %}{% endcapture %}
{% capture neal_stephensons %}{% author_link "Neal Stephenson" possessive %}{% endcapture %}
{% capture greg_bear %}{% author_link "Greg Bear" %}{% endcapture %}

The plot, what little there is, follows Norman Niblock House---VP at the GT
mega-corporation[^scale]---and Donald Hogan---a US spy---who share an
apartment in New York. House's storyline involves a friendly takeover of the
African country of Beninia by GT, while Hogan's involves him infiltrating the
southeast Asian nation of Yatakang. The book moves slowly, with these
plotlines only starting about two-thirds of the way through. They end abruptly
and in an almost too-cute, cynical manner: the solution to the world's
problems is discovered in Beninia, yet the only man capable of implementing it
was killed just weeks earlier in Yatakang by Hogan.

{{ this_book }} feels incredibly dated. The issue of overpopulation is lifted
straight from the discredited {{ the_population_bomb }} by {{ paul_ehrlich }}
and {{ anne_ehrlich }}, and it echoes {{ harry_harrisons }} earlier {{
make_room_make_room }}. The decolonization of Africa in the 50s and 60s
clearly influenced the book's de- and recolonization storyline. The war with
Yatakang is the contemporary Vietnam War writ large. Chad C. Mulligan, the
reflexive cynic, doesn't seem like a wise counter-culture observer but rather
resembles today's contrarian social media grifters. With the second rise of
fascism we're experiencing in the world, {{ nineteen_eighty_four }}, written
by {{ george_orwell }} in the shadow of World War II, is the more relevant
dystopia.

[^scale]:
    The scale of the company is hilariously off, with House and his coworkers
    panicking over a $40 million market cap drop, when today we see
    trillion-dollar companies with far less power and influence than GT.

{{ this_book }} also suffers from the "Codder/Shiggy Problem".[^codder] {{
the_author }} invented a bunch of new slang for the novel, but it never sounds
natural. {{ gene_wolfe }} was able to insert hundreds of new words in {{ botns
}}, and they all felt natural---partly because he drew them from archaic
English instead of inventing them from scratch. The new words coined by {{
the_author }} are just jarring.

One thing I enjoyed in the novel was the inclusion of the "Context", "The
Happening World", and "Tracking With Closeup" chapters, which flesh out the
setting with side-stories, characters, and bits of in-world media. However,
because the main narrative is sparse and slow-moving, these extra chapters
only serve to drag down the pace even further. Getting through {{ this_book }}
was a slog.

{{ this_book }} was _clearly_ influential among the authors and media that
followed it:

- The use of monomolecular wire to slice a boat in half was later adopted by
  {{ liu_cixin }} in {{ the_three_body_problem }}.

- The idea of a corporation buying an aircraft carrier to use as a floating
  city reminded me of {{ neal_stephensons }} {{ snow_crash }}.

- The insertion of in-universe stories about Begi reminds me of the narratives
  {{ gene_wolfe }} weaves into {{ the_claw_of_the_conciliator }}.

- The increasingly violent world reminds me of {{ octavia_butlers }} {{
  mind_of_my_mind }}.

- The ideas of identity, mind, and consciousness explored through Hogan's
  reprogramming and the supercomputer Shalmaneser are further developed in {{
  blindsight }} by {{ peter_watts }}. Both works feature a "synthesist" who
  pieces together and interprets disjointed facts.

- The riot and sweep-trucks equipped with plows appear in the movie <cite
  class="movie-title">Soylent Green</cite>---which are absent from {{
  make_room_make_room }}.

[^codder]:
    From egypturnash on Reddit, who said this while reviewing {{ this_book }}:

    > It [{{ this_book }}] is the origin of one of my personal terms for
    > Sci-Fi Problems: a story with "a case of the codder-shiggies" is a story
    > with awkward future slang that makes you cringe every time someone says
    > it.

    {% include cite.html
      author_handle="egypturnash"
      title="Comment on 'Stand on Zanzibar'"
      publication_title="Reddit, r/PrintSF"
      date="2019-02-24"
      url="https://www.reddit.com/r/printSF/comments/au154p/stand_on_zanzibar/eh52zha/"
    %}
