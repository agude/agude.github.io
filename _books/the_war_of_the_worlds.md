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
witnesses a terrifying invasion by Martians with advanced weaponry.

{% capture this_book %}<cite class="book-title">{{ page.title }}</cite>{% endcapture %}
{% capture the_authors %}<span class="author-name">{{ page.book_authors }}</span>'s{% endcapture %}
{% capture the_authors_lastname %}<span class="author-name">{{ page.book_authors | split: " " | last }}</span>{% endcapture %}

{% capture orsons %}{% author_link "Orson Welles" possessive %}{% endcapture %}
{% capture pal %}{% author_link "George Pal" %}{% endcapture %}
{% capture spielberg %}{% author_link "Steven Spielberg" %}{% endcapture %}

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

{% capture clarke %}{% author_link "Arthur C. Clarke" %}{% endcapture %}
{% capture heinlein %}{% author_link "Robert A. Heinlein" %}{% endcapture %}
{% capture bradbury %}{% author_link "Ray Bradbury" %}{% endcapture %}
{% capture verne %}{% author_link "Jules Verne" %}{% endcapture %}

{{ the_authors }} {{ this_book }} is a sci-fi classic. It describes the
invasion of Earth by Martians and their tripods, the destruction they unleash,
and their eventual defeat by bacteria. It was one of the first science fiction
books I read as a kid, and it helped shape the kind of stories I've loved ever
since. It's hugely influential, having been adapted for radio and film
multiple times, including [{{ orsons }} radio drama][radio] and films by [{{
pal }}][pal] and [{{ spielberg }}][spielberg].

[radio]: https://en.wikipedia.org/wiki/The_War_of_the_Worlds_(1938_radio_drama)
[pal]: https://en.wikipedia.org/wiki/The_War_of_the_Worlds_(1953_film)
[spielberg]: https://en.wikipedia.org/wiki/War_of_the_Worlds_(2005_film)

This book is a version of the [invasion novel][invasion] popular at the time,
except that the invaders are Martians instead of European powers. It's similar
to {{ chesneys }} {{ dorkink }}, which kicked off the genre. Both feature
surprise attacks on England by technologically superior enemies and are set in
Surrey. Woking, where the Martians land, is less than a dozen miles from
Dorking, where the climactic battle and the British Army's defeat take place.

[invasion]: https://en.wikipedia.org/wiki/Invasion_literature

{{ this_book }} is political through and through. It was inspired by the
horrors of colonialism and flips the power dynamic: suddenly the English are
at the mercy of a greater, indifferent force bent on wiping them out. It also
develops several ideas that still resonate. The curate sees the Martians as
divine punishment for humanity's sins, much like some modern Christians see
god's hand in natural disasters. He regrets not using his position to speak
out against inequality and the treatment of the poor. The artilleryman, by
contrast, sees the Martians as a necessary reckoning---cleansing humanity of
the weakness brought on by modern life. That lines up well with a lot of
contemporary conservative rhetoric.
 
But the style of the book makes it hard to love. The prose is great---in a way
that {{ suns }}, {{ shards }}, and {{ three }} are not---but the narrative
takes long digressions and slows the pacing as the author focuses on small
details. It reminds me a bit of {{ moby }} and {{ leagues }}, though the
digressions are not quite as meandering. Still, those digressions---and the
narrator's journalistic tone---add a sense of realism and immediacy. At the
same time, his total lack of agency reinforces the feeling of humanity's
helplessness.

{{ this_book }} deeply influenced how science fiction writers imagined Mars.
The idea of ancient Martian civilizations appears in {{ burroughs }} {{
barsoom_series }}, starting with {{ barsoom1 }}, and in {{ bradburys }} {{
chronicles }}. The tripods and aliens who don't need to eat or sleep clearly
shaped {{ christophers }} {{ tripod_series }}, beginning with {{ tripod1 }}
and its series prequel, {{ tripod0 }}. Of my recent reads, the refugee
flotilla fleeing the Martians reminded me of {{ winterss }} {{ tlpm_series }},
especially {{ tlpm2 }}. And of course, the HMS _Thunder Child_ charging in to
defend the evacuees brought to mind the ship of the same name facing down the
Architects in {{ tchaikovskys }} {{ shards }}.

I first read {{ this_book }} when I was young, and re-reading it now was a
nostalgic experience. It makes me want to revisit some of the other authors I
loved back then, like {{ clarke }}, {{ bradbury }}, and {{ heinlein }}, as
well as {{ the_authors_lastname }}'s contemporaries like {{ verne }}. I'm
curious to see how another thirty years of reading and life experience will
change the way I see their work.
