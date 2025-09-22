---
date: 2025-09-20
title: Hyperion
book_authors: Dan Simmons
series: Hyperion Cantos
book_number: 1
is_anthology: true
rating: 5
image: /books/covers/hyperion.jpg
awards:
  - hugo
  - locus
---

<cite class="book-title">{{ page.title }}</cite> is <span
class="author-name">{{ page.book_authors }}</span>'s masterpiece. It is the
first book in his <span class="book-series">{{ page.series }}</span>. It
follows seven pilgrims as they travel to the time tombs on Hyperion to
petition the Shrike.

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

{% capture the_priests_tale %}{% short_story_link "The Priest's Tale" %}{% endcapture %}
{% capture the_soldiers_tale %}{% short_story_link "The Soldier's Tale" %}{% endcapture %}
{% capture the_poets_tale %}{% short_story_link "The Poet's Tale" %}{% endcapture %}
{% capture the_scholars_tale %}{% short_story_link "The Scholar's Tale" %}{% endcapture %}
{% capture the_detectives_tale %}{% short_story_link "The Detective's Tale" %}{% endcapture %}
{% capture the_consuls_tale %}{% short_story_link "The Consul's Tale" %}{% endcapture %}

{% comment %} Foundational Works for the Review {% endcomment %}

{% capture fall_hyperion %}{% book_link "The Fall of Hyperion" %}{% endcapture %}

{% capture keats %}{% author_link "John Keats" %}{% endcapture %}
{% capture keatss %}{% author_link "John Keats" possessive %}{% endcapture %}
{% capture keats_lastname %}{% author_link "John Keats" link_text="Keats" %}{% endcapture %}
{% capture keats_lastname_possessive %}{% author_link "John Keats" link_text="Keats" possessive %}{% endcapture %}
{% capture hyperion_keats %}{% book_link "Hyperion" author="John Keats" %}{% endcapture %}

{% capture chaucer %}{% author_link "Geoffrey Chaucer" %}{% endcapture %}
{% capture chaucers %}{% author_link "Geoffrey Chaucer" possessive %}{% endcapture %}
{% capture canterbury %}{% book_link "The Canterbury Tales" %}{% endcapture %}

{% comment %} Iain M. Banks (The Culture etc.) {% endcomment %}

{% capture banks %}{% author_link "Iain M. Banks" %}{% endcapture %}
{% capture bankss %}{% author_link "Iain M. Banks" possessive %}{% endcapture %}
{% capture player_of_games %}{% book_link "The Player of Games" %}{% endcapture %}
{% capture look_to_windward %}{% book_link "Look to Windward" %}{% endcapture %}
{% capture consider_phlebas %}{% book_link "Consider Phlebas" %}{% endcapture %}
{% capture surface_detail %}{% book_link "Surface Detail" %}{% endcapture %}
{% capture hydrogen_sonata %}{% book_link "The Hydrogen Sonata" %}{% endcapture %}
{% capture gift_from_the_culture %}{% short_story_link "A Gift from the Culture" %}{% endcapture %}
{% capture descendant %}{% short_story_link "Descendant" %}{% endcapture %}

{% comment %} Other Science Fiction Authors & Works {% endcomment %}

{% capture clarke %}{% author_link "Arthur C. Clarke" %}{% endcapture %}
{% capture clarkes %}{% author_link "Arthur C. Clarke" possessive %}{% endcapture %}
{% capture the_star %}{% short_story_link "The Star" %}{% endcapture %}

{% capture asimov %}{% author_link "Isaac Asimov" %}{% endcapture %}
{% capture asimovs %}{% author_link "Isaac Asimov" possessive %}{% endcapture %}
{% capture steel %}{% short_story_link "The Caves of Steel" %}{% endcapture %}

{% capture bradbury %}{% author_link "Ray Bradbury" %}{% endcapture %}
{% capture bradburys %}{% author_link "Ray Bradbury" possessive %}{% endcapture %}
{% capture the_man %}{% short_story_link "The Man" %}{% endcapture %}

{% capture conrad %}{% author_link "Joseph Conrad" %}{% endcapture %}
{% capture conrads %}{% author_link "Joseph Conrad" possessive %}{% endcapture %}
{% capture heart_of_darkness %}{% book_link "Heart of Darkness" %}{% endcapture %}

{% capture haldeman %}{% author_link "Joe Haldeman" %}{% endcapture %}
{% capture haldemans %}{% author_link "Joe Haldeman" possessive %}{% endcapture %}
{% capture forever_war %}{% book_link "The Forever War" %}{% endcapture %}

{% capture wells %}{% author_link "Martha Wells" %}{% endcapture %}
{% capture wellss %}{% author_link "Martha Wells" possessive %}{% endcapture %}
{% capture murderbot %}{% book_link "The Murderbot Diaries" %}{% endcapture %}

{% capture vance %}{% author_link "Jack Vance" %}{% endcapture %}
{% capture vances %}{% author_link "Jack Vance" possessive %}{% endcapture %}
{% capture dying_earth %}{% book_link "The Dying Earth" %}{% endcapture %}

{% capture hamilton %}{% author_link "Peter F. Hamilton" %}{% endcapture %}
{% capture hamiltons %}{% author_link "Peter F. Hamilton" possessive %}{% endcapture %}
{% capture judas_unchained %}{% book_link "Judas Unchained" %}{% endcapture %}

{% capture brunner %}{% author_link "John Brunner" %}{% endcapture %}
{% capture brunners %}{% author_link "John Brunner" possessive %}{% endcapture %}
{% capture stand_on_zanzibar %}{% book_link "Stand on Zanzibar" %}{% endcapture %}

{% capture card %}{% author_link "Orson Scott Card" %}{% endcapture %}
{% capture cards %}{% author_link "Orson Scott Card" possessive %}{% endcapture %}
{% capture enders_game %}{% book_link "Ender's Game" %}{% endcapture %}

{% capture arkady_and_boris_strugatsky %}{% author_link "Arkady Strugatsky" link_text="Arkady" %} and {% author_link "Boris Strugatsky" %}{% endcapture %}

{% capture le_guin %}{% author_link "Ursula K. Le Guin" %}{% endcapture %}
{% capture le_guins %}{% author_link "Ursula K. Le Guin" possessive %}{% endcapture %}
{% capture left_hand_of_darkness %}{% book_link "The Left Hand of Darkness" %}{% endcapture %}

{% capture keyes %}{% author_link "Daniel Keyes" %}{% endcapture %}
{% capture keyess %}{% author_link "Daniel Keyes" possessive %}{% endcapture %}
{% capture flowers_for_algernon %}{% book_link "Flowers for Algernon" %}{% endcapture %}

{% capture gibson %}{% author_link "William Gibson" %}{% endcapture %}
{% capture gibson_lastname %}{% author_link "William Gibson" link_text="Gibson" %}{% endcapture %}
{% capture gibsons %}{% author_link "William Gibson" possessive %}{% endcapture %}
{% capture johnny_mnemonic %}{% book_link "Johnny Mnemonic" %}{% endcapture %}
{% capture neuromancer %}{% book_link "Neuromancer" %}{% endcapture %}

{% capture orwell %}{% author_link "George Orwell" %}{% endcapture %}
{% capture orwells %}{% author_link "George Orwell" possessive %}{% endcapture %}
{% capture nineteen_eighty_four %}{% book_link "1984" %}{% endcapture %}

{% capture tchaikovsky %}{% author_link "Adrian Tchaikovsky" %}{% endcapture %}
{% capture tchaikovskys %}{% author_link "Adrian Tchaikovsky" possessive %}{% endcapture %}
{% capture shards_of_earth %}{% book_link "Shards of Earth" %}{% endcapture %}
{% capture lords %}{% book_link "Lords of Uncreation" %}{% endcapture %}

{% capture adams %}{% author_link "Douglas Adams" %}{% endcapture %}
{% capture adamss %}{% author_link "Douglas Adams" possessive %}{% endcapture %}
{% capture hitchhikers_guide %}{% book_link "The Hitchhiker's Guide to the Galaxy" %}{% endcapture %}

{% capture brin %}{% author_link "David Brin" %}{% endcapture %}
{% capture brins %}{% author_link "David Brin" possessive %}{% endcapture %}
{% capture sundiver %}{% book_link "Sundiver" %}{% endcapture %}

{% capture burroughs %}{% author_link "Edgar Rice Burroughs" %}{% endcapture %}
{% capture burroughss %}{% author_link "Edgar Rice Burroughs" possessive %}{% endcapture %}
{% capture john_carter %}{% book_link "A Princess of Mars" %}{% endcapture %}

{% capture hg_wells %}{% author_link "H. G. Wells" %}{% endcapture %}
{% capture hg_wellss %}{% author_link "H. G. Wells" possessive %}{% endcapture %}
{% capture time_machine %}{% book_link "The Time Machine" %}{% endcapture %}

{% capture chandler %}{% author_link "Raymond Chandler" %}{% endcapture %}
{% capture chandlers %}{% author_link "Raymond Chandler" possessive %}{% endcapture %}

{% comment %} Classic & Literary Authors {% endcomment %}

{% capture bible %}{% book_link "The Bible" %}{% endcapture %}
{% capture genesis %}{% short_story_link "The Book of Genesis" %}{% endcapture %}
{% capture binding %}{% short_story_link "Binding of Isaac" %}{% endcapture %}

{% capture twain %}{% author_link "Mark Twain" %}{% endcapture %}
{% capture twains %}{% author_link "Mark Twain" possessive %}{% endcapture %}
{% capture huckleberry_finn %}{% book_link "Adventures of Huckleberry Finn" %}{% endcapture %}

{% capture doyle %}{% author_link "Arthur Conan Doyle" %}{% endcapture %}
{% capture doyles %}{% author_link "Arthur Conan Doyle" possessive %}{% endcapture %}
{% capture the_final_problem %}{% short_story_link "The Final Problem" %}{% endcapture %}

{% capture collodi %}{% author_link "Carlo Collodi" %}{% endcapture %}
{% capture collodis %}{% author_link "Carlo Collodi" possessive %}{% endcapture %}
{% capture pinocchio %}{% book_link "The Adventures of Pinocchio" %}{% endcapture %}

{% capture shakespeare %}{% author_link "William Shakespeare" link_text="Shakespeare" %}{% endcapture %}
{% capture shakespeares %}{% author_link "William Shakespeare" link_text="Shakespeare" possessive %}{% endcapture %}
{% capture romeo_and_juliet %}{% book_link "Romeo and Juliet" %}{% endcapture %}

{% capture beowulf %}{% book_link "Beowulf" %}{% endcapture %}

{% capture kierkegaard %}{% author_link "Søren Kierkegaard" %}{% endcapture %}
{% capture kierkegaard_lastname %}{% author_link "Søren Kierkegaard" link_text="Kierkegaard" %}{% endcapture %}
{% capture kierkegaards %}{% author_link "Søren Kierkegaard" possessive %}{% endcapture %}
{% capture fear_and_trembling %}{% book_link "Fear and Trembling" %}{% endcapture %}

{% comment %} Games & Movies {% endcomment %}

{% capture disco_elysium %}<cite class="game-title">Disco Elysium</cite>{% endcapture %}

{% capture space_odyssey %}<cite class="movie-title">2001: A Space Odyssey</cite>{% endcapture %}
{% capture terminator %}<cite class="movie-title">The Terminator</cite>{% endcapture %}

I didn't love {{ this_book }} when [I first read it][first_read] about two
years ago. It's a book full of deep intertextuality, influenced heavily by {{
keatss }} {{ hyperion_keats }}, but also by {{ chaucers }} {{ canterbury }}.
{{ author_last_name_text }} uses that classic pilgrimage structure as a frame
to present six different stories, each one a pastiche of a different genre.
But I missed almost all of that the first time. Instead, I was distracted by
lasers, barbarians, and the god-like Shrike covered in blades.

[first_read]: #previous-review

### Themes

The central theme of {{ keatss }} {{ hyperion_keats }} is the inevitability of
change, especially the collapse of the old order. In his poem, this comes
through in the [Titans being overthrown by the Olympians][titanomachy]. {{
the_author }} carries this theme into his {{ this_book }}. We see it in the
looming downfall of humanity, with their replacement by either the
TechnoCore's AIs or the Ousters, but also in smaller ways throughout each
pilgrim's story.

[titanomachy]: https://en.wikipedia.org/wiki/Titanomachy

{{ keats_lastname }} explores several other themes in his work: the
relationship between beauty, truth, and power; the connection between
knowledge and suffering; and the role of the poet. {{ author_last_name_text }}
adopts these themes as well.

### Tales

There are seven pilgrims, but only six live to tell their tales. {{ the_author
}} uses each story to explore a different genre, but also to explore the {{
keats_lastname_possessive }} themes in new settings and scales.

#### {% short_story_title "The Priest's Tale" %}

{{ the_priests_tale }} tells the story of the priest's mentor, Father Paul
Duré, who is banished to Hyperion after faking evidence of a pre-human
Christian civilization on Armaghast. On Hyperion, Duré ventures deep into the
wilderness in search of the Bikura: the descendants of settlers from a crashed
ship. He finds them living by a twisted Christianity, one that promises
eternal life not through faith, but through the cruciform parasite that
revives its hosts in a grotesque parody of the resurrection.

Here, the Catholic Church represents the old order being swept away by new,
distorted religions. This tale inverts {{ keats_lastname_possessive }} idea
that the new triumphs because it is beautiful---the Bikura are hideously
disfigured. Duré suffers spiritually and physically, enduring a crisis of
faith and eventually crucifying himself on a Tesla tree for seven years to
defeat the parasite. His diary becomes the means by which he turns that
suffering into understanding.

{{ the_priests_tale }} is thematically similar to {{ conrads }} {{
heart_of_darkness }}, with Duré journeying into the wilderness only to uncover
a horrifying truth about faith and humanity. It also reminded me of {{ clarkes
}} {{ the_star }}, where a Jesuit's faith is shaken after learning that the
star of Bethlehem was born from the destruction of an alien civilization, and
{{ bradburys }} {{ the_man }}, where Jesus wanders from planet to planet.

#### {% short_story_title "The Soldier's Tale" %}

{{ the_soldiers_tale }} is military sci-fi that follows Fedmahn Kassad from
his training as a FORCE commando, through his commission and suppression of
various uprisings, and finally into battle against the Ousters. In the middle
of these conflicts, he is visited by a mysterious woman named Moneta, who
appears at the moments of greatest violence. Her name comes from the goddess
of memory in {{ keats_lastname_possessive }} {{ hyperion_keats }}. This story
is our first real hint that the Hegemony isn't what it seems---that its power
rests on brutality and hidden evils.

The story first shows the Hegemony as an old order able to hold off
challengers again and again, but then reveals the Ousters as the possible
heirs to the throne. Moneta herself ties beauty and power together,
effortlessly destroying out Ouster landing parties.

{{ the_soldiers_tale }} references John Carter from {{ burroughss }} {{
john_carter }}. The scene where he programs a surgical robot to attack the
Ousters is directly referenced in {{ tchaikovskys }} {{ lords }}. The
reference to "rock and thighbone duels" reminds me of {{ space_odyssey }}. The
virtual battles are seen again in {{ bankss }} {{ surface_detail }}, and the
semi-sentient space suits call back to his short story {{ descendant }}.

The story also has one of my favorite lines from the whole book:

> Firing squads had been busy day and night settling ancient theological
> disputes...

#### {% short_story_title "The Poet's Tale" %}

{{ the_poets_tale }} tells the story of Martin Silenus, born on Old Earth
before the Great Mistake destroyed it. He becomes an author, writing popular
books and unpopular poetry, before traveling with Sad King Billy to Hyperion.
There, Silenus discovers his muse in the Shrike as it murders the other
artists one by one. Left alone, Silenus becomes convinced that his poetry not
only responds to the killings but may have summoned the Shrike in the first
place.

Silenus watches the old order, Earth, fall, replaced by the Hegemony. He
writes his <cite class="book-title">Hyperion Cantos</cite> as a lament,
claiming that humanity doomed itself by destroying its homeworld and would in
turn be destroyed and replaced. His belief is explicitly Keatsian: that great
poetry can shape the physical world, just as he thinks his <cite
class="book-title">Cantos</cite> summons the Shrike. Silenus is only able to
write in the midst of pain, first during his exile on Heaven's Gate and later
on Hyperion as the Shrike is cutting down the other artists. His role is to
witness the fall of humanity and transform that suffering into his greatest
work of art.

In {{ the_poets_tale }}, Silenus "writes" works based on real ones. His <cite
class="book-title">Dying Earth</cite> borrows from {{ vances }} {{ dying_earth
}}, and his <cite class="book-title">Hyperion Cantos</cite> is the very text
we are reading, collapsing reality into art. King Billy tries to destroy the
<cite class="book-title">Hyperion Cantos</cite> by burning it in a fountain
with a statue of [Laocoön][laocoon]. Like the Greek priest, Billy is killed
for opposing divine power. The statue itself---Laocoön and his sons writhing
in the grip of serpents---embodies suffering turned into art.

[laocoon]: https://en.wikipedia.org/wiki/Laoco%C3%B6n

Because it is a story about writing, {{ the_poets_tale }} makes the most
allusions to other works. The Shrike is directly compared to Grendel from {{
beowulf }}. It mentions Huck and Jim from {{ twains }} {{ huckleberry_finn }},
Sherlock and Moriarty from {{ doyles }} {{ the_final_problem }}, and the Eloi
and Morlocks from {{ wellss }} {{ time_machine }}. Silenus even cites a fake
book by <span class="author-name">Stukatsky</span>, almost certainly a
reference to {{ arkady_and_boris_strugatsky }}.

{{ the_poets_tale }} also reminded me other other stories. The super-rich
staying behind to die on Earth reminded me of the dynasties in {{ hamiltons }}
{{ judas_unchained }}. The TechnoCore rebelling against its makers was like
the Hivers in {{ tchaikovskys }} {{ shards_of_earth }}. The bio-sculptors
brought to mind Ximenyr from {{ hydrogen_sonata }}. The debates in the All
Thing recalled Locke and Demosthenes shaping public opinion in {{ cards }} {{
enders_game }}. Even the android honorific "A." mirrors the "R." used by
robots in {{ asimovs }} {{ steel }}.

#### {% short_story_title "The Scholar's Tale" %}

{{ the_scholars_tale }} retells the {{ binding }} from {{ genesis }}. Sol
Weintraub is a philosopher studying {{ kierkegaard }}, whose daughter Rachel
contracts Merlin's disease while researching the time tombs on Hyperion. The
disease makes her age backwards, forgetting each morning what happened in her
future. God---or the Shrike---appears to Sol in dreams and demands that he
bring Rachel to Hyperion to sacrifice her, just as Abraham was asked to
sacrifice Isaac. The irony is heavy: <!-- TODO: Heavy? Eh... --> Sol is an
expert in {{ kierkegaard_lastname }}, whose {{ fear_and_trembling }} is about
that same ethical dilemma.

In Sol's tale, the fall is of the rational universe---where God honors His
covenants---into one that defies logic, where Earth has been destroyed and God
demands Rachel's sacrifice. Suffering and knowledge are inverted in this
story, with Sol and his family suffering terribly as Rachel ages backwards and
loses her identity while his knowledge is powerless against the disease. He
hopes---irrationally as matches the new order---that Hyperion holds a cure.

This is one of my favorite stories. As a father, it's hard to read <!-- WHY?
-->, but it also makes me more grateful for my own children. I cried both
times I read it. It reminded me a little of {{ keyss }} {{
flowers_for_algernon }}, with the way it charts Rachel's mental decline, but
this one hit me much harder.

#### {% short_story_title "The Detective's Tale" %}

{{ the_detectives_tale }} is a hard-boiled cyberpunk story, like a {{ gibson
}} story written by {{ chandler }}. Brawne Lamia[^fanny], a Lususian detective, is
hired by an AI cybrid recreation of John "Johnny" Keats to investigate his own
murder---the sudden disconnect between AI and cybrid body that erased his
recent memories. She soon learns the TechnoCore has three factions---the
Stables, the Volatiles, and the Ultimates. Only one wants humanity to survive,
yet all three are obsessed with Hyperion, a place their predictive routines
can't explain.

[^fanny]: Named after {{ keatss }} real-life lover [Fanny Brawne][fb].

[fb]: https://en.wikipedia.org/wiki/Fanny_Brawne

This tale shows the fall of the Hegemony and its possible replacement by the
TechnoCore, led by the genocidal Volatiles. The Keats cybrid is beautiful in
mind and body, seeking the truth of his death; he is literally a poet built by
the TechnoCore to understand both humanity and Hyperion. Brawne loses her
father, then her lover Johnny, and is nearly killed in a firefight outside the
Shrike Temple. From this suffering, she uncovers the TechnoCore's plans---and
carries Johnny's personality preserved in a Schrön loop inside her head.

<!-- TODO: Make this paragraph sounds less bad -->
{{ the_detectives_tale }} references a wide range of works. The cowboys in
cyberspace are straight from {{ neuromancer }}, <!-- TODO: Don't love
lampshaded --> lampshaded by naming one of them Gibson. Brawne has a Schrön
loop to transport data like {{ johnny_mnemonic }}. There's a reference to {{
orwells }} Big Brother from {{ nineteen_eighty_four }}. Johnny's desire to be
human is straight out of {{ collodis }} {{ pinocchio }}. The Shrike possibly
being sent back in time by the TechnoCore or the Ousters to change their
future is directly from {{ terminator }}. The hacking as battle with the
TechnoCore foreshadows the virtual battles of {{ surface_detail }}. And the
way the Keats cybrid was trained by compiling all of the author {{
keats_lastname_possessive }} writings was like a modern large language model.

#### {% short_story_title "The Consul's Tale" %}

{{ the_consuls_tale }} is sci-fi romance based on {{ shakespeares }} {{
romeo_and_juliet }}, except the insurmountable force separating the couple
isn't their feuding families, but the laws of physics and time dilation.

The tale follows the Consul's grandfather, Merin, who falls in love with a
native woman named Siri while on unauthorized shore leave on the water-world
Maui-Covenant. Their romance is cut short when Siri's cousin kills Merin's
friend, echoing Tybalt killing Mercutio in {{ romeo_and_juliet }}. Forced to
flee, Merin and Siri meet only a handful of times across her entire life,
stretched by relativity into decades for her but only a few years for him.
Their affair becomes legend, and Siri convinces Merin to resist the Hegemony's
assimilation of her world. After her death, Merin honors her by sabotaging the
project and sparking a rebellion in her name.

Here we also learn that the Hegemony and the TechnoCore conspired to destroy
Earth with the Great Mistake, and that the Hegemony has been committing quiet
genocide against other intelligent species, including the Human Ousters. The
Consul confesses to betraying the Hegemony to the Ousters, then
double-crossing the Ousters to unleash the Shrike and force a war.

This story shows the fall of two orders: first Maui-Covenant, destroyed by the
Hegemony, and then the Hegemony itself, undone by the Ousters with the
Consul's help. The Consul flips {{ keats_lastname_possessive }} idea that
beauty and power go together. For him, the Hegemony is ugly, and destroying it
is an act of beauty. He suffers the slow loss of Siri, but through it learns
what the Hegemony truly is.

{{ the_consuls_tale }} reminded me of other works: the talking dolphins are
straight out of {{ adamss }} {{ hitchhikers_guide }} or {{ brins }} {{
sundiver }}. Siri's gift of a powerful gun to Merin reminded me of {{ bankss
}} {{ gift_from_the_culture }}.

### Other Works


{% comment %}

==============
The Old Review
==============

Previous rating and date
date: 2023-10-17
rating: 4

{% endcomment %}
<details markdown="1">
  <summary>
    <h2 class="book-review-headline">Previous Review</h2>
  </summary>
{% rating_stars 4 %}

{{ this_book }} was not at all the book I expected. To give you an idea of how
much I misjudged it, about a third of the way through I would have rated it
two stars and almost put it down, about two-thirds of the way through I was
solidly at three stars, and by the end I was up to four. It was not the
all-time great I was promised, but it was very good.

It is told as the tale of six different pilgrims traveling to the planet
Hyperion to visit the Shrike, a cruel, death-god-like figure. {{ this_book }}
is very much {{ canterbury }} in space. At first the stories seem unconnected,
but as the pilgrims travel and tell their tales we realize they are all
connected, and they reveal a hint at the wider universe that the book takes
place in. The book ends "suddenly" but the sequel, {{ fall_hyperion }}, picks
up right where {{ this_book }} leaves off.

A theme that runs through the book is "the old gods replaced by the new",
based on {{ keatss }} {{ hyperion_keats }} poem about the [Greek Titans
falling to the new Gods of Olympus][titanomachy]. We see this with the Humans
and the AI TechnoCore, the humans and the Ousters (a breakaway post-human
faction), the Scholar and the Old Testament God, and Catholicism and the new
religions.

### {% short_story_title "The Priest's Tale" %}
{% rating_stars 2 %}

I think this story is supposed to be carried by the mystery, but it didn't
hook me. Not as much a horror story as I assumed halfway through, it's still a
little too far into the genre for me.

### {% short_story_title "The Soldier's Tale" %}
{% rating_stars 5 %}

A story with action, mystery, and our first really good look at both the
Ousters and the Shrike.

### {% short_story_title "The Poet's Tale" %}
{% rating_stars 3 %}

Starts off slow, but the payoff is good. Silenus, the poet, is a spoiled
annoying character, but the way he comes to believe that he has set the Shrike
loose with his writing is exciting.

### {% short_story_title "The Scholar's Tale" %}
{% rating_stars 5 %}

Emotional, heartbreaking. In the Scholar's Tale we learn why Sol Weintraub
brought a two-week old baby---one getting younger all the time---on the deadly
pilgrimage.

### {% short_story_title "The Detective's Tale" %}
{% rating_stars 5 %}

This story gives us a great look at the TechnoCore: the artificial
intelligences that seceded from humanity but are still tightly involved in our
affairs. The story hints that the TechnoCore's three factions---the stables,
the volatiles, and the ultimates---are engineering the coming war over
Hyperion. The end is a bit too 1980s cyberpunk (dodging code phages in the
neon cyberweb!), but the characters and history are compelling.

### {% short_story_title "The Consul's Tale" %}
{% rating_stars 4 %}

The final tale starts off as a love story between a planet-bound woman and a
space-faring man who, because of relativity, ages much slower. But at the very
end the story twists and it becomes a tale of revolution. It explains why and
how the Consul intentionally set the entire Hyperion crisis in motion.

</details>
