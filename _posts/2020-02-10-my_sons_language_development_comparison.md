---
layout: post
title: "Comparison of My Two Sons' Language Development"
description: >
  Being a nerd dad, I recorded all the words my first two sons spoke as they
  learned them. Now, I compare their language development rate!
image: /files/my-sons-words-comparison/coal_miners_child_in_grade_school_lejunior_harlan_county_kentucky.jpg
hide_lead_image: True
image_alt: >
  Black and white photo of a young boy at a school desk.
seo:
  date_modified: 2021-12-23T15:10:55-08:00
categories:
  - childhood-language
  - data-visualization
---

{% capture file_dir %}/files/my-sons-words-comparison/{% endcapture %}

My son Theo was born in the summer of 2016 and my son Cory was born in the
winter of 2017. Our family is multi-lingual so we knew our sons would
therefore have complicated and interesting language development. My wife and I
are (unsurprisingly) **huge nerds** so we wrote down each new word they
learned so we could explore how they learned language. I wrote [a post
focusing on Theo's language development][theo_post] and [another post focusing
on Cory's language development][cory_post]; this month I compare them.

[theo_post]: {% post_url 2018-09-30-my_sons_words %}
[cory_post]: {% post_url 2020-01-30-my_second_sons_words %}

## The Data

The data was collected by my wife and I attempting to identify when the boys
had learned a new word and writing it down. The most common error is writing
down words one of the boys does not yet really know. This would lead to an
increase in the number of words known at any time in the data; still the
difference between the boys should be unaffected as the error pushes the data
in the same direction for both of them.

I discuss data collection in more depth in [Theo's][theo_post_data] and
[Cory's][cory_post_data] data sections. You can find the Jupyter notebook used
to perform this analysis [here][notebook] ([rendered on Github][rendered]).
The data can be found [here][theo_data] and [here][cory_data].

[theo_post_data]: {% post_url 2018-09-30-my_sons_words %}#the-data
[cory_post_data]: {% post_url 2020-01-30-my_second_sons_words %}#the-data

{% capture notebook_uri %}{{ "Theo vs Cory words.ipynb" | uri_escape }}{% endcapture %}

[notebook]: {{ file_dir }}/{{ notebook_uri }}
[rendered]: https://github.com/agude/agude.github.io/blob/master{{ file_dir }}/{{ notebook_uri }}
[theo_data]: {% link files/my-sons-words/theo_words.csv %}
[cory_data]: {% link files/my-second-sons-words/cory_words.csv %}

## Development

Below I have plotted the number of words each of my sons knew as a function of
their age. Theo, our first son, is represented by dashed lines; Cory, our
second son, is represented by solid lines.

[![A plot showing the number of words my sons could speak as a function of
their age.][words_plot]][words_plot]

[words_plot]: {{ file_dir }}/child0_vs_child1_total_words_linear.svg

Second children are known to have slower onset of language
development.[^pine][^berglund] They learn their first 50 known words more
slowly, but catch up to their older siblings quickly, learning their first 100
words at about the same age. The advantage is small though; the average
difference in time to first 50 words between the first and second child is
only 1 month.

[^pine]: Pine, J. M., _Variation in vocabulary development as a function of birth order._ Child Development, 66(1), 272–281. (1995). doi:[10.2307/1131205](https://doi.org/10.2307/1131205)
[^berglund]: Berglund, E., Eriksson, M., and Westerlund, M. _Communicative skills in relation to gender, birth order, childcare and socioeconomic status in 18‐month‐old children._ Scandinavian Journal of Psychology, 46: 485-491. (2005). doi:[10.1111/j.1467-9450.2005.00480.x](https://doi.org/10.1111/j.1467-9450.2005.00480.x)

Theo and Cory do not follow this trend. Cory was 3 to 4 months faster than
Theo to hit language development milestones in Cantonese, English, and
Spanish; he also knew many more animal sounds. Theo was artificially limited
in his Spanish acquisition though, as [mentioned in his post][theo_post],
because my mother had injured herself and so Theo could not visit my parents
for a few months.

Sign is the only area where Theo eventually learned faster than Cory. I
suspect this is because he needed sign to communicate as he did not know as
many words as quickly, whereas Cory gave up on sign once he could talk.

Finally, I owe Theo's doctor an apology: she was always a little worried about
Theo's language development, but we did not take it seriously because we knew
that bilingual children developed language more slowly. Looking at the data
and comparing to his brother, I think our pediatrician was right to be
worried. Thankfully, Theo has had no problems since and now talks incessantly.

## Other Writings on Language Development

If you enjoyed this article, here are all the other articles I wrote about
[language development][language_topic]!

[language_topic]: {% link topics/childhood-language.md %}

{% include topic_posts_but_not_current.html
  topic="childhood-language"
%}
