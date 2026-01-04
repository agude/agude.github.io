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

{% capture hyperion %}{% book_link "Hyperion" %}{% endcapture %}
{% capture endymion %}{% book_link "Endymion" %}{% endcapture %}
{% capture rise_of_endymion %}{% book_link "The Rise of Endymion" %}{% endcapture %}

{% capture keats %}{% author_link "John Keats" %}{% endcapture %}
{% capture keatss %}{% author_link "John Keats" possessive %}{% endcapture %}
{% capture keats_lastname %}{% author_link "Keats" %}{% endcapture %}
{% capture keatss_lastname %}{% author_link "Keats" possessive %}{% endcapture %}
{% capture poem %}{% book_link "The Fall of Hyperion: A Dream" %}{% endcapture %}
{% capture hyperion_keats %}{% book_link "Hyperion" author="John Keats" %}{% endcapture %}

{% capture banks %}{% author_link "Iain M. Banks" %}{% endcapture %}
{% capture bankss %}{% author_link "Iain M. Banks" possessive %}{% endcapture %}
{% capture banks_lastname %}{% author_link "Iain M. Banks" link_text="Banks" %}{% endcapture %}
{% capture bankss_lastname %}{% author_link "Iain M. Banks" possessive link_text="Banks" %}{% endcapture %}
{% capture the_player_of_games %}{% book_link "The Player of Games" %}{% endcapture %}
{% capture surface_detail %}{% book_link "Surface Detail" %}{% endcapture %}

{% capture el_mohtar %}{% author_link "Amal El-Mohtar" %}{% endcapture %}
{% capture el_mohtars %}{% author_link "Amal El-Mohtar" possessive %}{% endcapture %}
{% capture el_mohtar_lastname %}{% author_link "Amal El-Mohtar" link_text="El-Mohtar" %}{% endcapture %}
{% capture el_mohtars_lastname %}{% author_link "Amal El-Mohtar" possessive link_text="El-Mohtar" %}{% endcapture %}
{% capture gladstone %}{% author_link "Max Gladstone" %}{% endcapture %}
{% capture gladstones %}{% author_link "Max Gladstone" possessive %}{% endcapture %}
{% capture gladstone_lastname %}{% author_link "Max Gladstone" link_text="Gladstone" %}{% endcapture %}
{% capture gladstones_lastname %}{% author_link "Max Gladstone" possessive link_text="Gladstone" %}{% endcapture %}
{% capture el_mohtar_and_gladstones %}{% author_link "Amal El-Mohtar" link_text="El-Mohtar"%} and {% author_link "Max Gladstone" link_text="Gladstone" possessive %}{% endcapture %}
{% capture this_is_how_you_lose_the_time_war %}{% book_link "This Is How You Lose the Time War" %}{% endcapture %}

{% capture vonnegut %}{% author_link "Kurt Vonnegut" %}{% endcapture %}
{% capture vonneguts %}{% author_link "Kurt Vonnegut" possessive %}{% endcapture %}
{% capture vonnegut_lastname %}{% author_link "Kurt Vonnegut" link_text="Vonnegut" %}{% endcapture %}
{% capture vonneguts_lastname %}{% author_link "Kurt Vonnegut" possessive link_text="Vonnegut" %}{% endcapture %}
{% capture the_sirens_of_titan %}{% book_link "The Sirens of Titan" %}{% endcapture %}

{% capture taylor %}{% author_link "Dennis E. Taylor" %}{% endcapture %}
{% capture taylors %}{% author_link "Dennis E. Taylor" possessive %}{% endcapture %}
{% capture taylor_lastname %}{% author_link "Dennis E. Taylor" link_text="Taylor" %}{% endcapture %}
{% capture taylors_lastname %}{% author_link "Dennis E. Taylor" possessive link_text="Taylor" %}{% endcapture %}
{% capture bobiverse %}{% series_link "Bobiverse" %}{% endcapture %}
{% capture lost %}{% book_link "Not Till We Are Lost" %}{% endcapture %}

{% capture weber %}{% author_link "David Weber" %}{% endcapture %}
{% capture webers %}{% author_link "David Weber" possessive %}{% endcapture %}
{% capture weber_lastname %}{% author_link "David Weber" link_text="Weber" %}{% endcapture %}
{% capture webers_lastname %}{% author_link "David Weber" possessive link_text="Weber" %}{% endcapture %}
{% capture basilisk %}{% book_link "On Basilisk Station" %}{% endcapture %}

{% capture asimov %}{% author_link "Isaac Asimov" %}{% endcapture %}
{% capture asimovs %}{% author_link "Isaac Asimov" possessive %}{% endcapture %}
{% capture asimov_lastname %}{% author_link "Isaac Asimov" link_text="Asimov" %}{% endcapture %}
{% capture asimovs_lastname %}{% author_link "Isaac Asimov" possessive link_text="Asimov" %}{% endcapture %}
{% capture i_robot %}{% book_link "I, Robot" %}{% endcapture %}

{% capture baum %}{% author_link "L. Frank Baum" %}{% endcapture %}
{% capture baums %}{% author_link "L. Frank Baum" possessive %}{% endcapture %}
{% capture baum_lastname %}{% author_link "L. Frank Baum" link_text="Baum" %}{% endcapture %}
{% capture baums_lastname %}{% author_link "L. Frank Baum" possessive link_text="Baum" %}{% endcapture %}
{% capture the_wonderful_wizard_of_oz %}{% book_link "The Wonderful Wizard of Oz" %}{% endcapture %}

{% capture wolfe %}{% author_link "Gene Wolfe" %}{% endcapture %}
{% capture wolfes %}{% author_link "Gene Wolfe" possessive %}{% endcapture %}
{% capture wolfe_lastname %}{% author_link "Gene Wolfe" link_text="Wolfe" %}{% endcapture %}
{% capture wolfes_lastname %}{% author_link "Gene Wolfe" possessive link_text="Wolfe" %}{% endcapture %}
{% capture botns %}{% series_link "The Book of the New Sun" %}{% endcapture %}
{% capture urth %}{% book_link "Urth of the New Sun" %}{% endcapture %}

{% capture terminator %}<cite class="movie-title">The Terminator</cite>{% endcapture %}

{% capture moore %}{% author_link "Alan Moore" %}{% endcapture %}
{% capture moores %}{% author_link "Alan Moore" possessive %}{% endcapture %}
{% capture moore_lastname %}{% author_link "Alan Moore" link_text="Moore" %}{% endcapture %}
{% capture moores_lastname %}{% author_link "Alan Moore" possessive link_text="Moore" %}{% endcapture %}

{% capture gibbons %}{% author_link "Dave Gibbons" %}{% endcapture %}
{% capture gibbonss %}{% author_link "Dave Gibbons" possessive %}{% endcapture %}
{% capture gibbons_lastname %}{% author_link "Dave Gibbons" link_text="Gibbons" %}{% endcapture %}
{% capture gibbonss_lastname %}{% author_link "Dave Gibbons" possessive link_text="Gibbons" %}{% endcapture %}

{% capture moore_and_gibbonss %}{% author_link "Alan Moore" link_text="Moore" %} and {% author_link "Dave Gibbons" link_text="Gibbons" possessive %}{% endcapture %}
{% capture watchmen %}{% book_link "Watchmen" %}{% endcapture %}

I loved {{ this_book }} when I [first read it][first_read], even more so than
{{ hyperion }}. It tells a much simpler story, delivering space battles, the
Soldier fighting the Shrike, and answers to every mystery. It doesn't require
the kind of close reading {{ hyperion }} does to really enjoy it.

[first_read]: {% link _books/the_fall_of_hyperion/review-2023-10-27.md %}

On this second read-through, I recognized {{ hyperion }} for the masterpiece
it is, on the same level as {{ wolfes_lastname }} {{ botns }} <!-- TODO...
What else? Things I rate more highly are: Firefall; Fire Upon The Deep; and
Surface Detail, Use of Weapons, Look to Windward, Player of Games, and
Inversions. BOTNS is actually rated much lower (4 stars) but I think on a
reread I'd move it into the high 5-stars with the others. -->. My opinion of
this book didn't change; it's still great, but the gap between it and the
first book widened considerably. <!-- TODO Not really widened? I used to think
Hyperion was worse -->

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
well. The machine god is all intellect, but because it cannot suffer, it is
destined to lose to the human god, which unites intellect with empathy via the
Void Which Binds. Severn transitions from dreamer to poet when he suffers
through the same death as {{ keats_lastname }}, allowing him to act in the
world by joining the empathy aspect of the human god triune through the Void.

Ultimately, the book follows {{ keatss_lastname }} theme of "dying into life."
The narrator in {{ poem }} feels his death and rebirth as he climbs to the
altar. In the novel, the birth of the human god parallels Apollo in {{
hyperion_keats }}, who is granted godhood through "knowledge enormous". We see
this cycle everywhere: with Father Duré and Father Hoyt dying and being reborn
through the cruciform parasite, and finally with CEO Meina Gladstone's choice
to destroy the Hegemony.

Gladstone's choice echoes the theme of Abrahamic sacrifice from the first book
most closely associated with the scholar Sol Weintraub and his daughter
Rachel. In {{ this_book }}, Weintraub finally sacrifices Rachel when he
realizes that it is _his daughter_, not the Shrike, demanding the sacrifice.
Likewise, Gladstone sacrifices the Hegemony and takes on the sin of doing so
not because it is demanded, but because she chooses it.

### Story

{{ hyperion }}'s structure is so compelling, with each pilgrim's story as a
pastiche of a different genre. When you layer in the themes and references to
{{ keatss_lastname }} work, it becomes a masterpiece. {{ this_book }} feels
like a pale imitation. It's still great, but not transcendental.

It also suffers in the way {{ wolfes_lastname }} {{ urth }} does: it explains
every mystery. The cruciform parasites do this, the Tree of Thorns does that,
etc., etc. It leaves the impression that the world is a little too neat, too
planned out.

That said, the plotting and pacing are on point. There are two twists that
both hit hard. The first is when the other Ouster swarms attack the web,
indicating they must have been launched hundreds of years ago. The second
comes when the swarms are revealed to be TechnoCore false-flag operations, and
the Ousters are shown to be humanity's true descendants.

{{ this_book }} reminded me of a few other works. The Shrike's Tree of Pain
being imaginary, the torture fed into the victims' heads via a shunt, is the
same idea as in {{ bankss_lastname }} {{ surface_detail }}, where
civilizations use simulated hells to punish sinners. The planet-wide inferno
on God's Grove was like the tsunamis of flame in {{ the_player_of_games }}.
Gladstone sacrificing billions to save humanity reminds me of the choice
Ozymandias makes in {{ moore_and_gibbonss }} {{ watchmen }}, where he brings
humanity back from the brink of nuclear war by fabricating an alien threat.
The Core references {{ asimovs_lastname }} [Three Laws of
Robotics][three_laws] from {{ i_robot }}. The navy's use of a star system in
the farcaster network as a DMZ is an idea later used by {{ taylor_lastname }}
in {{ lost }}, and is similar to how Basilisk is used in {{ webers_lastname }}
{{ basilisk }}. The cruciform glowing on the labyrinth walls reminded me of
the glowing Harmonium aliens in the caves of Mercury in {{ vonneguts_lastname
}} {{ the_sirens_of_titan }}. Both this book and {{ el_mohtar_and_gladstones
}} {{ this_is_how_you_lose_the_time_war }} deal with a war being fought over
possible futures.

[three_laws]: https://en.wikipedia.org/wiki/Three_Laws_of_Robotics

The last time I read this book, I stopped here and didn't finish the rest of
the {{ this_series }}. This time I intend to continue on through {{ endymion
}} and {{ rise_of_endymion }}, even though I hear each one is worse than the
last. I'm hoping I've heard incorrectly!
