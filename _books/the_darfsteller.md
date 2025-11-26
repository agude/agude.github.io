---
date: 2025-11-24
title: The Darfsteller
book_authors: Walter M. Miller Jr.
book_number: 1
is_anthology: false
rating: 3
image: /books/covers/the_darfsteller.jpg
awards:
  - hugo
---

<cite class="book-title">{{ page.title }}</cite>, by <span
class="author-name">{{ page.book_authors }}</span>, is a Hugo Award-winning
novelette about the obsolescence of the human artist. It follows Ryan
Thornier, a former stage idol reduced to working as a janitor in a theater now
run entirely by robots and an AI director, as he schemes to take the stage one
last time.

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

In the future of {{ this_book }}, actors have been replaced on the stage by
robots. An AI Maestro controls them, adjusting the plays on the fly in
response to the audiences' reactions. Audiences prefer the robotic plays
because they are easier to understand and less challenging to their views.
Against this backdrop, three former actors---Ryan Thornier, Mela Stone, and
Jade Ferne---try to figure out what to do with their lives.

Thornier is obsessed with his former life and resorts to mopping the theater
floors in a bid to stay close to the stage. When he grows tired of it, and is
on the verge of being replaced by a robot yet again, he plots to sabotage the
play and give himself one last chance at a starring role. Stone, on the other
hand, has accepted the complete commercialization of her art. She sells her
personality rights, allowing robots to be made in her image. Ferne was never
popular enough for that kind of contract, so she works producing robotic plays
instead.

I expected {{ the_authors_lastname }}, as an artist, to take Thornier's side.
But he doesn't, not really. He portrays Thornier as driven by vanity and
fighting hopelessly against the inevitable. His inability to respond to the
audience and move on makes him more machine-like than the Maestro. Nor does
the author condemn Stone and Ferne as collaborators. Even the robots and their
creator aren't villains. If anyone is at fault, it is the audience that has
learned to prefer unchallenging plays. But there too, {{ the_authors_lastname
}} admits this is the reality of how commercial art must be: controlled
entirely by economics.

At the end, the author argues that specialists are doomed to be replaced. Only
those who keep adapting survive. As one character put it: "The specialty of
creating new specialties. Continuously. Your own. [...] More or less a
definition of Man, isn't it?" It reminds me of {{ heinleins_lastname }} famous
assertion that "Specialization is for insects".[^quote] Although {{
the_authors_lastname }} argues more for specializing in _being yourself_ while
{{ heinlein_lastname }} argues for generalization, both have identified
stagnation as the problem.

[^quote]:
    From {{ time_enough_for_love }}: 

    > A human being should be able to change a diaper, plan an invasion,
    > butcher a hog, conn a ship, design a building, write a sonnet, balance
    > accounts, build a wall, set a bone, comfort the dying, take orders, give
    > orders, cooperate, act alone, solve equations, analyze a new problem,
    > pitch manure, program a computer, cook a tasty meal, fight efficiently,
    > die gallantly. Specialization is for insects.

Science fiction often imagines robots replacing manual labor and AI taking
over numerical jobs. A common conceit is that creativity is the one human
trait machines can't emulate, and it is what keeps us relevant. {{ this_book
}} flips that. Instead, it suggests that creative work will be the first thing
we automate. Seventy years later, with the rise of [generative AI][gen_ai],
that is exactly what we're seeing. Like current artists, the actors in this
story react in different ways: [some push back against][ai_art] it while
others give in. {{ the_authors_lastname_possessive }} answer is bleak: in
commercial art, what makes money wins. The result feels surprisingly
prescient.

[gen_ai]: {% link topics/generative-ai.md %}
[ai_art]: {% post_url 2023-01-30-ai_artists_and_technology %}

The fear of automating creative work is explored in a few other stories, and
writers---being writers---have mostly focused on the written word: {{
dahls_lastname }}'s {{ grammatizator }} features a machine that generates
best-sellers automatically; {{ leibers_lastname }}'s {{ the_silver_eggheads }}
imagines authors selling their names to brand computer-written books; {{
lems_lastname }}'s {{ trurls_electronic_bard }} centers on a machine that
writes poetry better than humans, driving them to suicide; {{
ballards_lastname }}'s {{ studio_5_the_stars }} likewise has a poetry machine.
{{ vonneguts_lastname }}'s {{ player_piano }} explores a world where
everything is automated. {{ simmonss_lastname }}'s {{ hyperion }} tackles the
commercialization and debasement of art, where Silenus's brilliant <cite
class="book-title">Cantos</cite> flops while his pulpy <cite
class="book-title">The Dying Earth</cite> sells billions.

Up next is {{ arkady_and_boris_strugatskys }} {{ saturday }}, and then I
really should start {{ time_war }} for my book club.
