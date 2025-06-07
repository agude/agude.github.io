---
date: 2025-06-06 12:27:48 -0700
title: Bolo
book_authors: Keith Laumer
series: Bolo
book_number: 1
rating: 3
image: /books/covers/bolo.jpg
---

<cite class="book-title">{{ page.title }}</cite>, by <span
class="author-name">{{ page.book_authors }}</span>, is the first book in the
<span class="book-series">{{ page.series }}</span> series. It is a collection of
seven novellas and short stories, all featuring Bolos.

{% capture this_book %}<cite class="book-title">{{ page.title }}</cite>{% endcapture %}
{% capture the_author %}<span class="author-name">{{ page.book_authors }}</span>{% endcapture %}
{% capture the_authors_lastname %}<span class="author-name">{{ page.book_authors | split: " " | last }}</span>{% endcapture %}
{% capture the_authors %}{% author_link page.book_authors possessive %}{% endcapture %}
{% capture the_author_link %}{% author_link page.book_authors %}{% endcapture %}
{% capture this_series %}{% series_text page.series %}{% endcapture %}

{% capture bolo1 %}{% book_link "Bolo" %}{% endcapture %}
{% capture bolo2 %}{% book_link "Rogue Bolo" %}{% endcapture %}
{% capture bolo3 %}{% book_link "The Stars Must Wait" %}{% endcapture %}
{% capture bolo10 %}{% book_link "Honor of the Regiment" %}{% endcapture %}
{% capture bolo11 %}{% book_link "The Unconquerable" %}{% endcapture %}
{% capture bolo12 %}{% book_link "The Triumphant" %}{% endcapture %}

{% capture retief %}{% series_link "Retief" %}{% endcapture %}

{% capture fire %}{% book_link "A Fire Upon The Deep" %}{% endcapture %}
{% capture childhoods %}{% book_link "Childhoods End" %}{% endcapture %}
{% capture so2001 %}{% book_link "2001: A Space Odyssey" %}{% endcapture %}
{% capture zanzibar %}{% book_link "Stand on Zanzibar" %}{% endcapture %}
{% capture bob1 %}{% book_link "We Are Legion (We Are Bob)" %}{% endcapture %}

{% capture history %}[<cite class="short-story-title">A Short History of the Bolo Fighting Machines</cite>](#a-short-history-of-the-bolo-fighting-machines){% endcapture %}
{% capture trolls %}[<cite class="short-story-title">The Night of the Trolls</cite>](#the-night-of-the-trolls){% endcapture %}
{% capture courier %}[<cite class="short-story-title">Courier</cite>](#courier){% endcapture %}
{% capture field_test %}[<cite class="short-story-title">Field Test</cite>](#field-test){% endcapture %}
{% capture last_command %}[<cite class="short-story-title">The Last Command</cite>](#the-last-command){% endcapture %}
{% capture relic %}[<cite class="short-story-title">A Relic of War</cite>](#a-relic-of-war){% endcapture %}
{% capture combat_unit %}[<cite class="short-story-title">Combat Unit</cite>](#combat-unit){% endcapture %}

I read the Bolo anthologies---{{ bolo10 }}, {{ bolo11 }}, {{ bolo12}},
etc.---about twenty-five years ago, and then read every other Bolo book I
could find at the used book store. Eventually I picked up {{ this_book }}.
Now that I'm rereading it the stories are familiar in the same way that {{
fire }} or {{ childhoods }} were: the details are fuzzy but the overall arc
is clear.

With two more decades of sci-fi in my head, this book doesn't rank as great.
Some of the stories, like {{ last_command }} and {{ combat_unit }}, start to
hit on the format that makes the later anthologies work: getting directly
inside the Bolo's minds and seeing what and how they're thinking. But the
other stories---{{ trolls }} and {{ courier }} especially---treat the Bolos as
set pieces and are far the worse for it.

Another thing the three best stories---{{ last_command }}, {{ relic }}, and {{
combat_unit }}---get right all take place well _after_ the war. This lets them
explore the theme of duty in more depth. It is easy to be honorable, to do
ones duty, when the enemy is charging across the battlefield, it is harder
when you've been forgotten and abandoned by those you saved. It allows {{
the_authors_lastname }} to explore other themes as well, like loss and death,
and what it means to be alive.

### <cite class="short-story-title">A Short History of the Bolo Fighting Machines</cite>
{% rating_stars 3 %}

An in-universe explanation of how Bolos came to be. Not really a story.

### <cite class="short-story-title">The Night of the Trolls</cite>
{% rating_stars 3 %}

A novella version of {{ the_authors }} later novel {{ bolo3 }}. The main
character annoys me with how he talks and punches his way through the story.
The plot---a man wakes up from stasis and discovers he's survived a nuclear
apocalypse---is predictable. The Bolos are the eponymous "trolls", and they're
just an obstacle to overcome, not a character like in the more successful
stories.

### <cite class="short-story-title">Courier</cite>
{% rating_stars 2 %}

A {{ retief }} story that just happens to have a Bolo at the end. Retief
punches his way onto a planet, discovers the locals can read minds, punches a
Bolo (sort of), and skis off into the sunset with a dame. I can't really stand
Retief, whose lack of subtlety is apparently balanced by his upper body
strength and annoyingly accurate confidence. Feels like a <cite
class="tv-show-title">Star Trek: The Original Series</cite> episode, but with
Retief as a less intellectual (I know!) Kirk.

### <cite class="short-story-title">Field Test</cite>
{% rating_stars 3 %}

The first sentient Bolo---the Mark XX---is sent untested into combat as a
last-ditch effort to save a city. It "fails" by performing a suboptimal
suicidal charge which nonetheless wins the day, driven by its sense of duty
and honor. Told in a series of paragraph-length chapters, each one a different
piece of in-universe media---from letters to speeches to short
conversations---reminiscent of how {{ zanzibar }} is structured.

### <cite class="short-story-title">The Last Command</cite>
{% rating_stars 4 %}

A Bolo wakes up after being decommissioned and buried, and assumes it's under
attack. Only the timely arrival of its ancient commander saves a local city.
There is a heart-strings tugging moment at the end where the dying Bolo asks
how far until it reaches the maintenance bay, and it's dying command replies
""It's a long way, Lenny... But I'm coming with you..." That connection
between human and machine is a constant theme in the later Bolo books.

### <cite class="short-story-title">A Relic of War</cite>
{% rating_stars 3 %}

An abandoned Bolo is found by the government, who mean to shut it down---only
to accidentally awaken the creatures the Bolo originally fought. In the end,
the Bolo allows itself to be shut down to protect the town from itself, which
reminded me a little of shutting down HAL in {{ so2001 }}.

### <cite class="short-story-title">Combat Unit</cite>
{% rating_stars 4 %}

A damaged Bolo wakes up in a repair bay and suspects it's been captured and is
under attack. The twist, set up by placing this story after {{ field_test }}
and {{ last_command }}---both of which feature Bolos incorrectly assuming
they're under attack---is that this time, it _really is_. A fun way of showing
how dangerous Bolos are even when stripped of all "weapons." My favorite part
was when the Bolo hacks the site's power plant and causes a nuclear meltdown.
The story is a bit like when Bob escapes the research center in {{ bob1 }}.
