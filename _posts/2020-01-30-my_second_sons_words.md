---
layout: post
title: "My Second Son's Language Development"
description: >
  My second son is a little over two years old. We tracked every word he's
  spoken to watch his language development, and now you can observe it too!
image: /files/my-second-sons-words/teaching_punctuation_by_j_w_orr.png
hide_lead_image: True
image_alt: >
  A woodcut by J. W. Orr showing a man using a blackboard to teach young
  children punctuation.
seo:
  date_modified: 2021-12-19T19:04:19-08:00
categories:
  - childhood-language
  - data-visualization
---

{% capture file_dir %}/files/my-second-sons-words/{% endcapture %}

My second son, Cory, was born in the winter of 2017. Like [my first
son][theo_post], we tracked his language development to see how fast he picked
up the various languages that our family speaks.

[theo_post]: {% post_url 2018-09-30-my_sons_words %}

## The Data

The data was collected in the [same manner as last time][theo_post_data]. The
only difference was I added a new language category for "animal sounds"
because when recording that data for Theo I realized it was hard to tell "moo"
from "mu". A catch-all category for animals made data logging much easier.

[theo_post_data]: {% post_url 2018-09-30-my_sons_words %}#the-data

I had the same data collection difficulties as last time: when Cory was young,
it was hard to decide if he was associating a sound with a concept. When Cory
was older, he was so good at imitating sounds that it was hard to know if he
knew the word or was just repeating what you had said. There was a new
difficulty this time as well: we had our third child just as Cory's language
development exploded. Cory was with his grandparents for a few weeks as we
adjusted to the new baby and so I was not able to record his new words during
that time period.

You can find the Jupyter notebook used to perform this analysis
[here][notebook] ([rendered on Github][rendered]). The data can be found
[here][data].

{% capture notebook_uri %}{{ "Cory's first words.ipynb" | uri_escape }}{% endcapture %}

[notebook]: {{ file_dir }}/{{ notebook_uri }}
[rendered]: https://github.com/agude/agude.github.io/blob/master{{ file_dir }}/{{ notebook_uri }}
[data]: {{ file_dir }}/cory_words.csv

## Development

Cory's first [baby sign][baby_sign] was waving goodbye at 11 months. He
learned four more---pointing at things he wanted, blowing kisses, shaking his
head for "no", and shaking his hands for "all done"---before speaking his
first word. His first word, [like his older brother][theo_post_dev], was in
Cantonese, although it was "dad" and not "dog". It was two more months before
he said "mom" in Cantonese, at which point he already knew "older brother",
"ball", "there", and "pick me up". My wife was disappointed it took so long,
but I suspect it was because he spent so much time with her he did not need a
word to get her attention, he always had it.

[baby_sign]: https://en.wikipedia.org/wiki/Baby_sign_language
[theo_post_dev]: {% post_url 2018-09-30-my_sons_words %}#development

Cory's sign language development outpaced his other languages until he was 20
months old. My suspicion is the same as it was with his brother: sign was his
universal language. English could only be used to talk to dad, Cantonese could
only be used to talk to mom, but sign could communicate with both of us and
even his grandparents.

Cory's language development is plotted below, showing the number of words he
could speak in each "language" as a function of how old he was.

[![A plot showing the number of words my second son could speak as a function
of age.][words_plot_linear]][words_plot_linear]

[words_plot_linear]: {{ file_dir }}/child1_total_words_linear.svg

Cantonese and English exploded at about 19 months; Cory doubled his vocabulary
in those two languages in just four weeks. He almost doubled it again in his
20th month. In his 22nd month, he picked up about 50 Cantonese words and
almost 70 English ones!

Part of that growth in the 22nd month is a data entry artifact: that is when
he went to stay with his grandparents. He had a week to learn words and I only
recorded them when he came back to us and spoke them. You can see two flat
areas in his English and Cantonese language development---one right before 22
months and one right after---that are due to this effect.

Spanish started pretty slowly because only my father speaks it to him. At 22
months we moved closer to my parents so Cory spent more time with them. You
can see a bit of an increase in the amount of Spanish learned then; I'm sure
we would see a much larger increase if we kept recording.

## The Words

I plotted a selection of some of Cory's first words in each language below.
Notice that I have switched to a log plot for the _y_-axis to better show the
beginnings of each language.

[![A plot showing the first words my second son could speak as a function of
age.][first_words]][first_words]

[first_words]: {{ file_dir }}/child1_first_words.svg

A few fun words:

- **Grandpa** (Spanish): As the only person who speaks Spanish full-time to
him, it makes sense that Grandpa would be Cory's first Spanish word. Cory has
always had a special affinity for my father, so it is appropriate as well.
- **Cow** (English and Spanish) and **Lola** (Spanish): Cory started hearing
_La Vaca Lola_ (Lola the cow) and quickly learned most of the words. He still
loves cows, and it is still one of his favorite songs.
- **Older Brother** (Cantonese): Theo is one of the defining features of
Cory's life as both Cory's best friend and primary antagonizer. Cory learned
to identify him quickly (and often would just point and say "big brother" when
Theo had pushed him over).
- **Older Sister** (Cantonese): Cory doesn't have a sister, but there were two
girls who lived next door to our apartment with whom he would play and call
"older sister".
- **Lion Dancer** (Cantonese): Theo became obsessed with lion dancers during
Lunar New Year last year. Cory has picked up on this obsession as well and
often does a solo lion dance.
- **Google** and **Deebot** (English): We have a lot of technology in our
house and Cory has learned all about it. We talk to our Google Home devices
several times a day trying to get them to play music or animal sounds, and
Deebot vacuums the kitchen every night as Cory watches in awe.

## Other Writings on Language Development

If you enjoyed this article, here are all the other articles I wrote about
[language development][language_topic]!

[language_topic]: {% link topics/childhood-language.md %}

{% include topic_posts_but_not_current.html
  topic="childhood-language"
%}
