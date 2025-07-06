---
date: 2025-07-06
title: The War of the Worlds
book_authors: H. G. Wells
series: null
book_number: 1
rating: 3
image: /books/covers/the_war_of_the_worlds.jpg
---

<cite class="book-title">{{ page.title }}</cite>, by <span
class="author-name">{{ page.book_authors }}</span>, is a landmark science
fiction novel. It takes place in late Victorian England as an unnamed narrator
witnesses a terrifying invasion of Martians with advanced weaponry.

{% capture this_book %}<cite class="book-title">{{ page.title }}</cite>{% endcapture %}
{% capture the_author %}<span class="author-name">{{ page.book_authors }}</span>{% endcapture %}
{% capture the_authors %}<span class="author-name">{{ page.book_authors }}</span>'s{% endcapture %}
{% capture the_authors_lastname %}<span class="author-name">{{ page.book_authors | split: " " | last }}</span>{% endcapture %}
{% capture the_author_link %}{% author_link page.book_authors %}{% endcapture %}
{% capture the_authors_link %}{% author_link page.book_authors possessive %}{% endcapture %}
{% capture this_series %}{% series_text page.series %}{% endcapture %}

{% capture orsons %}{% author_link "Orson Welles" possessive %}{% endcapture %}
{% capture pals %}{% author_link "George Pal" possessive %}{% endcapture %}
{% capture spielbergs %}{% author_link "Steven Spielberg" possessive %}{% endcapture %}

{% capture dorkink %}{% book_link "The Battle of Dorking: Reminiscences of a Volunteer" link_text="The Battle of Dorking" %}{% endcapture %}
{% capture chesneys %}{% author_link "George Tomkyns Chesney" possessive %}{% endcapture %}

{% capture suns %}{% book_link "House of Suns" %}{% endcapture %}
{% capture shards %}{% book_link "Shards of Earth" %}{% endcapture %}
{% capture three %}{% book_link "The Three-Body Problem" %}{% endcapture %}

{% capture moby %}{% book_link "Moby Dick" %}{% endcapture %}
{% capture leagues  %}{% book_link "Twenty Thousand Leagues Under the Seas" %}{% endcapture %}

{% capture burroughs %}{% author_link "Edgar Rice Burroughs" possessive link_text="Burroughs" %}{% endcapture %}
{% capture barsoom1 %}{% book_link "A Princess of Mars" %}{% endcapture %}
{% capture barsoom_series %}{% series_link "Barsoom" %} series{% endcapture %}

{% capture bradburys  %}{% author_link "Ray Bradbury" possessive link_text="Bradbury" %}{% endcapture %}
{% capture chronicles %}{% book_link "The Martian Chronicles" %}{% endcapture %}

{% capture christophers %}{% author_link "John Christopher" possessive link_text="Christopher" %}{% endcapture %}
{% capture tripod0 %}{% book_link "When the Tripods Came" %}{% endcapture %}
{% capture tripod1 %}{% book_link "The White Mountains" %}{% endcapture %}
{% capture tripod_series %}{% series_link "The Tripods" %} series{% endcapture %}

{% capture winterss %}{% author_link "Ben H. Winters" possessive link_text="Winters" %}{% endcapture %}
{% capture tlpm2 %}{% book_link "Countdown City" %}{% endcapture %}
{% capture tlpm_series %}{% series_link "The Last Policeman" %} series{% endcapture %}

{% capture tchaikovskys %}{% author_link "Adrian Tchaikovsky" possessive link_text="Tchaikovsky" %}{% endcapture %}

{{ the_authors }} {{ this_book }} is a sci-fi classic. It describes the
invasion of Earth by Martians and their tripods, the destruction they unleash,
and their defeat by bacteria. It is hugely influential, being adapted to radio
and film multiple times, including [{{ orsons }} radio drama][radio], and both
[{{ pals }} movie][pal], and [{{ spielbergs }}][spielberg].

[radio]: https://en.wikipedia.org/wiki/The_War_of_the_Worlds_(1938_radio_drama)
[pal]: https://en.wikipedia.org/wiki/The_War_of_the_Worlds_(1953_film)
[spielberg]: https://en.wikipedia.org/wiki/War_of_the_Worlds_(2005_film)

This book is a version of the [invasion novel][invasion] that was popular at
the time, except it substitutes the usuals other European powers for Martians.
It's similar {{ chesneys }} {{ dorkink }}, which started the genre. Both
feature surprise attacks on England by technologically superior foes and take
place in Surrey. Woking, where the Martians first land, is under a dozen miles
from Dorking, where the climatic battle and defeat of British Army by the
German-speaking enemies.

[invasion]: https://en.wikipedia.org/wiki/Invasion_literature

{{ this_book }} is a political book through and through. It was inspired by
the horrors of colonialism, and it shows the effects of these policies by
flipping the power dynamic: suddenly the Englander is at the mercy of a
greater, indifferent power bent on their extinction. It also expands on
several ideas that still resonate. The Curate sees the Martians as divine
retribution for humanity's sins, much as modern Christians see god's hand in
hurricanes and earthquakes. He laments that he did use his position to speak
up against inequality and the treatment of the poor. The artilleryman on the
other hand believes the Martians will rid humanity of the weakness brought on
by modern life, which matches well with many modern conservative movements.
 
But the style of the book makes it hard to love. The prose are great---in a
way that {{ suns }}, {{ shards }}, and {{ three }} are not---but the narrative
takes long digressions and slows the pacing as the author focuses on small
details. It reminds me a bit of {{ moby }} and {{ leagues }}, although the
digressions aren't as long or as far afield. The fact that the narrator has no
agency and serves only to act as our camera also hurt the book.

{{ this_book }} influenced how science fiction authors viewed Mars for years.
The idea that it is the home of ancient civilizations is seen in {{ burroughs
}} {{ barsoom_series }} starting with {{ barsoom1 }}, and in {{ bradburys }}
{{ chronicles }}. The tripods and aliens that don't need to eat or sleep
are a direct influence of {{ christophers }} {{ tripod0 }} and his {{
tripod_series }} starting with {{ tripod1 }}. Of my recent reads, the flotilla
escaping the Martians reminded me of {{ winterss }} {{ tlpm_series }},
specifically {{ tlpm2 }}, and of course the HMS _Thunder Child_ charging in to
save the fleeing refugees reminded me of the ship of the same name confronting
the Architects in {{ tchaikovskys }} {{ shards }}.
