---
layout: post
title: "The Weaving of Code"
description: >
  We stopped hiring junior engineers and laid off most of the ones we had. As
  AI climbs the ladder of abstraction, I turn to Prony, Babbage, and Lovelace
  to work out what happens to my job next.
image: /files/weaving-of-code/power_loom_weaving_1835_cropped.jpg
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
field's future with the rise of LLM coding. I certainly am. We prided
ourselves on our _technical ability_, but in less then a year machines have
completely surpassed us. What do we bring to the table if not that?

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
companies, with staff engineers looking that large scale direction, senior
engineers figuring out how to implement the directive, and juniors churning
out the raw code. The difference, of course, is Prony's hairdressers were
never expected to become planners or mathematicians, whereas a junior was
expected to learn and become a senior. Recently though I've been having
variations of this conversation:

> **Me**: We don't really hire junior engineers anymore, do we? In fact we
> just laid a bunch off.
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
and subtracting numbers [seemed like a good task to automate][de]. He failed.
Human computers survived for another 100 yeas until the electronic computers
of the 1960s started to replace them. Some of them weren't replaced though,
they moved up. Former computers like [McNulty][mcnulty], [Snyder][snyder],
[Wescoff][wescoff], [Lichterman][lichterman], [Jennings][jennings], and
[Bilas][bilas] were recruited to program the first electronic computer,
[ENIAC][eniac].

[de]: https://en.wikipedia.org/wiki/Difference_engine
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

In 1843, [Ada Lovelace][lovelace] wrote in her notes on Babbage's [Analytical
Engine][ae] that:

[lovelace]: https://en.wikipedia.org/wiki/Ada_Lovelace
[ae]: https://en.wikipedia.org/wiki/Analytical_engine

{% citedquote
  author_first="Ada"
  author_last="Lovelace"
  work_title="Translator's Notes to M. Menabrea's Memoir, Note A"
  container_title="Scientific Memoirs"
  editor="Richard Taylor"
  volume="3"
  publisher="Richard and John E. Taylor"
  date="1843"
  page="696"
  url="https://en.wikisource.org/wiki/Page:Scientific_Memoirs,_Vol._3_(1843).djvu/706"
%}
We may say most aptly that the Analytical Engine _weaves algebraical patterns_
just as the Jacquard-loom weaves flowers and leaves.
{% endcitedquote %}

But, looking at the division of skill, she too drew the line low:

{% citedquote
  author_first="Ada"
  author_last="Lovelace"
  work_title="Translator's Notes to M. Menabrea's Memoir, Note G"
  container_title="Scientific Memoirs"
  editor="Richard Taylor"
  volume="3"
  publisher="Richard and John E. Taylor"
  date="1843"
  page="722"
  url="https://en.wikisource.org/wiki/Page:Scientific_Memoirs,_Vol._3_(1843).djvu/732"
%}
The Analytical Engine has no pretensions whatever to _originate_ any thing. It
can do whatever we _know how to order it_ to perform. It can _follow_
analysis; but it has no power of _anticipating_ any analytical relations or
truths. Its province is to assist us in making _available_ what we are already
acquainted with.
{% endcitedquote %}

That's what changed in 2026. In 2022, AI could file in the next line of code.
By 2025 they could write the entire thing. Computers had suddenly moved up and
taken the junior engineer's job. Then in, 2026 they made the next leap.

In January of 2026, [Erdős problem][erdos_problems] 728 was solved by an AI,
with "little human intervention" according to [Terence Tao][tao]. In July, the
[Dinitz--Garg--Goemans conjecture][dgg] was disproved by asking an AI to "do a
breakthrough". In September, AI solved the [Navier--Stokes existence and
smoothness problem][ns], a [Millennium Problem][millennium]. In November, AI
proved the [Riemann Hypothesis][riemann], which had stood for 187 years and
was considered the holy grail by many mathematicians.

The final of Prony's tiers fell to automation.

[erdos_problems]: https://en.wikipedia.org/wiki/Erd%C5%91s_problems
[tao]: https://en.wikipedia.org/wiki/Terence_Tao
[dgg]: https://en.wikipedia.org/wiki/Dinitz%E2%80%93Garg%E2%80%93Goemans_conjecture
[ai_discoveries]: https://en.wikipedia.org/wiki/List_of_mathematical_discoveries_made_with_artificial_intelligence
[ns]: https://en.wikipedia.org/wiki/Navier%E2%80%93Stokes_existence_and_smoothness
[millennium]: https://en.wikipedia.org/wiki/Millennium_Prize_Problems
[riemann]: https://en.wikipedia.org/wiki/Riemann_hypothesis

## The End?

It was [Antoine Tilloy's][at] [_The short age of dragon riders_][dragon] that
got me thinking about all this again. His conclusion is similar to mine, that
some people will move up a level of abstraction and "ride the dragon" that is
AI, until they don't:

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

The machines have already moved up, just not everywhere at once. The frontier
is jagged. Some math theorems fall with just a "do a breakthrough", others
still require human direction. At work I'm still in the saddle, riding the
dragon. I don't write code, but I decide what my agents will work on. Maybe
I'll get one more warning as the seniors get laid off leaving only us staff
engineers, or maybe not.

Machines first wove flowers and leaves, then algebraical patterns, and now
code. Soon they will move up again, but we live now, not in three years.
