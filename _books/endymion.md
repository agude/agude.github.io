---
date: 2026-01-19
title: Endymion
book_authors: Dan Simmons
series: Hyperion Cantos
book_number: 3
rating: 4
image: /books/covers/endymion.jpg
---

<cite class="book-title">{{ page.title }}</cite>, by <span
class="author-name">{{ page.book_authors }}</span>, is the third book in the
<span class="book-series">{{ page.series }}</span> series. It follows a
completely new cast of characters---Aenea, Rual, Bettik---as the escape the
oppresive Pax using a Raft and the River Tethys.

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

{% comment %} Dan Simmons {% endcomment %}
{% capture simmons %}{% author_link "Dan Simmons" %}{% endcapture %}
{% capture simmonss %}{% author_link "Dan Simmons" possessive %}{% endcapture %}
{% capture simmons_lastname %}{% author_link "Dan Simmons" link_text="Simmons" %}{% endcapture %}
{% capture simmonss_lastname %}{% author_link "Dan Simmons" link_text="Simmons" possessive %}{% endcapture %}
{% capture endymion %}{% book_link "Endymion" %}{% endcapture %}
{% capture hyperion %}{% book_link "Hyperion" %}{% endcapture %}
{% capture fall_hyperion %}{% book_link "The Fall of Hyperion" %}{% endcapture %}
{% capture rise_of_endymion %}{% book_link "The Rise of Endymion" %}{% endcapture %}

{% comment %} Iain M. Banks {% endcomment %}
{% capture banks %}{% author_link "Iain M. Banks" %}{% endcapture %}
{% capture bankss %}{% author_link "Iain M. Banks" possessive %}{% endcapture %}
{% capture banks_lastname %}{% author_link "Iain M. Banks" link_text="Banks" %}{% endcapture %}
{% capture bankss_lastname %}{% author_link "Iain M. Banks" link_text="Banks" possessive %}{% endcapture %}
{% capture consider_phlebas %}{% book_link "Consider Phlebas" %}{% endcapture %}

{% comment %} Mark Twain {% endcomment %}
{% capture twain %}{% author_link "Mark Twain" %}{% endcapture %}
{% capture twains %}{% author_link "Mark Twain" possessive %}{% endcapture %}
{% capture twain_lastname %}{% author_link "Mark Twain" link_text="Twain" %}{% endcapture %}
{% capture twains_lastname %}{% author_link "Mark Twain" link_text="Twain" possessive %}{% endcapture %}
{% capture huck_finn %}{% book_link "Adventures of Huckleberry Finn" %}{% endcapture %}

{% comment %} L. Frank Baum {% endcomment %}
{% capture baum %}{% author_link "L. Frank Baum" %}{% endcapture %}
{% capture baums %}{% author_link "L. Frank Baum" possessive %}{% endcapture %}
{% capture baum_lastname %}{% author_link "L. Frank Baum" link_text="Baum" %}{% endcapture %}
{% capture baums_lastname %}{% author_link "L. Frank Baum" link_text="Baum" possessive %}{% endcapture %}
{% capture wizard_of_oz %}{% book_link "The Wonderful Wizard of Oz" %}{% endcapture %}

{% comment %} Gene Wolfe {% endcomment %}
{% capture wolfe %}{% author_link "Gene Wolfe" %}{% endcapture %}
{% capture wolfes %}{% author_link "Gene Wolfe" possessive %}{% endcapture %}
{% capture wolfe_lastname %}{% author_link "Gene Wolfe" link_text="Wolfe" %}{% endcapture %}
{% capture wolfes_lastname %}{% author_link "Gene Wolfe" link_text="Wolfe" possessive %}{% endcapture %}
{% capture botns %}{% series_link "The Book of the New Sun" %}{% endcapture %}
{% capture shadow_torturer %}{% book_link "The Shadow of the Torturer" %}{% endcapture %}

{% comment %} Peter F. Hamilton {% endcomment %}
{% capture hamilton %}{% author_link "Peter F. Hamilton" %}{% endcapture %}
{% capture hamiltons %}{% author_link "Peter F. Hamilton" possessive %}{% endcapture %}
{% capture hamilton_lastname %}{% author_link "Peter F. Hamilton" link_text="Hamilton" %}{% endcapture %}
{% capture hamiltons_lastname %}{% author_link "Peter F. Hamilton" link_text="Hamilton" possessive %}{% endcapture %}
{% capture abyss_beyond_dreams %}{% book_link "The Abyss Beyond Dreams" %}{% endcapture %}
{% capture pandoras_star %}{% book_link "Pandora's Star" %}{% endcapture %}
{% capture judas_unchained %}{% book_link "Judas Unchained" %}{% endcapture %}

{% comment %} Margaret Atwood {% endcomment %}
{% capture atwood %}{% author_link "Margaret Atwood" %}{% endcapture %}
{% capture atwoods %}{% author_link "Margaret Atwood" possessive %}{% endcapture %}
{% capture atwood_lastname %}{% author_link "Margaret Atwood" link_text="Atwood" %}{% endcapture %}
{% capture atwoods_lastname %}{% author_link "Margaret Atwood" link_text="Atwood" possessive %}{% endcapture %}
{% capture handmaids_tale %}{% book_link "The Handmaid's Tale" %}{% endcapture %}

{% comment %} Frank Herbert {% endcomment %}
{% capture herbert %}{% author_link "Frank Herbert" %}{% endcapture %}
{% capture herberts %}{% author_link "Frank Herbert" possessive %}{% endcapture %}
{% capture herbert_lastname %}{% author_link "Frank Herbert" link_text="Herbert" %}{% endcapture %}
{% capture herberts_lastname %}{% author_link "Frank Herbert" link_text="Herbert" possessive %}{% endcapture %}
{% capture dune %}{% book_link "Dune" %}{% endcapture %}

{% comment %} Vladimir Nabokov {% endcomment %}
{% capture nabokov %}{% author_link "Vladimir Nabokov" %}{% endcapture %}
{% capture nabokovs %}{% author_link "Vladimir Nabokov" possessive %}{% endcapture %}
{% capture nabokov_lastname %}{% author_link "Vladimir Nabokov" link_text="Nabokov" %}{% endcapture %}
{% capture nabokovs_lastname %}{% author_link "Vladimir Nabokov" link_text="Nabokov" possessive %}{% endcapture %}
{% capture lolita %}{% book_link "Lolita" %}{% endcapture %}

{% comment %} Robert A. Heinlein {% endcomment %}
{% capture heinlein %}{% author_link "Robert A. Heinlein" %}{% endcapture %}
{% capture heinleins %}{% author_link "Robert A. Heinlein" possessive %}{% endcapture %}
{% capture heinlein_lastname %}{% author_link "Robert A. Heinlein" link_text="Heinlein" %}{% endcapture %}
{% capture heinleins_lastname %}{% author_link "Robert A. Heinlein" link_text="Heinlein" possessive %}{% endcapture %}
{% capture starship_troopers %}{% book_link "Starship Troopers" %}{% endcapture %}

{% comment %} Adrian Tchaikovsky {% endcomment %}
{% capture tchaikovsky %}{% author_link "Adrian Tchaikovsky" %}{% endcapture %}
{% capture tchaikovskys %}{% author_link "Adrian Tchaikovsky" possessive %}{% endcapture %}
{% capture tchaikovsky_lastname %}{% author_link "Adrian Tchaikovsky" link_text="Tchaikovsky" %}{% endcapture %}
{% capture tchaikovskys_lastname %}{% author_link "Adrian Tchaikovsky" link_text="Tchaikovsky" possessive %}{% endcapture %}
{% capture final_architecture %}{% series_link "The Final Architecture" %}{% endcapture %}

{% comment %} Isaac Asimov {% endcomment %}
{% capture asimov %}{% author_link "Isaac Asimov" %}{% endcapture %}
{% capture asimovs %}{% author_link "Isaac Asimov" possessive %}{% endcapture %}
{% capture asimov_lastname %}{% author_link "Isaac Asimov" link_text="Asimov" %}{% endcapture %}
{% capture asimovs_lastname %}{% author_link "Isaac Asimov" link_text="Asimov" possessive %}{% endcapture %}
{% capture i_robot %}{% book_link "I, Robot" %}{% endcapture %}

{% comment %} Jane Langton {% endcomment %}
{% capture langton %}{% author_link "Jane Langton" %}{% endcapture %}
{% capture langtons %}{% author_link "Jane Langton" possessive %}{% endcapture %}
{% capture langton_lastname %}{% author_link "Jane Langton" link_text="Langton" %}{% endcapture %}
{% capture langtons_lastname %}{% author_link "Jane Langton" link_text="Langton" possessive %}{% endcapture %}
{% capture diamond_window %}{% book_link "The Diamond in the Window" %}{% endcapture %}

{% comment %} John Brunner {% endcomment %}
{% capture brunner %}{% author_link "John Brunner" %}{% endcapture %}
{% capture brunners %}{% author_link "John Brunner" possessive %}{% endcapture %}
{% capture brunner_lastname %}{% author_link "John Brunner" link_text="Brunner" %}{% endcapture %}
{% capture brunners_lastname %}{% author_link "John Brunner" link_text="Brunner" possessive %}{% endcapture %}
{% capture stand_on_zanzibar %}{% book_link "Stand on Zanzibar" %}{% endcapture %}

{% comment %} Cixin Liu {% endcomment %}
{% capture liu %}{% author_link "Cixin Liu" %}{% endcapture %}
{% capture lius %}{% author_link "Cixin Liu" possessive %}{% endcapture %}
{% capture liu_lastname %}{% author_link "Cixin Liu" link_text="Liu" %}{% endcapture %}
{% capture lius_lastname %}{% author_link "Cixin Liu" link_text="Liu" possessive %}{% endcapture %}
{% capture three_body %}{% book_link "The Three-Body Problem" %}{% endcapture %}

{% comment %} Amal El-Mohtar & Max Gladstone {% endcomment %}
{% capture el_mohtar %}{% author_link "Amal El-Mohtar" %}{% endcapture %}
{% capture el_mohtars %}{% author_link "Amal El-Mohtar" possessive %}{% endcapture %}
{% capture el_mohtar_lastname %}{% author_link "Amal El-Mohtar" link_text="El-Mohtar" %}{% endcapture %}
{% capture el_mohtars_lastname %}{% author_link "Amal El-Mohtar" link_text="El-Mohtar" possessive %}{% endcapture %}

{% capture gladstone %}{% author_link "Max Gladstone" %}{% endcapture %}
{% capture gladstones %}{% author_link "Max Gladstone" possessive %}{% endcapture %}
{% capture gladstone_lastname %}{% author_link "Max Gladstone" link_text="Gladstone" %}{% endcapture %}
{% capture gladstones_lastname %}{% author_link "Max Gladstone" link_text="Gladstone" possessive %}{% endcapture %}

{% capture el_mohtar_and_gladstone %}{% author_link "Amal El-Mohtar" %} and {% author_link "Max Gladstone" %}{% endcapture %}
{% capture time_war %}{% book_link "This Is How You Lose the Time War" %}{% endcapture %}

{% comment %} Kurt Vonnegut {% endcomment %}
{% capture vonnegut %}{% author_link "Kurt Vonnegut" %}{% endcapture %}
{% capture vonneguts %}{% author_link "Kurt Vonnegut" possessive %}{% endcapture %}
{% capture vonnegut_lastname %}{% author_link "Kurt Vonnegut" link_text="Vonnegut" %}{% endcapture %}
{% capture vonneguts_lastname %}{% author_link "Kurt Vonnegut" link_text="Vonnegut" possessive %}{% endcapture %}
{% capture sirens_of_titan %}{% book_link "The Sirens of Titan" %}{% endcapture %}

{% capture alexs_lastname %}{% author_link "A. N. Alex" link_text="Alex" possessive %}{% endcapture %}
{% capture mote %}{% book_link "A Mote In Shadow" %}{% endcapture %}

{% comment %} John Keats {% endcomment %}
{% capture keats %}{% author_link "John Keats" %}{% endcapture %}
{% capture keatss %}{% author_link "John Keats" possessive %}{% endcapture %}
{% capture keats_lastname %}{% author_link "John Keats" link_text="Keats" %}{% endcapture %}
{% capture keatss_lastname %}{% author_link "John Keats" link_text="Keats" possessive %}{% endcapture %}
{% capture hyperion_keats %}{% book_link "Hyperion" author="John Keats" cite=false link_text="version" %}{% endcapture %}
{% capture fall_keats %}{% book_link "The Fall of Hyperion" author="John Keats" cite=false link_text="the poem" %}{% endcapture %}
{% capture endymion_keats %}{% book_link "Endymion" author="John Keats" cite=false link_text="poem" %}{% endcapture %}
{% capture endymion_keats_name %}{% book_link "Endymion" author="John Keats" %}{% endcapture %}
{% capture keatss_lastname_endymion %}{{ keatss_lastname }} {{ endymion_keats_name }}{% endcapture %}

{% comment %} Other Media {% endcomment %}
{% capture terminator_2 %}<cite class="movie-title">Terminator 2: Judgment Day</cite>{% endcapture %}
{% capture empire_strikes_back %}<cite class="movie-title">The Empire Strikes Back</cite>{% endcapture %}

{{ hyperion }} followed the themes and plot of {{ keatss }} {{ hyperion_keats
}}, and {{ fall_hyperion }} likewise followed {{ fall_keats }} by {{
keats_lastname }}. So it's no surprise that {{ this_book }} is _also_ based on
a {{ keats_lastname }} {{ endymion_keats }}. {{ keatss_lastname_endymion }} is
the story of the shepherd Endymion who falls in love with the moon goddess
Cynthia.

<!-- TODO clean this up, it's just raw notes now basically -->
One of the main themes of {{ keatss_lastname_endymion }} is the pairing of the
mortal and immortal, the earthly and the divine. We see these pairings in {{
this_book }} as well. Aenea is a messianic figure, a mix of humanity and the
divine. The Pax have given up on the divine and instead turned to technology
to grant immortality through the crucifix parasite instead of true spiritual
immortality through evolving towards god. Just as in {{ hyperion }} and {{
fall_hyperion }}, things must "die into life", and the Pax has refused death.

{{ this_book }} follows the structure of Endymion's journey in the {{
endymion_keats }}, with Raul visiting the underworld (ice cave of Sol Draconi
Septem), ocean floor (Mare Infinitus), and meeting [Glaucus][glaucus]. But it
is influenced by other literature as well. The journey as a voyage on a raft
is from {{ twains }} {{ huck_finn }}, with the formerly enslaved android
Bettik standing in as a Jim figure. {{ simmons_lastname }}, as he has done
through the whole series, also likens his characters to those from {{
baums_lastname }} {{ wizard_of_oz }}.

[glaucus]: https://en.wikipedia.org/wiki/Glaucus

There was a lot I enjoyed in {{ this_book }}. The nominal antagonist, Federico
de Soya, is sympathetic even as he tries to capture the heroes. His slow
realization that the Pax isn't the salvation of humanity he thought it was is
haunting. The pacing, once the real antagonist---Rhadamanth Nemes---is
revealed is perfect. I couldn't stop turning the pages. The additional
worldbuilding, how the universe has changed in 300 years, is also really
interesting, especially how humanity reacts to true resurrection, and the
horrifying technology it enables. The freed Android Bettik is another great
character, searching for his family, unwaveringly loyal and competent, and
unfortunately underutilized.

But for all that, this book is good, but not great. The pacing is too slow:
Nemes wasn't even introduced until the last quarter. Raul and Aenea as
annoying: Raul because he spends most of the narrative passive, and then
screws things up when he acts. Aenea because she is supposed to be a mix of
immature 12 year old and all-knowing messiah, but instead comes off
inconsistent. She keeps talking about how they will someday be lovers which is
weird given how young she is, and so {{ simmons_lastname }} has to keep
throwing in awkward narrator notes reminding us the Raul is not a pedophile
and doesn't find her attractive. At the same time, {{ simmons_lastname }}
makes winking allusions to {{ nabokov }} and {{ lolita }}.

{{ this_book }} reminded me of many others. Raul's narration as a written
story of his life reminded me of Severian's narration in {{ wolfes_lastname }}
{{ botns }}. The Schrödinger's Cat Box execution method reminds me of the
unorthodox execution method used on Horza in {{ bankss_lastname }} {{
consider_phlebas }}. The Pax remind me of Gilead from {{ atwoods_lastname }}
{{ handmaids_tale }}, their ban on AI is similar to {{ herberts_lastname }} {{
dune }}, and the Swiss Guard in their power armor at like the Mobile Infantry
{{ heinleins_lastname }} {{ starship_troopers }}. I appreciated that Androids
have "Asimotivation", modeled after {{ asimovs_lastname }} Three Laws from {{
i_robot }}. The journey on the river felt like Ozzy's trip in {{ pandoras_star
}} and {{ judas_unchained }}. The A. and M. honorifics to indicate species
reminds me of the hand gestures to indicate pronouns in {{ alexs_lastname }}
{{ mote }}. Being trapped in the ice cave reminded me of being trapped in the
nautilus in {{ langtons_lastname }} {{ diamond_window }}.

I was tempted to take a break but instead I picked up {{ rise_of_endymion }}
immediately after finishing. I'm a few chapters into it as I write this review
and I can already tell it's going to be a struggle. Wish me luck!
