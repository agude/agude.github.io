---
layout: post
title: "My Second Son's Language Development"
description: >
  My second son is a little over two. We tracked every word he's spoken to
  watch his language development, and now you can join us!
image: /files/my-second-sons-words/teaching_punctuation_by_j_w_orr.png
image_alt: >
  A woodcut by J. W. Orr showing a man using a blackboard to teach young
  children punctuation.
---

{% capture file_dir %}/files/my-second-sons-words/{% endcapture %}

My second son, Cory, was born in the winter of 2017. Like [my first
son][theo_post], we tracked his language development to see how fast he picked
up the various languages that our family speaks.

[theo_post]: {% post_url 2018-09-30-my_sons_words %}

## The Data

The data was collected in the [same manner as last time][theo_post_data]. The
only difference is I added a new language category for "animal sounds" because
when recording that data for Theo I realized it was hard to tell "moo" from
"mu". A catch-all category for animals made data logging much easier.

[theo_post_data]: {% post_url 2018-09-30-my_sons_words %}#the-data

I had the same data collection difficulties as last time: When Cory was young
it was hard to decide if he was associating a sound with a concept. When Cory
was older he was so good at imitating sounds that it was hard to know if he
knew the word or was just repeating what you had said. A new difficulty was
that we had our third child just as Cory's language development exploded. Cory
was with his grandparents for a few weeks as we adjusted to the new baby and
so I was not able to record his new words.

You can find the Jupyter notebook used to perform this analysis
[here][notebook] ([rendered on Github][rendered]). The data can be found
[here][data].

{% capture notebook_uri %}{{ "Theo's first words.ipynb" | uri_escape }}{% endcapture %}

[notebook]: {{ file_dir }}/{{ notebook_uri }}
[rendered]: https://github.com/agude/agude.github.io/blob/master{{ file_dir }}/{{ notebook_uri }}
[data]: {{ file_dir }}/cory_words.csv

## Development

Cory's first [baby sign][baby_sign] was waving goodbye at 11 months. He
learned four more---pointing at things he wanted, blowing kisses, shaking his
head for "no", shaking his hands for "all done"---before speaking his first
word. His first word, [like his older brother][theo_post_dev], was in
Cantonese, although it was "dad" and not "dog". It was another two months
before he said "mom" in Cantonese, at which point he already knew "older
brother", "ball", "there", and "pick me up". My wife was disappointed it took
so long, but I suspect it was because he spent so much time with her he did
not really think of her as distinct from himself.

[baby_sign]: https://en.wikipedia.org/wiki/Baby_sign_language
[theo_post_dev]: {% post_url 2018-09-30-my_sons_words %}#development

Cory's sign language development outpaced his other languages until he was 20
months old. Like Theo, was suspect it was because English could only be used
to talk to dad, Cantonese could only be used to talk to mom, but sign could
communicate with both of us and even his grandparents.

Cory's language development is plotted below, showing the number of words he
could speak in each "language" as a function of how old he was.

[![A plot showing the number of words my second son could speak as a function
of age.][words_plot_linear]][words_plot_linear]

[words_plot_linear]: {{ file_dir }}/child1_total_words_linear.svg

Cantonese and English exploded at about 19 months; he doubled his vocabulary
in those two languages in just four weeks. He almost doubled it again in his
20th month. In his 22nd month, he picked up about 50 Cantonese words and
almost 70 English ones!

Part of that growth in the 22nd month is just data entry error: that is
when he went to stay with his grandparents. So he had a week to learn words
and I only recorded them when he came back to us. You can see two flat areas
in his English and Cantonese language development---one right before 22 months
and one right after---that are due to that.

Spanish started pretty slowly because only my father speak it to him. At 22
months we moved closer to my parents and so Cory spent more time with them.
You can see a bit of an increase in the amount of Spanish learned then.

## The Words

I plotted a selection of some of Cory's first words in each language below.
Notice that I have switched to a log plot for the _y_-axis to better show the
beginnings of each language.

[![A plot showing the first words my son could speak as a function of
age.][first_words]][first_words]

[first_words]: {{ file_dir }}/child1_first_words.svg

A few fun words:

- **Grandpa** (Spanish): As the only person who speaks Spanish full-time to
him, it makes sense that Grandpa would be Cory's first Spanish word. Cory has
always had a special affinity for my father, so it is appropriate as well.
- **Cow** (English and Spanish) and **Lola** (Spanish): Cory started singing
_La Vaca Lola_ (Lola the cow) and quickly learned most of the words. He still
loves cows, and it is still one of his favorite songs.
- **Older Brother** (Cantonese): Theo is one of the defining features of
Cory's life as both Cory's best friend and primary antagonizer. Cory learned
to identify him quickly (and often would just point and say "big brother" when
Theo had pushed him over).
