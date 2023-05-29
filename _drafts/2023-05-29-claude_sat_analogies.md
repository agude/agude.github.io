---
layout: post
title: "Claude Solves SAT Analogies"
description: >
  Word2Vec failed to solve SAT analogies, can modern language models do
  better? A small test of Anthropic's Claude LLM.
image: /files/sat2vec/00225-2672697451-impressionistic_painting,_four_men_studying_at_a_desk,_smoking,_looking_over_papers,_window_in_the_background.png
image_alt: >
  An impressionistic painting based on "Night Before the Exam" by Leonid
  Pasternak, generated with Stable Diffusion using img2img from the original.
  The painting shows four students sitting around a kitchen table studying for
  a exam. Prompt: Impressionistic painting, four men studying at a desk,
  smoking, looking over papers, window in the background.
categories:
  - machine-learning
---


{% capture file_dir %}/files/sat2vec{% endcapture %}

Several years ago, I [tried to get Word2Vec to solve SAT
analogies][last_post]. It did not go well. Word2Vec got just 8 out of 36
right.

[last_post]: {% post_url 2016-07-11-SAT2Vec %}

But in the last 7 years language models have gotten much, **MUCH** better. I
wondered how a state-of-the-art model, one too large to run on my computer,
would perform on the same questions.

To find out, I ran the analogies through [Anthropic's][anthropic] biggest
model: [Claude][claude].

[anthropic]: https://www.anthropic.com/
[claude]: https://www.anthropic.com/index/introducing-claude

## Experimental Setup

I gave Claude the following instructions:

<div class="chatgpt-edit-block">
<div class="chatgpt-prompt-only" markdown="1">
> We're going to solve SAT analogy questions. I'll give you a pair of words
> like:
>
>
> "authenticity : counterfeit"
>
>
> And you determine the relationship between the two words, and then pick the
> pair from the next 5 with the same relation. So in this case I would give
> you:
>
>
> reliability : erratic
>
> mobility : energetic
>
> argument : contradictory
>
> reserve : reticent
>
> anticipation : solemn
>
>
> You need to pick:
>
>
> "reliability : erratic"
>
> Make sure to explain the relationship and why you chose the answer you did.
</div>
</div>

Then I gave it an analogy like:

<div class="chatgpt-edit-block">
<div class="chatgpt-prompt-only" markdown="1">
>  fix : stable
>
> <span markdown="0">------------------------</span>
>
>  fortify : strong
>  captivate : attractive
>  deter : active
>  furrow : productive
>  mend : torn
</div>
</div>

<details markdown="1">
<summary markdown="1">
And it would reply with its answer and reasoning (click "Show" to see all of
it):

<div class="chatgpt-edit-block">
<div class="chatgpt-output-only" markdown="1">
> Okay, for this analogy:
>
> agenda : conference
>
> The relationship here is:
>
> An agenda is a list that provides the plan or schedule for a conference. So
> a conference relies on and uses an agenda.
>
> Based on this, the choice that shows a similar relationship is:
>
> map : trip
</div>
</div>

</summary>

<div class="chatgpt-edit-block">
<div class="chatgpt-output-only" markdown="1">
> Okay, for this analogy:
>
> agenda : conference
>
> The relationship here is:
>
> An agenda is a list that provides the plan or schedule for a conference. So
> a conference relies on and uses an agenda.
>
> Based on this, the choice that shows a similar relationship is:
>
> map : trip
>
> Because a trip relies on and uses a map. A map provides the plan and
> guidance for a trip, just as an agenda does for a conference.
>
> The other choices do not show this same kind of relationship:
>
> - Teacher : class - A teacher facilitates a class but a class does not rely
>   on or use a teacher in the same direct way that a conference uses an
>   agenda or a trip uses a map.
> - Executive : employee - An executive oversees employees but employees do
>   not directly rely on or make use of an executive the same way a conference
>   uses an agenda or a trip uses a map.
> - Man : woman - These do not have a direct facilitator/user relationship.
>   They do not rely on each other in the same way.
> - Agency : assignment - While an agency may give out assignments, an
>   assignment does not directly rely on or use an agency in the way a
>   conference uses an agenda or a trip uses a map.
>
> So by analyzing each choice, map : trip is the one option that shows the
> closest relationship to the original pair's dynamic of agenda : conference.
> Please let me know if this makes sense or if you have another analogy
> challenge for me!
</div>
</div>
</details>

One potential issue: I left the analogies and their possible answers in the
sorted order from my word2vec post. This means the analogies word2vec got
right were up first, with the correct answer in the first position. Then the
ones word2vec had the correct answer second, and so on. I randomized a few of
the analogies to check if this was a significnat problem, and it did not seem
to be. If I had API access, I would have randomized the order of all the
potential answers and run multiple tests.

## Results

Unsurprisingly, Claude did much better than Word2Vec. It got 25 out of 35
analogies correct[^previous] compared to 8 out of 36 for Word2Vec.

[^previous]:
    I used one analogy in my instruction to Claude, which explains the
    discrepancy between 35 and 36.

{% comment %} This allows styling the table text without cutting and pasting a
lot of HTML. {% endcomment %}
{% capture u %}<u style="color:ForestGreen">{% endcapture %}
{% capture endu %}</u>{% endcapture %}

The most frequent failure appears to be Claude identifying the right
relationship, but then incorrectly applying it to choose the answer. For
example this analogy (correct answer **bold**, Claude's answer in {{u}}green
underline{{endu}}):

<div class="low-width-table" markdown="1" style="max-width: 30%">

| hospitable : courtesy             |
|:----------------------------------|
| **vindictive : spite**            |
| {{u}}despondent : glee{{endu}}    |
| leisurely : haste                 |
| morbid : cheerfulness             |
| infamous : honor                  |

</div>

With the following logic:

<div class="chatgpt-edit-block">
<div class="chatgpt-output-only" markdown="1">
> Okay, for the pair:
>
> hospitable : courtesy
>
> The relationship is:
>
> Someone who is hospitable shows courtesy or kindness to their guests. So
> there is a relationship where one concept (hospitable) leads to or results
> in what the other represents (courtesy).
>
> Based on this, the choice that shows a similar relationship where one
> concept results in what the other represents is:
>
> despondent : glee
>
> Because someone who is despondent lacks glee or cheer. Like hospitable leads
> to courtesy, despondent precludes glee.
</div>
</div>

Claude _correctly_ identifies that hospitable implies showing courtesy, but
then picks the opposite relation, someone is despondent **lacks** glee.

All of Claude's answers are [here][answers].

[answers]: /blog/sat2vec/claude_results/
