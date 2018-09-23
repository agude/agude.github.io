---
layout: post
title: "My Son's Language Developement"
description: >
  My son is a little over two and unfortunately he has two huge nerds for
  parents. We tracked every word he's spoken to watch his language
  developement, and now you can join us!
image: /files/words/Articulation_by_j_w_orr.png
image_alt: >
  A woodcut by JW Orr.
---

{% capture file_dir %}/files/words/{% endcapture %}

My son Theo was born in the summer of 2016. My wife and I knew his language
development would be interesting, because she and her parents speak Cantonese
and my parents speak Spanish (although they did not really pass it on to me);
being huge nerds, we decided to record his progress.

{% comment %}
[![A plot showing the number of words my son could speak as a function of
age.][words_plot]][words_plot]

[words_plot]: {{ file_dir }}/child0_total_words.svg
{% endcomment %}


## The Data

We collected the data using a Google form. We decided a "word" was a phrase or
sign that Theo associated with a specific concept. This meant that when he
babbled "mama" or "baba" at 10 months we did not count those because he didn't
have a clear association. We did count some made-up words that did had
association, but these were mostly in sign language where he would invent
signs to convey his meaning.

We found data collection to be very difficult and error prone. Deciding when
Theo had a clear association was difficult because the best indicator was that
he used the word multiple times for the same thing. Sometimes these reuses
would be separated by many days, forcing us to try to remember when he first
used it.

As Theo got older and much better at language, we ran into new issues. First,
he was learning so fast that we had trouble keeping up and remembering if a
word had been recorded our not. Second, he became so good at mimicking sounds
that he would repeat words back to you, but not remember them later.

Still, we think the data is a pretty good representation of his language
development. I'll spend a future post exploring some off the quality issues.

You can find the Jupyter notebook used to perform this analysis
[here][notebook] ([rendered on Github][rendered]). The data can be found
[here][data].

{% capture notebook_uri %}{{ "Most Popular Names Blit Same Time.ipynb" | uri_escape }}{% endcapture %}

[notebook]: {{ file_dir }}/{{ notebook_uri }}
[rendered]: https://github.com/agude/agude.github.io/blob/master{{ file_dir }}/{{ notebook_uri }}
[data]: https://www.ssa.gov/oact/babynames/names.zip

## Development

Theo spoke his first word, in Cantonese, at 14 months. He had been babbling
for a long time before that, but without associating the sounds with meaning.
He then picked up four signs from [baby sign language][baby_sign] before
speaking his second word a month later. We suspect Theo picked up signing
quickly because it was a universal language in our house; Mom would only speak
Cantonese and I would only speak English, but we both responded to his signs.

[baby_sign]: https://en.wikipedia.org/wiki/Baby_sign_language

Theo's language development is plotted below, showing the number of words he
could speak in each "language" as a function of how old he was.

[![A plot showing the number of words my son could speak as a function of
age.][words_plot_linear]][words_plot_linear]

[words_plot_linear]: {{ file_dir }}/child0_total_words_linear.svg

Theo continued adding signs and Cantonese words for three months before he spoke
a word in English, the language I speak to him. That is when he also started
mimicking animal sounds. At 18 months his spoke his first word in Spanish, the
language my parents speak to him.

Theo slowly added words, week by week, until right before he turned 2. At 23
months his language acquisition exploded. He started the period knowing 25
Cantonese words. He knew 50 a month later, and almost 100 after just two
months. Theo is now 26 months old and knows almost 200 words in Cantonese.
English exploded also, but a little later. At 25 months he knew about 40
English words, and now he knows over 100 a month and a half later!

His Spanish development took off at around the same time, but quickly
plateaued. The reasoning is simple: neither of us speaks it well, but my
parents do. The quick rise happened when he was visiting his grandparents
regularly, and the plateau is when we stopped visiting for a few months while
my parents were out of town. It will be interesting to see if Spanish
continues developing when we visit them again.
