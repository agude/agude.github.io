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
follows seven pilgrims as they travel to the Time Tombs on Hyperion to
petition the Shrike. Along the way, each tells their own story, weaving
together history, myth, and prophecy to tell of the impending downfall of man.

{% capture this_book %}<cite class="book-title">{{ page.title }}</cite>{% endcapture %}
{% capture the_author %}<span class="author-name">{{ page.book_authors }}</span>{% endcapture %}
{% capture author_last_name_text %}{{ page.book_authors | split: " " | last }}{% endcapture %}

{% capture the_priests_tale %}{% short_story_link "The Priest's Tale" %}{% endcapture %}
{% capture the_soldiers_tale %}{% short_story_link "The Soldier's Tale" %}{% endcapture %}
{% capture the_poets_tale %}{% short_story_link "The Poet's Tale" %}{% endcapture %}
{% capture the_scholars_tale %}{% short_story_link "The Scholar's Tale" %}{% endcapture %}
{% capture the_detectives_tale %}{% short_story_link "The Detective's Tale" %}{% endcapture %}
{% capture the_consuls_tale %}{% short_story_link "The Consul's Tale" %}{% endcapture %}

{% comment %} Foundational Works for the Review {% endcomment %}

{% capture fall_hyperion %}{% book_link "The Fall of Hyperion" %}{% endcapture %}
{% capture endymion %}{% book_link "Endymion" %}{% endcapture %}
{% capture rise_of_endymion %}{% book_link "The Rise of Endymion" %}{% endcapture %}

{% capture keatss %}{% author_link "John Keats" possessive %}{% endcapture %}
{% capture keats_lastname %}{% author_link "John Keats" link_text="Keats" %}{% endcapture %}
{% capture keats_lastname_possessive %}{% author_link "John Keats" link_text="Keats" possessive %}{% endcapture %}
{% capture hyperion_keats %}{% book_link "Hyperion" author="John Keats" %}{% endcapture %}

{% capture chaucers %}{% author_link "Geoffrey Chaucer" possessive %}{% endcapture %}
{% capture canterbury %}{% book_link "The Canterbury Tales" %}{% endcapture %}

{% comment %} Iain M. Banks (The Culture etc.) {% endcomment %}

{% capture bankss %}{% author_link "Iain M. Banks" possessive %}{% endcapture %}
{% capture surface_detail %}{% book_link "Surface Detail" %}{% endcapture %}
{% capture hydrogen_sonata %}{% book_link "The Hydrogen Sonata" %}{% endcapture %}
{% capture gift_from_the_culture %}{% short_story_link "A Gift from the Culture" %}{% endcapture %}
{% capture descendant %}{% short_story_link "Descendant" %}{% endcapture %}

{% comment %} Other Science Fiction Authors & Works {% endcomment %}

{% capture clarkes %}{% author_link "Arthur C. Clarke" possessive %}{% endcapture %}
{% capture the_star %}{% short_story_link "The Star" %}{% endcapture %}
{% capture space_odyssey %}{% book_link "2001: A Space Odyssey" %}{% endcapture %}

{% capture asimovs %}{% author_link "Isaac Asimov" possessive %}{% endcapture %}
{% capture steel %}{% short_story_link "The Caves of Steel" %}{% endcapture %}

{% capture bradburys %}{% author_link "Ray Bradbury" possessive %}{% endcapture %}
{% capture the_man %}{% short_story_link "The Man" %}{% endcapture %}

{% capture conrads %}{% author_link "Joseph Conrad" possessive %}{% endcapture %}
{% capture heart_of_darkness %}{% book_link "Heart of Darkness" %}{% endcapture %}

{% capture vances %}{% author_link "Jack Vance" possessive %}{% endcapture %}
{% capture dying_earth %}{% book_link "The Dying Earth" %}{% endcapture %}

{% capture hamiltons %}{% author_link "Peter F. Hamilton" possessive %}{% endcapture %}
{% capture judas_unchained %}{% book_link "Judas Unchained" %}{% endcapture %}

{% capture cards %}{% author_link "Orson Scott Card" possessive %}{% endcapture %}
{% capture enders_game %}{% book_link "Ender's Game" %}{% endcapture %}

{% capture arkady_and_boris_strugatsky %}{% author_link "Arkady Strugatsky" link_text="Arkady" %} and {% author_link "Boris Strugatsky" %}{% endcapture %}

{% capture le_guins %}{% author_link "Ursula K. Le Guin" possessive %}{% endcapture %}
{% capture left_hand_of_darkness %}{% book_link "The Left Hand of Darkness" %}{% endcapture %}
{% capture rocannon %}{% book_link "Rocannon's World" %}{% endcapture %}
{% capture hainish_cycle %}{% series_link "Hainish Cycle" %}{% endcapture %}

{% capture keyess %}{% author_link "Daniel Keyes" possessive %}{% endcapture %}
{% capture flowers_for_algernon %}{% book_link "Flowers for Algernon" %}{% endcapture %}

{% capture gibson %}{% author_link "William Gibson" %}{% endcapture %}
{% capture johnny_mnemonic %}{% book_link "Johnny Mnemonic" %}{% endcapture %}
{% capture neuromancer %}{% book_link "Neuromancer" %}{% endcapture %}

{% capture orwells %}{% author_link "George Orwell" possessive %}{% endcapture %}
{% capture nineteen_eighty_four %}{% book_link "1984" %}{% endcapture %}

{% capture tchaikovskys %}{% author_link "Adrian Tchaikovsky" possessive %}{% endcapture %}
{% capture shards_of_earth %}{% book_link "Shards of Earth" %}{% endcapture %}
{% capture lords %}{% book_link "Lords of Uncreation" %}{% endcapture %}

{% capture adamss %}{% author_link "Douglas Adams" possessive %}{% endcapture %}
{% capture hitchhikers_guide %}{% book_link "The Hitchhiker's Guide to the Galaxy" %}{% endcapture %}

{% capture brins %}{% author_link "David Brin" possessive %}{% endcapture %}
{% capture sundiver %}{% book_link "Sundiver" %}{% endcapture %}

{% capture burroughss %}{% author_link "Edgar Rice Burroughs" possessive %}{% endcapture %}
{% capture john_carter %}{% book_link "A Princess of Mars" %}{% endcapture %}

{% capture hg_wellss %}{% author_link "H. G. Wells" possessive %}{% endcapture %}
{% capture time_machine %}{% book_link "The Time Machine" %}{% endcapture %}

{% capture chandler %}{% author_link "Raymond Chandler" %}{% endcapture %}

{% comment %} Classic & Literary Authors {% endcomment %}

{% capture genesis %}{% short_story_link "The Book of Genesis" %}{% endcapture %}
{% capture binding %}{% short_story_link "Binding of Isaac" %}{% endcapture %}

{% capture twains %}{% author_link "Mark Twain" possessive %}{% endcapture %}
{% capture huckleberry_finn %}{% book_link "Adventures of Huckleberry Finn" %}{% endcapture %}

{% capture doyles %}{% author_link "Arthur Conan Doyle" possessive %}{% endcapture %}
{% capture the_final_problem %}{% short_story_link "The Final Problem" %}{% endcapture %}

{% capture collodis %}{% author_link "Carlo Collodi" possessive %}{% endcapture %}
{% capture pinocchio %}{% book_link "The Adventures of Pinocchio" %}{% endcapture %}

{% capture shakespeares %}{% author_link "William Shakespeare" link_text="Shakespeare" possessive %}{% endcapture %}
{% capture romeo_and_juliet %}{% book_link "Romeo and Juliet" %}{% endcapture %}

{% capture beowulf %}{% book_link "Beowulf" %}{% endcapture %}

{% capture kierkegaard %}{% author_link "Søren Kierkegaard" %}{% endcapture %}
{% capture kierkegaard_lastname %}{% author_link "Søren Kierkegaard" link_text="Kierkegaard" %}{% endcapture %}
{% capture fear_and_trembling %}{% book_link "Fear and Trembling" %}{% endcapture %}

{% capture terminator %}<cite class="movie-title">The Terminator</cite>{% endcapture %}

{% capture bolo12 %}{% book_link "The Triumphant" %}{% endcapture %}
{% capture bolo13 %}{% book_link "Last Stand" %}{% endcapture %}
{% capture titan %}{% book_link "The Sirens of Titan" %}{% endcapture %}
{% capture mb6 %}{% book_link "Fugitive Telemetry" %}{% endcapture %}

I didn't love {{ this_book }} when [I first read it][first_read] about two
years ago. It's a book full of deep intertextuality, influenced heavily by {{
keatss }} {{ hyperion_keats }}, but also by {{ chaucers }} {{ canterbury }}.
{{ author_last_name_text }} uses that classic pilgrimage structure as a frame
to present six different stories, each one a pastiche of a different genre.
But I missed almost all of that the first time. Instead, I was distracted by
lasers, barbarians, and the god-like Shrike covered in blades.

[first_read]: {% link _books/hyperion/review-2023-10-17.md %}

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
}} uses each story to explore a different genre, but also to explore {{
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

{{ the_soldiers_tale }} is military sci-fi that follows Colonel Fedmahn Kassad
from his training as a FORCE commando, through his commission and suppression
of various uprisings, and finally into battle against the Ousters. In the
middle of these conflicts, he is visited by a mysterious woman named Moneta,
who appears at the moments of greatest violence. Her name comes from the
goddess of memory in {{ keats_lastname_possessive }} {{ hyperion_keats }}.
This story is our first real hint that the Hegemony isn't what it seems---that
its power rests on brutality and hidden evils.

The story first shows the Hegemony as an old order able to hold off
challengers again and again, but then reveals the Ousters as the possible
heirs to the throne. Moneta herself ties beauty and power together,
effortlessly destroying Ouster landing parties.

{{ the_soldiers_tale }} references John Carter from {{ burroughss }} {{
john_carter }}. The scene where Kassad programs a surgical robot to attack the
Ousters is directly referenced in {{ tchaikovskys }} {{ lords }}. The
reference to "rock and thighbone duels" reminds me of {{ space_odyssey }}. The
virtual battles are seen again in {{ bankss }} {{ surface_detail }}, and the
semi-sentient spacesuits call back to his short story {{ descendant }}.

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
and Morlocks from {{ hg_wellss }} {{ time_machine }}. Silenus even cites a
fake book by a <span class="author-name">Stukatsky</span>, almost certainly a
reference to {{ arkady_and_boris_strugatsky }}.

{{ the_poets_tale }} also reminded me of other stories. The super-rich staying
behind to die on Earth reminded me of the dynasties in {{ hamiltons }} {{
judas_unchained }}. The TechnoCore rebelling against its makers was like the
Hivers in {{ tchaikovskys }} {{ shards_of_earth }}. The bio-sculptors brought
to mind Ximenyr from {{ hydrogen_sonata }}. The debates in the All Thing
recalled Locke and Demosthenes shaping public opinion in {{ cards }} {{
enders_game }}. Even the android honorific "A." mirrors the "R." used by
robots in {{ asimovs }} {{ steel }}.

#### {% short_story_title "The Scholar's Tale" %}

{{ the_scholars_tale }} retells the {{ binding }} from {{ genesis }}. Sol
Weintraub is a philosopher studying {{ kierkegaard }}, whose daughter Rachel
contracts Merlin's disease while researching the Time Tombs on Hyperion. The
disease makes her age backward, forgetting each morning what happened in her
future. God---or the Shrike---appears to Weintraub in dreams and demands that
he bring Rachel to Hyperion to sacrifice her, just as Abraham was asked to
sacrifice Isaac. The irony is unavoidable: Weintraub is an expert in {{
kierkegaard_lastname }}, whose {{ fear_and_trembling }} is about the same
ethical dilemma he now faces.

In Weintraub's tale, the fall is of the rational universe---where God honors
His covenants---into one that defies logic, where Earth has been destroyed and
God demands Rachel's sacrifice. Suffering and knowledge are inverted in this
story, with Weintraub and his family suffering terribly as Rachel ages
backward and loses her identity while his knowledge is powerless against the
disease. He hopes---irrationally, as matches the new order---that Hyperion
holds a cure.

This is one of my favorite stories. As a father, it's hard to read because so
much of Weintraub's struggle is about helplessly watching his child slip away,
but it also makes me more grateful for my own children. I cried both times I
read it. It reminded me a little of {{ keyess }} {{ flowers_for_algernon }},
with the way it charts Rachel's mental decline, but this one hit me much
harder.

{{ the_scholars_tale }} also makes a passing reference to {{ le_guins }}
Ansible, seen in {{ rocannon }}, {{ left_hand_of_darkness }}, and throughout
her {{ hainish_cycle }}. The requirement to sleep to survive faster-than-light
travel without going insane also shows up in {{ tchaikovskys }} {{
shards_of_earth }}.

#### {% short_story_title "The Detective's Tale" %}

{{ the_detectives_tale }} is a hard-boiled cyberpunk story, like a {{ gibson
}} story written by {{ chandler }}. Brawne Lamia,[^fanny] a Lusian detective,
is hired by an AI cybrid recreation of John "Johnny" Keats to investigate his
own murder---the sudden disconnect between the AI and cybrid body that erased
his recent memories. She soon learns the TechnoCore has three factions: the
Stables, the Volatiles, and the Ultimates. Only one wants humanity to survive,
yet all three are obsessed with Hyperion, a place their predictive routines
can't explain.

[^fanny]: Named after {{ keatss }} real-life lover [Fanny Brawne][fb].

[fb]: https://en.wikipedia.org/wiki/Fanny_Brawne

This tale shows the fall of the Hegemony and its possible replacement by the
TechnoCore, led by the genocidal Volatiles. The Keats cybrid is beautiful in
mind and body, seeking the truth of his death; he is literally a poet built by
the TechnoCore to understand both humanity and Hyperion. Lamia loses her
father, then her lover Johnny, and is nearly killed in a firefight outside the
Shrike Temple. From this suffering, she uncovers the TechnoCore's plans---and
carries Johnny's personality preserved in a Schrön loop inside her head.

{{ the_detectives_tale }} references a wide range of works. Its cyberspace
cowboys recall {{ neuromancer }}; one is even named Gibson. Lamia uses a
Schrön loop for data transport, right out of {{ johnny_mnemonic }}. There's an
allusion to {{ orwells }} Big Brother from {{ nineteen_eighty_four }}.
Johnny's yearning for humanity echoes {{ collodis }} {{ pinocchio }}. The
possibility that the Shrike was sent back in time by the TechnoCore or the
Ousters to change their future is directly from {{ terminator }}. The hacking
as a battle with the TechnoCore foreshadows the same scene in {{
surface_detail }}. The creation of the Keats cybrid, by compiling all his
written works, reads today like how we train large language models.

#### {% short_story_title "The Consul's Tale" %}

{{ the_consuls_tale }} is a sci-fi romance based on {{ shakespeares }} {{
romeo_and_juliet }}, except the insurmountable force separating the couple
isn't their feuding families, but the laws of physics and time dilation.

The tale follows the Consul's grandfather, Merin Aspic, who falls in love with
a native woman named Siri while on unauthorized shore leave on the water-world
Maui-Covenant. Their romance is cut short when Siri's cousin kills Aspic's
friend, echoing Tybalt killing Mercutio in {{ romeo_and_juliet }}. Forced to
flee, Aspic and Siri meet only a handful of times across her entire life,
stretched by relativity into decades for her but only a few years for him.
Their affair becomes a legend, and Siri convinces Aspic to resist the
Hegemony's assimilation of her world. After her death, Aspic honors her by
sabotaging the project and sparking a rebellion in her name.

{% comment %}
Should I comment on the reversal?
Hot passion -> slow
Tomb ends the story -> tomb starts the story
{% endcomment %}

Here we also learn that the Hegemony and the TechnoCore conspired to destroy
Earth with the Great Mistake, and that the Hegemony has been committing quiet
genocide against other intelligent species, including the human Ousters. The
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
sundiver }}. Siri's gift of a powerful gun to Aspic reminded me of {{ bankss
}} {{ gift_from_the_culture }}.

### Conclusion

I'm sure it comes through clearly that I had a lot of fun on this second
read-through, trying to pin down all the themes and references. To me, that's
what makes {{ this_book }} a masterpiece: it's a great sci-fi story on its
own, but with levels of meaning hidden below the lasers, barbarians, and
god-like Shrike covered in blades.

The only catch is that {{ this_book }} is just the first half of the story. To
get the full effect you have to read {{ fall_hyperion }}, which I plan to do
again after a taking a quick break to read {{ bolo12 }}, and maybe {{ bolo13
}}, {{ titan }}, and {{ mb6 }}. I'm looking forward to it! And who knows?
Maybe this time I'll make it all the way through {{ endymion }} and {{
rise_of_endymion }}.
