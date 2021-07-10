---
layout: post
title: "Fate Dice Intervals"
description: >
  What does a "normal" distribution of rolls from a fair set of Fate dice look
  like? There are a lot of ways to estimate it. In this post I'll go through
  four methods.
image: /files/fate-dice-statistics/alphonse-mucha-fate-1920.jpg
image_alt: >
  An oil painting titled 'Fate', painted in 1920 by Alphonse Mucha. It depicts
  a woman in a white robe holding an oil lamp.
use_latex: True
categories:
  - data-science
  - fun-and-games
---

{% capture file_dir %}/files/fate-dice-statistics/{% endcapture %}

Last month [I checked my Fate dice for biases][lastpost]. One of the things I
did was plot an interval for the 4dF outcomes (-4 through 4) we expect from a
fair set of dice 99% of the time. In this post I will look at four different
methods of computing those regions. While writing this post, I came upon a
[NIST handbook page][nist] that covers the same topic; check it out too!

[lastpost]: {% post_url 2017-07-28-fate_dice_statistics %}
[nist]: https://www.itl.nist.gov/div898/handbook/prc/section2/prc241.htm

As per usual, you can find the Jupyter notebook used to perform these
calculations and make the plots [here][notebook] ([rendered on
Github][rendered]).

{% capture notebook_uri %}{{ "Fate Dice Expectation Regions.ipynb" | uri_escape }}{% endcapture %} 

[notebook]: {{ file_dir }}/{{ notebook_uri }}
[rendered]: https://github.com/agude/agude.github.io/blob/master{{ file_dir }}/{{ notebook_uri }}

## Normal Approximation

One of the simplest ways of determining how often we expect an outcome to
appear is to assume that the distribution of results is
[Gaussian][normal].[^clt] If the outcome has a probability _P_, and the dice
are thrown _N_ times, then the range of expected results is:

[normal]: https://en.wikipedia.org/wiki/Normal_distribution
[^clt]: The [central limit theorem](https://en.wikipedia.org/wiki/Central_limit_theorem) can be used to justify this approximation, but as you can see in the plot in the [binomial section](#binomial-probability), even for large _N_ the distribution is not a perfect Gaussian.

$$ M_{\pm} = NP \pm z \sqrt{NP(1-P)} $$

Where [_z_][zscore] is the correct value for the interval (2.58 for 99%) and the
two M values are the lower (for minus) and upper (for plus) bounds on the
region.

[zscore]: https://en.wikipedia.org/wiki/Standard_score

Using this approximation yields values that are close to exact, with the
exception that they allow negative counts for rare outcomes. The values (the 
negative outcomes -4 through -1 are removed, because the distribution is symmetric)
are:

| Outcome | Lower Bound | Upper Bound |
|:--------|------------:|------------:|
|       0 |       97.47 |      147.42 |
|       1 |       79.64 |      126.58 |
|       2 |       45.05 |       83.84 |
|       3 |       13.01 |       38.55 |
|       4 |       -0.06 |       12.95 |

## Wilson Score Interval

The [Wilson score interval][wilson] gives a better result than the normal
approximation, but at the expense of a slightly more complicated formula.
Unlike the normal approximation, the Wilson interval is asymmetric and can not
go below 0. It is defined as:

[wilson]: https://en.wikipedia.org/wiki/Binomial_proportion_confidence_interval#Wilson_score_interval

$$ M_{\pm} = \frac{N^2}{N+z^2} \left[ P + \frac{z^2}{2N} \pm z \sqrt{ \frac{P \left(1 - P\right)}{N}  + \frac{z^2}{4N^2}} \,\right] $$

Plugging in the numbers yields:

| Outcome | Lower Bound | Upper Bound |
|:--------|------------:|------------:|
|       0 |       99.34 |      149.02 |
|       1 |       81.73 |      128.46 |
|       2 |       47.52 |       86.31 |
|       3 |       15.72 |       41.74 |
|       4 |        2.43 |       16.84 |

## Monte Carlo Simulation

The previous two methods were quick to calculate, but only returned
approximate results. One way to determine the exact intervals is to [simulate
rolling the dice][mc]. This is often easy to implement, but is slow due to the
high trial count required.

[mc]: https://en.wikipedia.org/wiki/Monte_Carlo_method

The following code (which can be found in the [notebook][rendered]) will
"roll" 4dF _N_ times per trial, and perform 10,000 trials:

```python
def simulate_rolls(n, trials=10000):
    """ Simulate rolling 4dF N times and calculate the expectation
    intervals.
    """

    # The possible values we can select, the weights for each,
    # and a histogram binning to let us count them quickly
    values = [-4, -3, -2, -1, 0, 1, 2, 3, 4]
    bins = [-4.5, -3.5, -2.5, -1.5, -0.5, 0.5, 1.5, 2.5, 3.5, 4.5]
    weights = [1, 4, 10, 16, 19, 16, 10, 4, 1]

    results = [[], [], [], [], [], [], [], [], []]

    # Perform a trial
    for _ in range(trials):
        # We select all n rolls "at once" using a weighted choice function
        rolls = choices(values, weights=weights, k=n)
        counts = np.histogram(rolls, bins=bins)[0]

        # Add the results to the global result
        for i, count in enumerate(counts):
            results[i].append(count)

    return results
```

After generating the trials, the intervals are computed by looking at the 0.5
percentile and the 99.5 percentile for each possible 4dF outcomes. The results
are:

| Outcome | Lower Bound | Upper Bound |
|:--------|------------:|------------:|
|       0 |          98 |         148 |
|       1 |          80 |         127 |
|       2 |          46 |          84 |
|       3 |          14 |          39 |
|       4 |           1 |          14 |

## Binomial Probability

Simulating the rolls is guaranteed to produce the right result, but it takes a
lot of time to run. For a simple case like rolling dice, we can calculate the
intervals exactly using a little knowledge of probability. This is the method
I used in my [previous post][lastpost] because it is _fast **and** exact_.

The interval indicates the expected results a fair set of dice would roll 99%
of the time, but that is exactly what probabilities gives as well! The
interval is therefore just the set of rolls that make up 99% of the cumulative
probability, centered around the most likely value for each outcome.
Equivalently, we can find the set of rolls that make up the very unlikely 1%,
which will come (approximately equally) from both tails of the
distribution. That is, integrate from the low side (which is a sum, since
the bins are discrete) until the cumulative probability is 0.5%, and then
repeat for the high side. The stopping points are the correct lower and upper
bounds.

Here is an example image showing this process for the probability distribution
of the number of zeroes rolled if the dice are thrown 522 times. The red parts
of the histogram are the results of the two integrals, each containing about
0.5% of the probability, and the grey lines mark the lower and upper bounds at
98 and 148.

[![The probability of rolling zero on 4dF a set number of times given 522 rolls.][prob_plot]][prob_plot]

[prob_plot]: {{ file_dir }}/fate_dice_probabilities.svg

Each of the bins in the plot has probability given by:

$$ \binom{N}{M} P^M (1-P)^{N-M} $$

Where _P_ is the probability of rolling the outcome on one roll and _M_ is the
number of time the outcome happens in _N_ throws.

Applying this process to all the possible outcomes gives the following
results:

| Outcome | Lower Bound | Upper Bound |
|:--------|------------:|------------:|
|       0 |          98 |         148 |
|       1 |          80 |         127 |
|       2 |          46 |          84 |
|       3 |          14 |          39 |
|       4 |           1 |          14 |

## Comparison

Tables are great when you want exact numbers, but it is much easier to compare
the various methods using a plot. The following plot shows the predictions
from each of the four methods for the outcomes 0 through 4. The negative
outcomes (-4 through -1) are omitted because the distributions are symmetric.

[![The four different methods of computing the expected intervals.][results_plot]][results_plot]

[results_plot]: {{ file_dir }}/fate_dice_regions.svg

The Monte Carlo method and the estimate using the binomial probability agree
exactly, as expected. The naive variance method agrees well for the first few
values, but begins predicting lower intervals as the value increases, finally
ending with a nonsense negative count. The Wilson interval is consistently
higher than the other values, and this discrepancy increases as the value of
the roll increases.
