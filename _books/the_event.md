---
date: 2026-08-04 17:58:19 -0700
title: The Event
book_authors: Henry Bean
series: null
book_number: 1
is_anthology: false
rating: 4
image: /books/covers/the_event.jpg
wikidata_qid: null
isbn: null
date_published: 2025-09
same_as_urls:
  - "https://jewishcurrents.org/the-event"
---

{% book_link page.title %}, by {% author_link page.book_authors link=false %},
is a short story about the destruction of Israel and Palestine, narrated by a
researcher who can barely keep his own life together.

{% capture this_book %}{% book_link page.title %}{% endcapture %}
{% capture the_author %}{% author_link page.book_authors link=false %}{% endcapture %}
{% capture the_authors %}{% author_link page.book_authors link=false possessive %}{% endcapture %}
{% capture author_last_name_text %}{{ page.book_authors | split: " " | last }}{% endcapture %}
{% capture the_authors_lastname %}{% author_link page.book_authors link=false link_text=author_last_name_text %}{% endcapture %}
{% capture the_authors_lastname_possessive %}{% author_link page.book_authors link=false link_text=author_last_name_text possessive %}{% endcapture %}
{% capture the_author_link %}{% author_link page.book_authors %}{% endcapture %}
{% capture the_authors_link %}{% author_link page.book_authors possessive %}{% endcapture %}
{% capture the_authors_lastname_link %}{% author_link page.book_authors link_text=author_last_name_text %}{% endcapture %}
{% capture the_authors_lastname_possessive_link %}{% author_link page.book_authors link_text=author_last_name_text possessive %}{% endcapture %}

{% capture fall %}{% author_link "Isabel Fall" %}{% endcapture %}
{% capture falls %}{% author_link "Isabel Fall" possessive %}{% endcapture %}
{% capture fall_lastname %}{% author_link "Isabel Fall" link_text="Fall" %}{% endcapture %}
{% capture falls_lastname %}{% author_link "Isabel Fall" link_text="Fall" possessive %}{% endcapture %}
{% capture i_sexually_identify_as_an_attack_helicopter %}{% book_link "I Sexually Identify as an Attack Helicopter" %}{% endcapture %}

{% capture arkady_strugatsky %}{% author_link "Arkady Strugatsky" %}{% endcapture %}
{% capture arkady_strugatskys %}{% author_link "Arkady Strugatsky" possessive %}{% endcapture %}
{% capture arkady_strugatsky_lastname %}{% author_link "Arkady Strugatsky" link_text="Strugatsky" %}{% endcapture %}
{% capture arkady_strugatskys_lastname %}{% author_link "Arkady Strugatsky" link_text="Strugatsky" possessive %}{% endcapture %}
{% capture boris_strugatsky %}{% author_link "Boris Strugatsky" %}{% endcapture %}
{% capture boris_strugatskys %}{% author_link "Boris Strugatsky" possessive %}{% endcapture %}
{% capture boris_strugatsky_lastname %}{% author_link "Boris Strugatsky" link_text="Strugatsky" %}{% endcapture %}
{% capture boris_strugatskys_lastname %}{% author_link "Boris Strugatsky" link_text="Strugatsky" possessive %}{% endcapture %}
{% capture arkady_and_boris %}{% author_link "Arkady Strugatsky" link_text="Arkady" %} and {% author_link "Boris Strugatsky" link_text="Boris" %}{% endcapture %}
{% capture arkady_and_boris_strugatskys %}{% author_link "Arkady Strugatsky" link_text="Arkady" %} and {% author_link "Boris Strugatsky" possessive %}{% endcapture %}
{% capture roadside_picnic %}{% book_link "Roadside Picnic" %}{% endcapture %}

{% capture danielewski %}{% author_link "Mark Z. Danielewski" %}{% endcapture %}
{% capture danielewskis %}{% author_link "Mark Z. Danielewski" possessive %}{% endcapture %}
{% capture danielewski_lastname %}{% author_link "Mark Z. Danielewski" link_text="Danielewski" %}{% endcapture %}
{% capture danielewskis_lastname %}{% author_link "Mark Z. Danielewski" link_text="Danielewski" possessive %}{% endcapture %}
{% capture house_of_leaves %}{% book_link "House of Leaves" %}{% endcapture %}

{% capture qntm %}{% author_link "qntm" %}{% endcapture %}
{% capture qntms %}{% author_link "qntm" possessive %}{% endcapture %}
{% capture lena %}{% short_story_link "Lena" %}{% endcapture %}
{% capture antimeme %}{% book_link "There Is No Antimemetics Division" %}{% endcapture %}

{% capture chiang %}{% author_link "Ted Chiang" %}{% endcapture %}
{% capture chiangs %}{% author_link "Ted Chiang" possessive %}{% endcapture %}
{% capture chiang_lastname %}{% author_link "Ted Chiang" link_text="Chiang" %}{% endcapture %}
{% capture chiangs_lastname %}{% author_link "Ted Chiang" link_text="Chiang" possessive %}{% endcapture %}
{% capture the_evolution_of_human_science %}{% short_story_link "The Evolution of Human Science" %}{% endcapture %}

{% capture faulkner %}{% author_link "William Faulkner" %}{% endcapture %}
{% capture faulkners %}{% author_link "William Faulkner" possessive %}{% endcapture %}
{% capture faulkner_lastname %}{% author_link "William Faulkner" link_text="Faulkner" %}{% endcapture %}
{% capture faulkners_lastname %}{% author_link "William Faulkner" link_text="Faulkner" possessive %}{% endcapture %}
{% capture absalom_absalom %}{% book_link "Absalom, Absalom!" %}{% endcapture %}

{{ this_book }} was written as a fake academic report published in [Jewish
Currents][the_event], about a supernatural fire that engulfed Israel and
Palestine. It explores how some topics can't be acknowledged or discussed:
they can only be approached indirectly. This is exactly the case with the
mystical fire. Little is known about it, people are starting to forget it, and
even subconsciously avert their gaze when near. The theme plays out at
multiple scales: from satellites going blind, to the armies of Egypt crossing
into the fire, unaware that the troops ahead of them have been incinerated.
The narrator has the same problem with his life, unable to face his own
failures and the people he's hurt; it slowly leaks into his report. And the
story itself, of course, is a way to address the [Israeli--Palestinian
conflict][ip] obliquely.

[the_event]: https://jewishcurrents.org/the-event
[ip]: https://en.wikipedia.org/wiki/Israeli%E2%80%93Palestinian_conflict

I enjoyed how the structure of the story reinforces the theme. It starts as a
dry academic report complete with citations. But the footnotes, which start
out academic, soon begin revealing the failures of the narrator's life: his
failed marriage, how he called his Jewish ex-wife at 1:30 AM, and then trying
to take it back by stating it's all irrelevant. By the end, the report itself
is more about him than the research. The story is a mix of {{
danielewskis_lastname }} {{ house_of_leaves }}, which uses footnotes to tell a
parallel story, and {{ qntms }} {{ lena }} and {{ chiangs_lastname }} {{
the_evolution_of_human_science }}, which use dry formatting to heighten the
emotional content of the prose.

{{ this_book }} is similar to {{ arkady_and_boris_strugatskys }} {{
roadside_picnic }}; both have a mysterious zone that humanity is trying, and
failing, to understand. Using fiction to approach a nearly taboo subject is
the same thing {{ fall_lastname }} does with gender in {{
i_sexually_identify_as_an_attack_helicopter }}. And the way people can't quite
comprehend the zone, going so far as to literally not look at it, reminds me
of the antimemes from {{ qntms }} {{ antimeme }}.

{{ the_author }} does a great job of fitting so much into this short
story---politics, grief, the narrator's self-destruction---all without really
focusing on it. It is [free to read][the_event], I recommend giving it a shot.
