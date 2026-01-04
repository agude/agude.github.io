---
date: 2025-12-30
title: The Fall of Hyperion
book_authors: Dan Simmons
series: Hyperion Cantos
book_number: 2
rating: 5
image: /books/covers/the_fall_of_hyperion.jpg
awards:
  - locus
---

<cite class="book-title">{{ page.title }}</cite>, by <span
class="author-name">{{ page.book_authors }}</span>, is the second book in the
<span class="book-series">{{ page.series }}</span>, but really it's the second
half of {% book_link "Hyperion" %}. It brings the seven pilgrims' story to an
end and depicts the war between the TechnoCore, the Ousters, and the Hegemony.

{% capture this_book %}<cite class="book-title">{{ page.title }}</cite>{% endcapture %}
{% capture the_authors_lastname %}<span class="author-name">{{ page.book_authors | split: " " | last }}</span>{% endcapture %}
{% capture the_authors_lastname_possessive %}<span class="author-name">{{ page.book_authors | split: " " | last }}</span>'s{% endcapture %}
{% capture this_series %}{% series_text page.series %}{% endcapture %}

{% capture hyperion %}{% book_link "Hyperion" %}{% endcapture %}
{% capture endymion %}{% book_link "Endymion" %}{% endcapture %}
{% capture rise_of_endymion %}{% book_link "The Rise of Endymion" %}{% endcapture %}

{% capture keatss %}{% author_link "John Keats" possessive %}{% endcapture %}
{% capture keats_lastname %}{% author_link "Keats" %}{% endcapture %}
{% capture keatss_lastname %}{% author_link "Keats" possessive %}{% endcapture %}
{% capture poem %}{% book_link "The Fall of Hyperion: A Dream" %}{% endcapture %}
{% capture hyperion_keats %}{% book_link "Hyperion" author="John Keats" %}{% endcapture %}

{% capture bankss_lastname %}{% author_link "Iain M. Banks" possessive link_text="Banks" %}{% endcapture %}
{% capture the_player_of_games %}{% book_link "The Player of Games" %}{% endcapture %}
{% capture surface_detail %}{% book_link "Surface Detail" %}{% endcapture %}

{% capture herberts_lastname %}{% author_link "Frank Herbert" possessive link_text="Herbert" %}{% endcapture %}
{% capture dune %}{% series_link "Dune" %}{% endcapture %}

{% capture tolkiens_lastname %}{% author_link "J. R. R. Tolkien" possessive link_text="Tolkien" %}{% endcapture %}
{% capture lotr %}{% series_link "The Lord of the Rings" %}{% endcapture %}

{% capture el_mohtar_and_gladstones %}{% author_link "Amal El-Mohtar" link_text="El-Mohtar"%} and {% author_link "Max Gladstone" link_text="Gladstone" possessive %}{% endcapture %}
{% capture this_is_how_you_lose_the_time_war %}{% book_link "This Is How You Lose the Time War" %}{% endcapture %}

{% capture vonneguts_lastname %}{% author_link "Kurt Vonnegut" possessive link_text="Vonnegut" %}{% endcapture %}
{% capture the_sirens_of_titan %}{% book_link "The Sirens of Titan" %}{% endcapture %}

{% capture taylor_lastname %}{% author_link "Dennis E. Taylor" link_text="Taylor" %}{% endcapture %}
{% capture lost %}{% book_link "Not Till We Are Lost" %}{% endcapture %}

{% capture webers_lastname %}{% author_link "David Weber" possessive link_text="Weber" %}{% endcapture %}
{% capture basilisk %}{% book_link "On Basilisk Station" %}{% endcapture %}

{% capture asimovs_lastname %}{% author_link "Isaac Asimov" possessive link_text="Asimov" %}{% endcapture %}
{% capture i_robot %}{% book_link "I, Robot" %}{% endcapture %}

{% capture wolfes_lastname %}{% author_link "Gene Wolfe" possessive link_text="Wolfe" %}{% endcapture %}
{% capture botns %}{% series_link "The Book of the New Sun" %}{% endcapture %}
{% capture urth %}{% book_link "The Urth of the New Sun" %}{% endcapture %}

{% capture moore_and_gibbonss %}{% author_link "Alan Moore" link_text="Moore" %} and {% author_link "Dave Gibbons" link_text="Gibbons" possessive %}{% endcapture %}
{% capture watchmen %}{% book_link "Watchmen" %}{% endcapture %}

I loved {{ this_book }} when I [first read it][first_read], even more so than
{{ hyperion }}, because it tells a much simpler story. It has space battles,
the Soldier fighting the Shrike, and answers to every mystery. It doesn't
require the kind of close reading that the first one does to really enjoy it.

[first_read]: {% link _books/the_fall_of_hyperion/review-2023-10-27.md %}

On this second read-through, I recognized {{ hyperion }} for the epic
masterpiece it is, on the same level as {{ wolfes_lastname }} {{ botns }}, {{
herberts_lastname }} {{ dune }}, or {{ tolkiens_lastname }} {{ lotr }}. My
opinion of {{ this_book }} didn't change. It's still great, but it didn't
reveal the same level of hidden depth.

### Themes

{{ this_book }} follows the themes and structure of its namesake, {{ keatss }}
{{ poem }}. Just as the narrator of the poem falls asleep and dreams of the
aftermath of the [Titanomachy][titanomachy], the cybrid Joseph Severn dreams
of the fall of the Hegemony from a distance.

[titanomachy]: https://en.wikipedia.org/wiki/Titanomachy

The character Moneta takes her role directly from the poem. In {{
keatss_lastname }} poem, she is the living archive of the war and the guardian
of the altar. In {{ the_authors_lastname_possessive }} book, she is the
survivor of a war in the far future who brings the memory of it back in time.
In the poem, she points out the difference between a dreamer and a poet: the
dreamer observes the world but does not act, while the poet uses empathy to
provide meaning and heal the world.

The central thesis of {{ this_book }}, that suffering is necessary for
enlightenment, comes directly from {{ keatss_lastname }} poem:

<figure>
  <blockquote cite="https://en.wikisource.org/wiki/The_Poetical_Works_of_John_Keats/An_Earlier_Version_of_%22Hyperion%22">
    <p>
    "None can usurp this height," returned that shade,<br>
    "But those to whom the miseries of the world<br>
    Are misery, and will not let them rest.<br>
    All else who find a heaven in the world,<br>
    Where they may thoughtless sleep away their days,<br>
    If by a chance into this fane they come,<br>
    Rot on the pavement where thou rottedst half."
    </p>
  </blockquote>
  <figcaption>
    <small>&mdash;{% citation
      author_first="John"
      author_last="Keats"
      work_title="An Earlier Version of 'Hyperion'"
      container_title="The Poetical Works of John Keats"
      publisher="DeWolfe, Fiske & Company"
      date=1884
      page=281
      url="https://en.wikisource.org/wiki/The_Poetical_Works_of_John_Keats/An_Earlier_Version_of_%22Hyperion%22"
    %}</small>
  </figcaption>
</figure>

{{ the_authors_lastname }} applies this idea to civilization itself. The
Hegemony is stagnant because the TechnoCore has made life too easy. This is
juxtaposed against the Ousters, who rejected the TechnoCore's gifts and have
flourished as the true heirs of humanity.

This requirement for suffering determines the outcome of the war in heaven as
well. Through Father Paul Duré, {{ the_authors_lastname }} casts the war as a
race to [Pierre Teilhard de Chardin's][ptdc] [Omega Point][op]---the final
evolution of an evolving god. The machines try to reach this point by creating
a god that is all intellect. But because it cannot suffer, it is destined to
lose to the human god, which unites intellect with empathy via the Void Which
Binds. Severn transitions from dreamer to poet only when he suffers through
the same death as {{ keats_lastname }}, allowing him to finally act by joining
the empathy aspect of the triune human god.

[ptdc]: https://en.wikipedia.org/wiki/Pierre_Teilhard_de_Chardin
[op]: https://en.wikipedia.org/wiki/Omega_Point

Ultimately, the book follows {{ keatss_lastname }} theme of "dying into life."
The narrator in {{ poem }} feels his death and rebirth as he climbs to the
altar; similarly, the novel's narrator, Joseph Severn, must physically die to
be reborn within the Void. Apollo in {{ keatss_lastname }} {{ hyperion_keats
}} is granted godhood through "knowledge enormous", taking in the agonies and
triumphs of the universe, just as the human god is born from uniting intellect
and empathy. We see this cycle everywhere: with Father Duré and Father Hoyt
dying and being reborn through the cruciform parasite, and finally with CEO
Meina Gladstone's choice to destroy the Hegemony.

Gladstone's choice resolves the theme of Abrahamic sacrifice introduced in the
first book. In {{ this_book }}, Sol Weintraub realizes that Abraham's test was
not really a test of Abraham, but a test of God, and that blind obedience is
immoral. By reclaiming his own will, he resolves the dilemma. Weintraub
sacrifices Rachel only when _she_ asks for it. Gladstone arrives at the same
solution: she sacrifices the Hegemony not because it is demanded, but because
she chooses to take the sin upon herself, freeing humanity and allowing them
to die into life.

### Story

{{ hyperion }}'s structure is so compelling, with each pilgrim's story as a
pastiche of a different genre. When you layer in the themes and references to
{{ keatss_lastname }} work, it becomes a masterpiece. {{ this_book }} feels
like a pale imitation. It's still great, but not transcendental.

It also suffers in the way {{ wolfes_lastname }} {{ urth }} does: it explains
every mystery. The cruciform parasites were intended to do this, the Tree of
Thorns was created to do that, etc., etc. It leaves the impression that the
world is a little too neat, too planned out.

That said, the plotting and pacing are on point. There are two twists that
both hit hard. The first is when the other Ouster swarms attack the Web,
indicating they must have been launched hundreds of years ago. The second
comes when the swarms are revealed to be TechnoCore false-flag operations, and
the Ousters are revealed to be humanity's true descendants rather than
barbarians.

{{ this_book }} reminded me of a few other works in its darker themes. The
Shrike's Tree of Pain being imaginary, with torture fed into the victims'
heads via a shunt, is the same idea as in {{ bankss_lastname }}
{{ surface_detail }}, where civilizations use simulated hells to punish
sinners. The planet-wide inferno on God's Grove was like the tsunamis of flame
in {{ the_player_of_games }}. Gladstone sacrificing billions to save humanity
reminds me of the choice Ozymandias makes in {{ moore_and_gibbonss }}
{{ watchmen }}, although Ozymandias builds a lie whereas Gladstone exposes the
truth. Both this book and {{ el_mohtar_and_gladstones }}
{{ this_is_how_you_lose_the_time_war }} deal with a war being fought over
possible futures.

Some of the details were similar to other books as well. The Core references
{{ asimovs_lastname }} [Three Laws of Robotics][three_laws] from {{ i_robot
}}. The navy's use of a star system in the farcaster network as a DMZ is an
idea later used by {{ taylor_lastname }} in {{ lost }}, and is similar to how
Basilisk is used in {{ webers_lastname }} {{ basilisk }}. Finally, the
cruciform glowing on the labyrinth walls reminded me of the glowing Harmonium
aliens in the caves of Mercury in {{ vonneguts_lastname }} {{
the_sirens_of_titan }}.

[three_laws]: https://en.wikipedia.org/wiki/Three_Laws_of_Robotics

The last time I read this book, I stopped here and didn't finish the rest of
the {{ this_series }}. This time I intend to continue on through {{ endymion
}} and {{ rise_of_endymion }}, even though I hear each one is worse than the
last. I'm hoping I've heard incorrectly!
