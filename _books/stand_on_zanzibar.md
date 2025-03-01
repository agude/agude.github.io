---
date: 2025-03-01
title: Stand on Zanzibar
book_author: John Brunner
series: null
book_number: 1
rating: 2
image: /books/covers/stand_on_zanzibar.jpg
---

<cite class="book-title">{{ page.title }}</cite>, by <span
class="author-name">{{ page.book_author }}</span>, is a Hugo-winning, New Wave
science fiction novel that explores overpopulation, corporate power, and
societal collapse.

{% capture this_book %}<cite class="book-title">{{ page.title }}</cite>{% endcapture %}
{% capture the_author %}<span class="author-name">{{ page.book_author }}</span>{% endcapture %}
{% capture the_authors %}{% include author_link.html name=page.book_author possessive=true %}{% endcapture %}
{% capture the_author_link %}{% include author_link.html name=page.book_author %}{% endcapture %}

{% capture botns %}{% include series_link.html series="The Book of the New Sun" %}{% endcapture %}
{% capture make_room_make_room %}{% include book_link.html title="Make Room! Make Room!" %}{% endcapture %}
{% capture harry_harrisons %}{% include author_link.html name="Harry Harrison" possessive=true %}{% endcapture %}
{% capture the_population_bomb %}{% include book_link.html title="The Population Bomb" %}{% endcapture %}
{% capture paul_ehrlich %}{% include author_link.html name="Paul R. Ehrlich" %}{% endcapture %}
{% capture anne_ehrlichs %}{% include author_link.html name="Anne Howland Ehrlich" possessive=true %}{% endcapture %}
{% capture blindsight %}{% include book_link.html title="Blindsight" %}{% endcapture %}
{% capture peter_watts %}{% include author_link.html name="Peter Watts" %}{% endcapture %}
{% capture mission_of_gravity %}{% include book_link.html title="Mission of Gravity" %}{% endcapture %}
{% capture hal_clement %}{% include author_link.html name="Hal Clement" %}{% endcapture %}
{% capture gun_with_occasional_music %}{% include book_link.html title="Gun, with Occasional Music" %}{% endcapture %}
{% capture jonathan_lethem %}{% include author_link.html name="Jonathan Lethem" %}{% endcapture %}
{% capture nineteen_eighty_four %}{% include book_link.html title="1984" %}{% endcapture %}
{% capture george_orwell %}{% include author_link.html name="George Orwell" %}{% endcapture %}
{% capture brave_new_world %}{% include book_link.html title="Brave New World" %}{% endcapture %}
{% capture aldous_huxley %}{% include author_link.html name="Aldous Huxley" %}{% endcapture %}
{% capture mind_of_my_mind %}{% include book_link.html title="Mind of My Mind" %}{% endcapture %}
{% capture octavia_butlers %}{% include author_link.html name="Octavia E. Butler" possessive=true %}{% endcapture %}
{% capture the_claw_of_the_conciliator %}{% include book_link.html title="The Claw of the Conciliator" %}{% endcapture %}
{% capture gene_wolfe %}{% include author_link.html name="Gene Wolfe" %}{% endcapture %}
{% capture the_three_body_problem %}{% include book_link.html title="The Three-Body Problem" %}{% endcapture %}
{% capture liu_cixin %}{% include author_link.html name="Liu Cixin" %}{% endcapture %}
{% capture snow_crash %}{% include book_link.html title="Snow Crash" %}{% endcapture %}
{% capture neal_stephensons %}{% include author_link.html name="Neal Stephenson" possessive=true %}{% endcapture %}
{% capture greg_bear %}{% include author_link.html name="Greg Bear" %}{% endcapture %}

The plot, what little there is, follows Norman Niblock House---VP at the GT
mega-corporation[^scale]---and Donald Hogan---US spy---who share an apartment
in New York. House's side of the story involves a friendly take-over of the
African country of Beninia by GT, while Hogan's eventually involves
infiltrating the southeast Asian country of Yatakang. The book moves slowly,
with these plots only really starting 2/3s of the way in. They end abruptly
and in an almost too-cute cynical way: the solution to the world's problems
are found in Beninia, but the only man who could have implemented them was
killed just weeks before in Yatakang by Hogan.

{{ this_book }} feels incredibly dated. The main problem of overpopulation is
right out of the {{ paul_ehrlich }} and {{ anne_ehrlichs }} discredited {{
the_population_bomb }} and echos {{ harry_harrisons }} earlier {{
make_room_make_room }}. The decolonization of Africa in the 50s and 60s
clearly influenced the de- and recolonization storyline that take place in the
book. The war with Yatakang is the contemporary Vietnam War writ large.
Chad C. Mulligan, the reflexive contrarian cynic, doesn't feel like a wise
counter-culture observer, but instead like our current contrarian social media
grifters. With the second rise of fascism we're experiencing, {{
nineteen_eighty_four }}, written by {{ george_orwell }} in the shadow of the
Second World War, is the more relevant dystopia.

[^scale]:
    The scale of the company is hilariously wrong, with House and his
    coworkers panicking about a $40 million market cap drop, when today we
    have trillion dollar companies with far less power and influence than GT.

{{ this_book }} also suffers from the "Codder/Shiggy Problem".[^codder] {{
the_author }} invented a bunch of new slang for the novel, but it doesn't
sound natural. {{ gene_wolfe }} was able to insert hundreds of new words in {{
botns}} and all of them felt natural in part because he drew them from archaic
English instead of inventing them wholesale. {{ the_authors }} new words are
just jarring.

{{ this_book }} was _clearly_ influential among authors that came after.

- The use of monomolecular wire to slice a boat in half was later used by {{
  liu_cixin }} in {{ the_three_body_problem }}.
- The corporation buying an aircraft carrier to use as a floating city
  reminded me of {{ neal_stephensons }} {{ snow_crash }}.
- The insertion of in-universe stories about Begi remind me of the stories {{
  gene_wolfe }} tells into {{ the_claw_of_the_conciliator }}.
- The increasingly violent world remind me of {{ octavia_butlers }} {{
  mind_of_my_mind }}.

[^codder]:
    From egypturnash on Reddit, who said this while reviewing {{ this_book }}:

    > It [{{ this_book }}] is the origin of one of my personal terms for
    > Sci-Fi Problems: a story with "a case of the codder-shiggies" is a story
    > with awkward future slang that makes you cringe every time someone says
    > it.

    {% include cite.html
      author_last="egypturnash"
      title="Comment on 'Stand on Zanzibar'"
      publication_title="Reddit, r/PrintSF"
      date="2019-02-24"
      url="https://www.reddit.com/r/printSF/comments/au154p/stand_on_zanzibar/eh52zha/"
    %}
