---
layout: post
title: "My Third Son's Language Development"
description: >
  We tracked my third son's language development word by word. Here, in plots,
  is how he learned to speak. Take a look!
image: /files/my-third-sons-words/taylor_and_alfred_by_j_w_orr.jpg
hide_lead_image: True
image_alt: >
  A woodcut by J. W. Orr showing a father giving his son a picture book in a
  richly appointed study.
categories: 
  - childhood-language
  - data-visualization
---

{% capture file_dir %}/files/my-third-sons-words/{% endcapture %}

My Third son, Ash, was born in the fall of 2019. Like my [first][theo_post]
and [second][cory_post] sons, we tracked Ash's language development to monitor
how quickly he was picking up the different languages we speak.

[theo_post]: {% post_url 2018-09-30-my_sons_words %}
[cory_post]: {% post_url 2020-01-30-my_second_sons_words %}

## The Data

The data was collected in the [same manner as last two times][theo_post_data]. 
One difference was that Ash learned to speak during the [COVID-19
pandemic][pandemic], when we were much more isolated from family and the rest
of the world, but also I was working from home so it was easier to enter my
own data rather than have my wife text me when Ash said a new word.

[theo_post_data]: {% post_url 2018-09-30-my_sons_words %}#the-data
[pandemic]: https://en.wikipedia.org/wiki/COVID-19_pandemic

The main difficulties in data collection were the same though: 

- Deciding when Ash had associated a sound with a concept as opposed to just babbling.
- Deciding if Ash "knew" a word or was just repeating a sound he had just
heard.

You can find the Jupyter notebook used to perform this analysis
[here][notebook] ([rendered on Github][rendered]). The data can be found
[here][data].

{% capture notebook_uri %}{{ "Ash's first words.ipynb" | uri_escape }}{% endcapture %}

[notebook]: {{ file_dir }}/{{ notebook_uri }}
[rendered]: https://github.com/agude/agude.github.io/blob/master{{ file_dir }}/{{ notebook_uri }}
[data]: {{ file_dir }}/ash_words.csv

## Development

Ash's first word was "milk" in Cantonese, spoken at 13 months old. Milk was
something he loved back then and the word is still in frequent use. He often
demands "milk milk milk" while shoving his empty cup towards us. His second
word was "mom" in Cantonese and his third word was "dad" in English. Unlike my
other children, Ash didn't start using the Cantonese word for "dad" until very
late. He preferred his own pidgin where he would simply use the English word
"dad" in an otherwise Cantonese phrase.

[chinglish]: https://en.wikipedia.org/wiki/Chinglish

Ash learned a few words of [baby sign language][baby_sign], but unlike his
other brothers was not too interested in learning much.

[baby_sign]: https://en.wikipedia.org/wiki/Baby_sign_language

Ash's language development is plotted below, showing the number of words he
could speak in each "language" as a function of how old he was.

[![A plot showing the number of words my third son could speak as a function
of age.][words_plot_linear]][words_plot_linear]

[words_plot_linear]: {{ file_dir }}/child2_total_words_linear.svg

Ash picked up English and Cantonese at roughly the same rate, with Cantonese
leading in the number of words spoken until he was 23 months old when he
started speaking more English. I suspect the reason his English learning
outpaced his Cantonese is because I was working from home during the pandemic.
This had two effects:

- Ash got a lot more exposure to my wife and other sons speaking to me in
  English, and more time listening to me talk to him.
- I was able to record new English words he was speaking, but since my
  Cantonese is bad (really bad) I could not do the same for it and so relied
  on my wife. This made it more likely that I would write down a new English
  word while missing more Cantonese words.

Ash's language development really took off at 17 or 18 months of age and went
nearly vertical at 23 months. During his 23rd month he doubled the number of
English words he knew to about 100 and overtook the number of Cantonese words,
which climbed more slowly.

Ash's Spanish development has been slow. He has had plenty of time with my
parents (who both speak Spanish) but not much alone time with them. He
normally visits with his older brothers who speak mostly English to my parents
now, which has reduced Ash's exposure to Spanish. Ash also did not love
Spanish cartoons, which is older brothers did at his age.

## The Words

I plotted a selection of some of ash's first words in each language below.
Notice that I have switched to a log plot for the _y_-axis to better show the
beginnings of each language.

[![A plot showing the third words my son could speak as a function of
age.][first_words]][first_words]

[first_words]: {{ file_dir }}/child2_first_words.svg

Here is a selection of fun words Ash learned:

- **Google** (English): Like all my sons, Ash was fascinated by the [Google
  Homes][google_home] we have everywhere. It will be interesting to see how
  their concept of Google evolves over time. To me it is the search engine
  company, to them it is the little black speaker that sits on the shelf and
  has a personality.
- **Gondola** (English): All three boys love the gondolas at the Oakland Zoo.
  Ash learned to say "ganda" very quickly to indicate that he wanted to ride.
- **Cookie** (Spanish): All three boys learned to say cookie in Spanish very
  quickly because my parents give them cookies when they visit. Ash actually
  tells us that "cookie" in English is wrong and still only calls them
  "gagas".
- **Hulk** (Animal Sounds): Cory loves Hulk and has a large action figure he
  plays with. Ash learned from Cory that Hulk makes a roaring sound while
  smashing things and would mimic it while playing with the toy.
- **Little Brother** and **Big Brother** (Chinese): Ash learned how to
  identify his brothers very quickly, mainly to complain to us when they took
  his toys!

[google_home]: https://en.wikipedia.org/wiki/Google_Home

## Other Writings on Language Development

If you enjoyed this article, here are all the other articles I wrote about
[language development][language_topic]!

[language_topic]: {% link topics/childhood-language.md %}

{% include topic_posts_but_not_current.html
  topic="childhood-language"
%}
