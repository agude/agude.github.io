---
layout: post
title: "Fate Dice Statistics"
description: >
  My friends and I played a Fate RPG for over two years. During that time we
  rolled a lot of dice and developed a lot of superstitions, but were any of
  them correct?
image: /files/fate-dice-statistics/fate_dice.jpg
show_lead_image: True
image_alt: >
  Three sets of four Fate dice, colored blue, red, and black, resting on top
  of a wooden table.
categories:
  - data-science
  - fun-and-games
---

{% capture file_dir %}/files/fate-dice-statistics/{% endcapture %}

My friends and I played [Fate][fate], a [role-playing game][rpg], for a few
years during graduate school. Over that time we developed superstitions about
the various dice we rolled. Since we were (are) huge nerds we decided to
record (almost) all of the rolls to determine if the dice really were biased.
We cursorily looked at the data when we finished playing, but I thought it
would be interesting to dig it back out and analyze it more deeply.

[rpg]: https://en.wikipedia.org/wiki/Tabletop_role-playing_game
[fate]: https://www.evilhat.com/home/fate-core/

## Fate Dice

[Fate dice][dice] (also called Fudge dice) have six sides and three values
with equal probability of appearing: plus, blank, and minus. These
respectively represent +1, 0, and -1 . Four dice are rolled at a time and
their results are summed, giving a range of -4 to 4. The
[notation][dice_notation] for this type of roll is 4dF.

[dice]: https://en.wikipedia.org/wiki/Fudge_(role-playing_game_system)#Fudge_dice
[dice_notation]: https://en.wikipedia.org/wiki/Dice_notation

Figuring out the probability of rolling a value is just simple combinatorics.
These probabilities are:

| Value    | Probability |
|:---------|------------:|
| 0        |       19/81 |
| 1 xor -1 |       16/81 |
| 2 xor -2 |       10/81 |
| 3 xor -3 |        4/81 |
| 4 xor -4 |        1/81 |

## Rolls

We had four sets of Fate dice, colored blue, red, black, and white. We wrote
down only the sum of each roll, since the individual dice in the set are
indistinguishable. This means that if one of the dice is biased, it will take
longer to show up than if we had been able to explore the results
individually. As per usual, you can find the Jupyter notebook used to make
these calculations [here][notebook] ([rendered on Github][rendered]). The data
is [here][data].

{% capture notebook_uri %}{{ "Fate Dice Statistics.ipynb" | uri_escape }}{% endcapture %} 

[notebook]: {{ file_dir }}/{{ notebook_uri }}
[rendered]: https://github.com/agude/agude.github.io/blob/master{{ file_dir }}/{{ notebook_uri }}
[data]: {{file_dir}}/fate_dice_data.csv

Here are the distributions of rolls for each of the four sets of dice. The
points indicate the number of rolls that came up with a certain value, while
the grey area is the range in which we would expect to find a result produced
by a fair set of dice 99% of the time. I discuss how these regions are
computing in detail in [another post][regions_post].

[regions_post]: {% post_url 2017-08-14-fate_dice_intervals %}

[![The results of our rolls during out Fate campaign.][results_plot]][results_plot]

[results_plot]: {{ file_dir }}/fate_dice_rolls.svg

The blue dice were rolled the most (because we thought the red and black sets
were unlucky), but visual inspection suggests that they were actually biased!
Contrary to our superstitions, the "cursed" red and black dice seem to have
been fine. The white dice have one bin (very) high, but it's hard to tell by
eye if that is significant.

## Significance

To check whether the dice are biased, a [chi-squared test][chi2] is required.
The chi-squared test essentially looks at how far away each point in a
distribution is from the expected value for that point, and normalizes by the
variance. The test statistic is then compared to the results expected from a
[chi-squared distribution][chi2_dist] and a significance is obtained. Running
this test on our dice yields the following results:

[chi2]: https://en.wikipedia.org/wiki/Pearson%27s_chi-squared_test
[chi2_dist]: https://en.wikipedia.org/wiki/Chi-squared_distribution

| Dice  | chi-squared | _p_-value |
|:------|------------:|----------:|
| Blue  |       26.31 |     0.001 | 
| Black |        9.32 |     0.315 |
| Red   |       10.77 |     0.215 |
| White |       19.07 |     0.014 |

The chi-squared test has some [caveats about low expected values][caveats],
but at worst we only have two (out of nine) bins below five expected entries.
Looking at the [_p_-values][pvalue] we conclude roughly the same as our
"_chi-by-eye_" test above: the blue dice are significantly biased, while the
black and red dice show no evidence of being unfair. The white dice are not
biased at the _p_ < 0.01 level, but that single high bin is odd and to be
absolutely sure I would want to roll them a lot more and check.

[caveats]: https://stats.stackexchange.com/q/93212
[pvalue]: https://en.wikipedia.org/wiki/p-value
