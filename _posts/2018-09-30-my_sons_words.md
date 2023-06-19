---
layout: post
title: "My Son's Language Development"
description: >
  My son is a little over two and unfortunately he has two huge nerds for
  parents. We tracked every word he's spoken to watch his language
  development, and now you can join us!
image: /files/my-sons-words/Articulation_by_j_w_orr.png
hide_lead_image: True
image_alt: >
  A woodcut by J. W. Orr showing a woman using a blackboard to teach young
  children how to pronounce words.
seo:
  date_modified: 2021-12-19T19:04:09-08:00
categories: 
  - childhood-language
  - data-visualization
---

{% capture file_dir %}/files/my-sons-words/{% endcapture %}

My son Theo was born in the summer of 2016. My wife and I knew his language
development would be interesting, because she and her parents speak Cantonese
and my parents speak Spanish (although they did not really pass it on to me).
Being huge nerds, we decided to record his progress.

## The Data

We collected the data using a Google form. We decided a "word" was a phrase or
sign that Theo associated with a specific concept. This meant that when he
babbled "mama" or "baba" at 10 months we did not count those because he didn't
have a clear association. We did count some made-up words where he had an
association, but these were mostly in sign language where he would invent
them to convey his meaning.

We found data collection to be difficult and error prone. Deciding when Theo
had a clear association was hard because the best indicator was that he used
the word multiple times for the same thing. Sometimes these reuses would be
separated by many days, forcing us to try to remember when he first used it.

As Theo got older and much better at language, we ran into new issues. First,
he was learning so fast that we had trouble keeping up and remembering if a
word had been recorded our not. Second, he became so good at mimicking sounds
that he would repeat words back to you several times, but not remember them
later.

Still, we think the data is a pretty good representation of his language
development. I'll spend a future post exploring some off the quality issues.

You can find the Jupyter notebook used to perform this analysis
[here][notebook] ([rendered on Github][rendered]). The data can be found
[here][data].

{% capture notebook_uri %}{{ "Theo's first words.ipynb" | uri_escape }}{% endcapture %}

[notebook]: {{ file_dir }}/{{ notebook_uri }}
[rendered]: https://github.com/agude/agude.github.io/blob/master{{ file_dir }}/{{ notebook_uri }}
[data]: {{ file_dir }}/theo_words.csv

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

[words_plot_linear]: {{ file_dir }}/theo_total_words_linear.svg

Theo continued adding signs and Cantonese words for three months before he spoke
a word in English, the language I speak to him. That is when he also started
mimicking animal sounds. At 18 months his spoke his first word in Spanish, the
language my parents speak to him.

Theo slowly added words, week by week, until right before he turned 2. At 23
months his language acquisition exploded. He started the period knowing 25
Cantonese words. He knew 50 a month later, and almost 100 after two
months. Theo is now 26 months old and knows almost 200 words in Cantonese.
English exploded also, but a little later. At 25 months he knew about 40
English words, and now he knows over 100 a month and a half later!

His Spanish development took off at around the same time, but quickly
plateaued, only to take off again recently. The reason is simple: neither of
us speaks it well, but my parents do. The quick rise happened when he was
visiting his grandparents regularly, and the plateau is when we stopped
visiting for a few months while my parents were out of town. Now that we are
visiting them again, he has started picking up more words.

## The Words

I plotted a selection of some of Theo's first words in each language below.
Notice that I have switched to a log plot for the _y_-axis to better show the
beginnings of each language.

[![A plot showing the first words my son could speak as a function of
age.][first_words]][first_words]

[first_words]: {{ file_dir }}/theo_first_words.svg

In a future post I'll explore when Theo learned different groups of words
(colors, numbers, foods, etc.), but for now here are some of the fun words
Theo learned:

- **Little Brother** (Cantonese): Theo has a brother, Cory,  who is 18 months
younger than him; it only took Theo a few weeks to learn what the new intruder
was called.
- **Google** (English): We have a few [Google Homes][google_home] in our
apartment and so we say the trigger word, "Hey Google", several times a day.
Theo quickly picked it up. We knew he was saying "Google" and not babbling
"Gaga" because he would either point at the device or grab it and shout at it
when saying it.
- **Cookie** (Spanish): Theo's first word in Spanish was "Cookie". We can
blame the grandparents for this, as they love giving him sweets.
- **Monkey** (Sign): "Monkey" is signed by holding one hand out with palm up
and bouncing the other on top of it, palm facing out and fingers spread. He
invented this sign after we used it while singing [Five Little
Monkeys][five_monkeys].
- **Pig** (Sign): "Pig" is signed by rubbing your chin between thumb and index
finger. He modeled this sign after the hand motions I would make while reading
[The Three Little Pigs][three_pigs], specifically during the line "Not by the
hair on my chiny chin chin".

[google_home]: https://en.wikipedia.org/wiki/Google_Home
[five_monkeys]: https://en.wikipedia.org/wiki/Five_Little_Monkeys
[three_pigs]: https://en.wikipedia.org/wiki/The_Three_Little_Pigs

## Other Writings on Language Development

If you enjoyed this article, here are all the other articles I wrote about
[language development][language_topic]!

[language_topic]: {% link topics/childhood-language.md %}

{% include topic_posts_but_not_current.html
  topic="childhood-language"
%}
