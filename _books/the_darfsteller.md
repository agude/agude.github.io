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
class="author-name">{{ page.book_authors }}</span>, is a Hugo Award-winning
novelette about the obsolescence of the human artist. It follows Ryan
Thornier, a former matinee idol reduced to working as a janitor in a theater
now run entirely by robots and an AI director, as he schemes to take the stage
one last time.

{% capture this_book %}<cite class="book-title">{{ page.title }}</cite>{% endcapture %}
{% capture the_authors_lastname %}<span class="author-name">Miller</span>{% endcapture %}
{% capture the_authors_lastname_possessive %}<span class="author-name">Miller</span>'s{% endcapture %}

{% capture dahls_lastname %}{% author_link "Roald Dahl" possessive link_text="Dahl" %}{% endcapture %}
{% capture grammatizator %}{% short_story_link "The Great Automatic Grammatizator" from_book="Someone Like You" %}{% endcapture %}

{% capture leibers_lastname %}{% author_link "Fritz Leiber" possessive link_text="Leiber" %}{% endcapture %}
{% capture the_silver_eggheads %}{% book_link "The Silver Eggheads" %}{% endcapture %}

{% capture lems_lastname %}{% author_link "Stanislaw Lem" possessive link_text="Lem" %}{% endcapture %}
{% capture trurls_electronic_bard %}{% short_story_link "Trurl's Electronic Bard" from_book="The Cyberiad" %}{% endcapture %}

{% capture ballards_lastname %}{% author_link "J.G. Ballard" possessive link_text="Ballard" %}{% endcapture %}
{% capture studio_5_the_stars %}{% short_story_link "Studio 5, The Stars" from_book="Vermilion Sands" %}{% endcapture %}

{% capture vonneguts_lastname %}{% author_link "Kurt Vonnegut" possessive link_text="Vonnegut" %}{% endcapture %}
{% capture player_piano %}{% book_link "Player Piano" %}{% endcapture %}

{% capture heinlein_lastname %}{% author_link "Robert A. Heinlein" link_text="Heinlein" %}{% endcapture %}
{% capture heinleins_lastname %}{% author_link "Robert A. Heinlein" possessive link_text="Heinlein" %}{% endcapture %}
{% capture time_enough_for_love %}{% book_link "Time Enough for Love" %}{% endcapture %}

{% capture simmonss_lastname %}{% author_link "Dan Simmons" possessive link_text="Simmons" %}{% endcapture %}
{% capture hyperion %}{% book_link "Hyperion" %}{% endcapture %}

{% capture arkady_and_boris_strugatskys %}{% author_link "Arkady Strugatsky" link_text="Arkady" %} and {% author_link "Boris Strugatsky" possessive %}{% endcapture %}
{% capture saturday %}{% book_link "Monday Begins on Saturday" %}{% endcapture %}

{% capture time_war %}{% book_link "This Is How You Lose the Time War" %}{% endcapture %}

In the specific future of {{ this_book }}, actors have been replaced on the
stage by robots. An AI Maestro controls them and adapts the works on the fly
to the audience's reactions. Human actors are a novelty, only used out in the
sticks as a lark. Audiences prefer the robotic plays because they are easier
to understand and less challenging to their points of view. Against this
backdrop, three former actors---Ryan Thornier, Mela Stone, and Jade
Ferne---try to figure out what to do with their lives.

Thornier is obsessed with his former life, and is reduced to mopping the
floors of the theater in a big to stay close to the stage. When he grows tired
of it, and is on the verge of again being replaced by a robot, he plots a way
to sabotage the play and give himself one last chance at a staring role.
Stone, on the other hand, has accepted the complete commercialization of her
art. She sells her personality rights, allowing robots to be made in her
image. Ferne was never popular enough to be offered that kind of contract, so
she instead works producing robotic plays.


I was expecting {{ the_authors_lastname }}, as an artist, to take Thornier's
side. But he doesn't, not really. He portrays Thornier as driven by vanity and
fighting hopelessly against an inevitability. His inability to move on, and
respond to the audience, makes him more machine-like than the Maestro. Nor
does the author condemn Stone and Ferne as collaborators. Even the robots and
their creator aren't the villains. If there is anyone at fault, it is the
audience that has learned to prefer unchallenging robots. But there too {{
the_authors_lastname }} admits that is the way it should be in commercial art;
controlled entirely by the economics of it.

At the end, the author argues that specialists are doomed to be replaced. Only
someone who adapts constantly survives. One of his characters says: "The
specialty of creating new specialties. Continuously. Your own. [...] More or
less a definition of Man, isn't it?" It reminds me of {{ heinleins_lastname }}
famous assertion that "Specialization is for insects".[^quote] Although {{
the_authors_lastname }} is arguing more for specializing in _being yourself_,
while {{ heinlein_lastname }} argues for generalization, both have identified
stagnation as the problem.

[^quote]:
    From {{ time_enough_for_love }}: 

    > A human being should be able to change a diaper, plan an invasion,
    > butcher a hog, conn a ship, design a building, write a sonnet, balance
    > accounts, build a wall, set a bone, comfort the dying, take orders, give
    > orders, cooperate, act alone, solve equations, analyze a new problem,
    > pitch manure, program a computer, cook a tasty meal, fight efficiently,
    > die gallantly. Specialization is for insects.

In science fiction, I often see works that predict robots replacing manual
labor, or AI taking over numerical jobs. A common conceit is that what makes
humans unique is our creativity and that is what will keep us relevant. {{
this_book }} is interesting in that it instead proposes that that creative
work might in fact be what we automate. 70 years after it was written, with
the rise of [generative AI][gen_ai], that might be exactly what we are
starting to see. Like current artists, the actors in this book have different
ways of dealing with their new reality, some [push back against it while
others give in][ai_art]. {{ the_authors_lastname_possessive }} answer is
bleak: for commercial art, what makes money is what will win. It makes the
work a surprisingly prescient take on our modern world.

[gen_ai]: {% link topics/generative-ai.md %}
[ai_art]: {% post_url 2023-01-30-ai_artists_and_technology %}

The anxiety of automation of creative work, and particularly of the writing
process, is a theme explored by a few other works (an understandable fear,
given they are written by authors): {{ dahls_lastname }} {{ grammatizator }}
has a man invent a way to automatically generate best-selling books. {{
leibers_lastname }} {{ the_silver_eggheads }} has authors selling their names
to brand computer written books. {{ lems_lastname }} {{ trurls_electronic_bard
}} has a machine that writes poetry better than humans, driving authors to
suicide. {{ ballards_lastname }} {{ studio_5_the_stars }} likewise has a
poetry writing machine. {{ vonneguts_lastname }} {{ player_piano }} explores a
world where everything is automated. {{ simmonss_lastname }} {{ hyperion }}
tackles the commercialization and debasement of art, with Silenus's brilliant
<cite class="book-title">Cantos</cite> flopping while his pulpy <cite
class="book-title">The Dying Earth</cite> sold billions.

Up next is {{ arkady_and_boris_strugatskys }} {{ saturday }}, and then I
really should start {{ time_war }} for my book club.
