---
layout: post
title: "Fate Dice: Statistics Testing Is Hard"
description: >
  A few months ago I tested my Fate Dice for biases. Now, I retest the
  "biased" set and see if it really is unlucky! Unfortunately, things aren't
  so clear...
image: /files/fate-dice-statistics/fate_dice.jpg
---

{% capture file_dir %}{{ site.url }}/files/fate-dice-statistics/{% endcapture %}

![The black, blue, and red sets of dice.]({{ file_dir }}/fate_dice.jpg)

[A few months ago][previous] I dug up the data from my [Fate campaign][fate]
and used it to test the dice we used for biases. I concluded that three of the
sets were fine, but that the blue dice were significantly biased, with [_P_ <
0.01][pvalue]!

[previous]: {% post_url 2017-07-28-fate_dice_statistics %}
[fate]: http://www.evilhat.com/home/fate-core/
[pvalue]: https://en.wikipedia.org/wiki/P-value

As a scientist, I want to know more than just that the dice are biased, I want
to understand how they are biased. Are three of the dice fine and one is
really bad? Are they all slightly wrong and combined it is significant? These
questions could not be answered with the data at hand as only the finally
total for each roll was recorded. Fortunately, I still have the dice, so I
decided to retest them!

That new test data is [here][new_data]. The old test data is [here][old_data].
You can find the Jupyter notebook used to make these calculations
[here][notebook] ([rendered on Github][rendered]). 

[new_data]: {{file_dir}}/blue_fate_dice_rolls.csv
[old_data]: {{file_dir}}/fate_dice_data.csv
[notebook]: {{file_dir}}/Blue Fate Dice Statistics.ipynb
[rendered]: https://github.com/agude/agude.github.io/blob/master/files/fate-dice-statistics/Blue%20Fate%20Dice%20Statistics.ipynb

## Individual Tests

To perform the test I rolled one of the die 500 times in a row and recorded
the results. I then picked another die and repeated the process, giving me
2000 total rolls. See my [previous post][previous_fate_dice] for a review of
how Fate dice work.

[previous_fate_dice]: {% post_url 2017-07-28-fate_dice_statistics %}#fate-dice

One way to visualize all the roles is to sum up the results for each die roll
by roll. This gives a cumulative total that wanders up and down as the die
rolls high and low results. Each die can then be modeled as a [1-dimensional
random walk][random_walk]. I've plotted the contours that 95% and 99% of
random walks lie within.

[random_walk]: https://en.wikipedia.org/wiki/Random_walk

[![The cumulative roll values for each of the four fate dice.][cumulative_dice]][cumulative_dice]

[cumulative_dice]: {{ file_dir }}/blue_fate_dice_cumulative_rolls.svg

None of the dice wander too far out of the contours, but that doesn't
guarantee they are unbiased. For example, a die that _always_ rolled 0 would
be highly biased but also stay within the contours. It is still possible that
together the dice are biased.

## Group Test

Each die was rolled individually, but Fate dice are rolled four at a time and
summed. In order to mimic this with the data I generated, I took the first
roll of each of the four dice and added them together, treating that as one
roll. I did this for with the rest of the data to get 500 rolls for the set of
dice.

That gives the following distribution, where the points indicate the number
of rolls of the dice that came up with a certain value and the grey area is
the range in which we would expect to find a result produced by a fair set of
dice 99% of the time. I discussed how these regions are computing in detail in
[a previous post][regions_post].

[regions_post]: {% post_url 2017-08-14-fate_dice_intervals %}

[![The results of the second set of blue dice rolls.][results_plot]][results_plot]

[results_plot]: {{ file_dir }}/blue_fate_dice_rolls.svg

Let me stop for a second: _**This is surprising!**_

My [previous test][previous_significance] shows that the blue dice were biased
at the _P_ < 0.01 level and yet not a single count is outside the 99% range
this time! Using a [chi-squared test][chi2] test on the new data gives _P_ =
0.66, which does not rule out the unbiased hypothesis! In fact, this new test
agrees the best with the unbiased hypothesis of all the tests [performed last
time][previous_significance]!

[previous_significance]: {% post_url 2017-07-28-fate_dice_statistics %}#significance
[chi2]: https://en.wikipedia.org/wiki/Pearson%27s_chi-squared_test

We can compare the two tests using the same cumulative plot shown above, but
this time taking the total of all four dice as a single step.

[![Cumulative rolls values for the blue dice comparing the first and second tests.][cumulative_combined]][cumulative_combined]

[cumulative_combined]: {{ file_dir }}/blue_fate_dice_cumulative_rolls_old.svg

The first test, from my [previous post][previous], very quickly wanders
outside the 99% contour and spends much of its time there. The second test
stays solidly within the contours.

<!--
[![The results of the second set of blue dice rolls.][combined_results_plot]][combined_results_plot]
[combined_results_plot]: {{ file_dir }}/blue_fate_dice_rolls_combined.svg
-->

## Explanation

So what explains a significant result in the first test and not in the second?
There are a few possibilities, that fall into two categories: statistics and
systematics.

### Statistics

It is possible that the dice are biased (or fine) and the test that says
otherwise is just a statistical fluke. At _P_ < 0.01 that happens 1 in 100
times. Performing further tests would answer this question: biased dice would
have more results with a low _P_-value, while unbiased dice would have few.

### Systematics

It is also possible, and I think more likely, that one of the tests was
performed in a biased manner. The second test was very carefully done, but
the first test was less controlled: we wrote down results when we remembered,
the person writing the results changed from day to day, and the person rolling
also changed. Further, we often remembered to start recording only **after** a
particularly bad roll. Performing multiple tests and looking at the
distribution of the _P_ value might offer a clue to if the first test was
systematically off, but it is hard to disentangle from statistical uncertainty.

## Conclusion

So what was it, statistics or systematic? If I had to bet I'd say that the
first test was performed poorly and that the dice are probably fine. Am I
going to test them _**again**_ to check? Maybe... You will see it here if I
do!
