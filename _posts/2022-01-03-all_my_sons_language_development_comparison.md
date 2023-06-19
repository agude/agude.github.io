---
layout: post
title: "Comparison of My Three Sons' Language Development"
description: >
  I recorded the words my sons spoke as they learned our various languages and
  now I compare how each developed! Read on to find out how each son learned.
image: /files/all-my-sons-words-comparison/miners_children_belva_mine_kentucky_nara.jpg
hide_lead_image: True
image_alt: >
  Black and white photo of two young boys hanging out a window, their faces
  smudged with soot.
categories:
  - childhood-language
  - data-visualization
---

{% capture file_dir %}/files/all-my-sons-words-comparison/{% endcapture %}

I tracked the language development of all three of my sons. I wrote [a post
focusing on Theo's language development][theo_post], [another post focusing
on Cory's language development][cory_post], and [a final one focusing on Ash's
language development][ash_post]. In this post I'll compare them all.

[theo_post]: {% post_url 2018-09-30-my_sons_words %}
[cory_post]: {% post_url 2020-01-30-my_second_sons_words %}
[ash_post]: {% post_url 2021-12-20-my_third_sons_words %}

## The Data

The data was collected by my wife and I using a Google form on our phones.
When we heard a new word we would log it. I then normalized the words
(sometimes we would write down grandma and sometimes grandmother for the same
word, for example) by hand and took the first occurrence of each word in each
language as the date when they learned it.

I discuss data collection in more depth in [Theo's][theo_post_data], 
[Cory's][cory_post_data], and [Ash's][ash_post_data] data sections. You can
find the Jupyter notebook used to perform this analysis [here][notebook]
([rendered on Github][rendered]). The data can be found [here][theo_data], 
[here][cory_data], and [here][ash_data].

[theo_post_data]: {% post_url 2018-09-30-my_sons_words %}#the-data
[cory_post_data]: {% post_url 2020-01-30-my_second_sons_words %}#the-data
[ash_post_data]: {% post_url 2021-12-20-my_third_sons_words %}#the-data

{% capture notebook_uri %}{{ "Theo vs Cory vs Ash words.ipynb" | uri_escape }}{% endcapture %}

[notebook]: {{ file_dir }}/{{ notebook_uri }}
[rendered]: https://github.com/agude/agude.github.io/blob/master{{ file_dir }}/{{ notebook_uri }}
[theo_data]: {% link files/my-sons-words/theo_words.csv %}
[cory_data]: {% link files/my-second-sons-words/cory_words.csv %}
[ash_data]: {% link files/my-third-sons-words/ash_words.csv %}

## Development

Below I have plotted the number of words each of my sons knew as a function of
their age. Theo, our first son, is represented by dotted lines; Cory, our
second son, is represented by dashed lines; Ash, our third son, is represented
with solid lines.

[![A plot showing the number of words my sons could speak as a function of
their age.][words_plot]][words_plot]

[words_plot]: {{ file_dir }}/child0_vs_child1_vs_child2_total_words_linear.svg

Cory learned all of the languages much faster than his brothers. Theo was the
slowest to learn English and Chinese, the primary languages of our household,
but slightly faster than Ash on Spanish, Sign, and Animal Sounds.
Interestingly, Ash's Chinese started strong but has slowed; had we kept
recording I suspect Theo would have caught up and passed him at 26 months of
age.

I discuss the slow Chinese acquisition in the [development
section of Ash's post][ash_dev], but briefly I think it is related to me
working from home during the COVID pandemic. This meant that:

[ash_dev]: {% post_url 2021-12-20-my_third_sons_words %}#development

- We used a lot more English at home.
- I was able to better identify when he had learned new English words but not
  new Chinese words, which led to a selection effect in what was recorded.

With one additional month of living with Ash (not reflected in the chart and
data) his Chinese has really taken off recently, using whole sentences instead
of just a few words, which leads me to suspect that the slowdown in the data
is mostly due to the selection effect mentioned above.

Also interestingly my wife tells me that Cory's current Chinese is worse than
Theo's was at the same age. Perhaps Cory's development slowed or there is more
to proficiency than just number of words known.

The shape of the English curves are all very similar, just displaced in time.
I would guess this has to do with the fact that they are always surrounded by
English speakers to learn from whereas the other languages require special
interactions with their family to learn.

Ash's Spanish has taken off much slower than our other two sons, although in
comparison he is not too far behind Theo. Theo's long drought of Spanish words
is due to an injury my mom sustained that prevented her and my father from
watching Theo and so reduced his contact with Spanish. Ash doesn't have the
same excuse, but it does show it's not too late for him to pick it up.

Ash never got much into sign language. He learned pointing quickly and got by
just doing that until he could speak. We also didn't emphasize it as much
because we were very busy with our other two boys. I suspect this is why he
didn't know as many animal sounds as well: I used to sit with Theo and Cory
and point at animals in books and teach them but I did not do this with Ash.

As a final note: our kids' doctors were worried about both Theo and Ash's
language development being too slow. Some of that worry transfered to us as
parents. Keeping track of their words like this was reassuring---we could see
that Ash was on pace compared to Theo, and we knew Theo turned out fine!

## Other Writings on Language Development

If you enjoyed this article, here are all the other articles I wrote about
[language development][language_topic]!

[language_topic]: {% link topics/childhood-language.md %}

{% include topic_posts_but_not_current.html
  topic="childhood-language"
%}
