---
layout: post
title: "Claude Solves SAT Analogies"
description: >
  Could Word2Vec pass the SAT analogies section and get accepted to a good
  college? I take a pre-trained model and find out!
image: /files/sat2vec/Pasternak_The_Night_Before_the_Exam.jpg
image_alt: >
  An impressionistic painting titled 'Night Before the Exam' by Leonid
  Pasternak. The painting shows four students sitting around a kitchen table
  studying for a exam. One student holds a skull, while the others longue
  around smoking or studying books or papers.
categories:
  - machine-learning
---

{% capture file_dir %}/files/sat2vec{% endcapture %}

Several years ago, I [tried to get Word2Vec to solve SAT
analogies][last_post]. It didn't go well. Word2Vec got 20% right.

[last_post]: {% post_url 2016-07-11-SAT2Vec %}

But in the last 7 years language models have gotten much, **MUCH** better. So
I wondered how a state-of-the-art model, one too large to run on my computer,
would do with the same questions.

To find out, I ran the same analogies through [Anthropic's][anthropic] largest
model: [Claude][claude].

[anthropic]: https://www.anthropic.com/
[claude]: https://www.anthropic.com/index/introducing-claude

Here is how it performed:

## Analogies

