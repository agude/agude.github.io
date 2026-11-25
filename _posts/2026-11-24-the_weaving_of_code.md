---
layout: post
title: "The Weaving of Code"
description: >
  TODO: One or two sentences. Junior engineers are the new drawboys, I am a
  dragon rider, and the loom has a history of climbing the ladder.
image: /files/weaving-of-code/power_loom_weaving_1835.jpg
image_alt: >
  A black and white engraving of a long mill hall lined with rows of power
  looms, driven by belts from overhead shafts. Women tend the looms while a
  man stands in the center aisle and a woman kneels beside a loom at his feet.
categories:
  - career-advice
  - machine-learning-engineering
  - opinions
---

I think most software engineers are starting to wonder about their and their
field's future with the rise of LLM coding. We prided ourselves on our
_technical ability_, but in less then a year machines have completely
surpassed us. What do we bring to the table if not that?

[prony_cadastre]: https://en.wikipedia.org/wiki/Gaspard_de_Prony#The_trigonometric_and_logarithmic_tables_of_the_cadastre

## Prony

In 1791, [Gaspard de Prony][gdp] was tasked with computing 19 books full of
logarithms for the French geographic survey. He divided the labor into three
tiers:

[gdp]: https://en.wikipedia.org/wiki/Gaspard_de_Prony

1. _Mathematicians_, including luminaries like [Legendre][legendre] and
   [Carnot][carnot], who did the high level algorithm work.

2. _Planners_, who figured out how to implement the algorithms and supervised.

3. _Computers_, many former hairdressers, who did the actual tedious
   calculations.

[legendre]: https://en.wikipedia.org/wiki/Adrien-Marie_Legendre
[carnot]: https://en.wikipedia.org/wiki/Lazare_Carnot

If you squint at it, that's almost the same way we structure software
companies, with Staff engineers looking that large scale direction, senior
engineers figuring out how to implement the directive, and juniors churning
out the raw code. The difference, of course, is Prony's hairdressers were
never expected to become planners or mathematicians, where as a junior was
expected to learn and become a senior. Recently though I've been having
variations of this conversation:

> **Me**: We don't really hire junior engineers anymore. In fact we just laid
> a bunch off.
>
> **Friend**: Yeah... Where are the next senior and staff engineers going to
> come from if juniors don't learn on the job?
>
> **Me**: Companies seem to think that's someone else's problem. But... did
> they need another generation of apprentices once the [Jacquard
> loom][jl_wiki] was invented?

[jl_wiki]: https://en.wikipedia.org/wiki/Jacquard_machine

## Babbage

In 1832, [Charles Babbage][babbage] published {% book_link "On the Economy of
Machinery and Manufactures" %}, which codified in what is now known as the
["Babbage Principle"][babbage_principle] the division of labor Prony had
invented for his survey. He explained that highly skilled---and hence highly
paid!---workers spend some of their time doing tasks below their skill level,
and that it is better to hire those tasks out to lower-skill workers. This
economic force drives jobs to be split into tasks by skill.[^skill]

[babbage]: https://en.wikipedia.org/wiki/Charles_Babbage
[babbage_principle]: https://en.wikipedia.org/wiki/Charles_Babbage#%22Babbage_principle%22

[^skill]:
    We've already seen this splitting in Data Science/Machine Learning already
    along the "_engineeriness_" dimension, as I documented in my articles
    [_The Data Science Split: From Unicorns to Teams_][split] and [_The Data
    Science Spectrum: From Analyst to Machine Learning_][engineeriness].

[split]: {% post_url 2021-05-31-the_data_science_split %}
[engineeriness]: {% post_url 2021-06-01-data_science_job_spectrum %}

Babbage saw the bottom tier of Prony's skill division and thought that adding
and subtracting numbers [seemed like a good task to automate][ae]. He failed.
Human computers survived for another 100 yeas until the electronic computers
of the 1960s started to replace them. Some of them weren't replaced though,
they moved up. Former computers like [McNulty][mcnulty], [Snyder][snyder],
[Wescoff][wescoff], [Lichterman][lichterman], [Jennings][jennings], and
[Bilas][bilas] were recruited to program the first electronic computer,
[ENIAC][eniac].

[ae]: https://en.wikipedia.org/wiki/Analytical_engine
[mcnulty]: https://en.wikipedia.org/wiki/Kathleen_Antonelli
[snyder]: https://en.wikipedia.org/wiki/Betty_Holberton
[wescoff]: https://en.wikipedia.org/wiki/Marlyn_Meltzer
[lichterman]: https://en.wikipedia.org/wiki/Ruth_Teitelbaum
[jennings]: https://en.wikipedia.org/wiki/Jean_Bartik
[bilas]: https://en.wikipedia.org/wiki/Frances_Spence
[eniac]: https://en.wikipedia.org/wiki/ENIAC

If you think about it, the junior--senior--staff leveling system already
leaves out that bottom bottom rung. <!-- One sentence to fix my "Oh wait above
we said the juniors were the bottom rung --> We, too, work with computers, but
not the human kind. Now LLMs are moving up another step on the ladder. Human
computers lasted about 350 years, junior engineers around 70. I'm not sure how
long senior and staff engineers will hold on.

## Lovelace

[Antoine Tilloy's][at] [_The short age of dragon riders_][dragon]

{% citedquote
  author_first="Antoine"
  author_last="Tilloy"
  work_title="The short age of dragon riders"
  container_title="Antoine Tilloy's research log"
  date="2026-11-16"
  url="https://atilloy.com/2026/11/16/the-short-age-of-dragon-riders/"
%}
I suspect the value of good dragon riders will increase exponentially until
it collapses dramatically. At some point it will not be possible to raise
the bar, stay above the wave, and it is plausible that nothing biological
will be able to give valuable insights to the silicon. The dragon will know
what to do. But we live now, not in three years.
{% endcitedquote %}

[at]: https://atilloy.com/about/
[dragon]: https://atilloy.com/2026/11/16/the-short-age-of-dragon-riders/
