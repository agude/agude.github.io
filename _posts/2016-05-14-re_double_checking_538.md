---
layout: post
title: "Further Double-checking FiveThirtyEight's 2016 Primary Predictions"
description: >
  Is FiveThirtyEight's Polls Plus model biased against any candidate? I
  continue my double-checking their model by looking at each candidate
  individually.
image: /files/2016_primary_prediction/black_board_02.jpg
image_alt: >
  A black and white photograph of a child filling in a bar graph on a
  chalkboard.
redirect_from: /2016/05/14/re_double_checking_538/
---

{% capture file_dir %}/files/2016_primary_prediction{% endcapture %}

![Child at a blackboard]({{ file_dir }}/black_board_02.jpg)

After my [last blog post][lastpost] double-checking [FiveThirtyEight
presidential primary predictions][primary], I was asked by a friend if I could
do two additional things:

1. Separate out the candidates in the plots
2. Look at how badly FiveThirtyEight's predictions missed on average for each
   candidate

[lastpost]: {% post_url 2016-04-28-double_checking_538 %}
[primary]: https://projects.fivethirtyeight.com/election-2016/primary-forecast/

This post will address both of those requests.

Just like last time I have included the code used to perform the analysis in
this [Jupyter Notebook][notebook] ([rendered on Github][rendered]). The data
used are here: [Republican Results][gopdata], [Democrat Results][demdata]. The
data have not been updated since April 28th, 2016 so newer primaries are not
included.

{% capture notebook_uri %}{{ "Prediction Second Check -- 538 2016 Primary.ipynb" | uri_escape }}{% endcapture %}

[notebook]: {{ file_dir }}/{{ notebook_uri }}
[rendered]: https://github.com/agude/agude.github.io/blob/master{{ file_dir }}/{{ notebook_uri }}
[gopdata]: {{ file_dir }}/2016_gop_primary_dataframe.csv
[demdata]: {{ file_dir }}/2016_dem_primary_dataframe.csv

## Scaled Results By Candidate

Here is what the scaled result plots look like broken out by candidate, where
the scaling is such that the 80% confidence interval has been transformed to
extend between -1 and 1 (as explained in more detail in my [previous
post][lastpost]). The Democrats:

![The distributions of results normalized to the prediction for the Democrats
by candidate.]({{ file_dir }}/538_scaled_results_dem_by_candidate.svg)

FiveThirtyEight slightly over predicts Clinton's results, but does a pretty
good job with Sanders. Michigan, of course, is the outlier for both.

The Republicans:

![The distributions of results normalized to the prediction for the
Republicans by candidate.]({{ file_dir }}/538_scaled_results_gop_by_candidate.svg)

The Republicans, despite the craziness in their primary, are well modeled.
Only Rubio is really skewed, tending to have his results over predicted.
Carson, interestingly enough, is always within his predicted bounds.

## Mean Absolute Miss Value

When FiveThirtyEight's predictions are wrong, how badly do they miss on
average? To find out, I took the scaled results for each candidate, selected
the ones that were outside the confidence interval (indicating a missed
prediction), and took the average of the absolute value of the selected
results minus 1. The subtraction adjusts the result so that it tells you how
far away from the 80% confidence intervals the missed predictions are on
average. I call this the Mean Absolute Miss Value, or MAMV.

The result of this calculation for each candidate are tabulated below:

|-----------+-------------------------+
| Candidate | Mean Absolute Miss Vale |
|:----------|:-----------------------:|
| Clinton   | 0.84                    |
|:----------|:-----------------------:|
| Sanders   | 1.00                    |
|:----------|:-----------------------:|
| Trump     | 0.66                    |
|:----------|:-----------------------:|
| Cruz      | 0.28                    |
|:----------|:-----------------------:|
| Rubio     | 0.57                    |
|:----------|:-----------------------:|
| Carson    | 0.00                    |
|:----------|:-----------------------:|

Carson's predictions are always in the interval, so his MAMV is 0. The missed
predictions for the Republicans are better that for the Democrats, with Trump
having the worst prediction misses. Sanders's misses and Clinton's misses are
on average worse than the Republicans, but this is again due to Michigan. If
Michigan is removed Clinton's MAMV is 0.52 and Sanders is 0.39, make the MAMV
for both parties about equal.
