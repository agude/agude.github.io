---
layout: post
title: "SWITRS: Car Crashes After Daylight Saving Time"
description: >
  Day light saving time leaves us drowsy and cranky at work, but it also leads
  to an increase in traffic collisions! Find out exactly how many more there
  are with this analysis!
image: /files/switrs-dst/dst_change_gare_saint_lazare_1937.png
image_alt: >
  A man adjusts the central time of the Gare Saint-Lazare in Paris, 1937.
categories: 
  - california-traffic-data 
  - data-science
seo:
  date_modified: 2018-10-13T22:25:17-0700
---

{% capture file_dir %}/files/switrs-dst{% endcapture %}

{% include lead_image.html %}

The [daylight saving time][dst] (DST) change is awful---we get less sleep and
it [might not even save energy][energy] as was intended! Worse, studies by
[Varughese & Allen][varughese] and [Smith][smith] have shown that the time
change increases the number of automobile crashes! Let's look for a similar
trend in the [SWITRS data][s2s_post] that I've collected.

[dst]: https://en.wikipedia.org/wiki/Daylight_saving_time
[energy]: https://www.scientificamerican.com/article/does-daylight-saving-times-save-energy/
[varughese]: https://doi.org/10.1016/S1389-9457(00)00032-0
[smith]: https://doi.org/10.1257/app.20140100
[s2s_post]: {% post_url 2016-11-01-switrs_to_sqlite %}

The Jupyter notebook used to perform this analysis can be found
[here][notebook] ([rendered on Github][rendered]).

{% capture notebook_uri %}{{ "SWITRS Daylight Saving Time Crashes.ipynb" | uri_escape }}{% endcapture %} 

[notebook]: {{ file_dir }}/{{ notebook_uri }}
[rendered]: https://github.com/agude/agude.github.io/blob/master{{ file_dir }}/{{ notebook_uri }}

## Crash Ratio

The analysis is relatively simple. I start with the number of crashes that
happen on the days following the start of DST in California. I divide the
amount of crashes on each day by the number of crashes on the same day of the
week but two weeks later.[^1] Taking the ratio cancels out most of the effects
that are unrelated to the time change---like the fact that [crash rates vary
by 30% depending on the year][apw]. Two weeks after is a good choice for
normalization because:

[apw]: {% post_url 2016-12-02-switrs_crashes_by_date %}#crashes-per-week

- The weeks after the time change have similar daylight hours to the week of
  the time change.
- The crashes rate is still slightly elevated a week later, so normalizing by
  the very next week hides some of the increase that is due to the start of
  DST.[^2]

The [violin plots][violin] below show the distribution of these ratios from
the years 2001 to 2016. A value greater than 1 means that there are more
crashes during the week when DST starts than two weeks after.

[violin]: https://en.wikipedia.org/wiki/Violin_plot

[![Violin plot showing the ratio of crashes per day of the week for the week
after the start of daylight saving time, divided by the week two weeks
after.][ratio_plot]][ratio_plot]

[ratio_plot]: {{ file_dir }}/accidents_two_weeks_after_dst_change_in_california.svg

Except for Sunday, every day of the week following the time change has on
average a higher rate of crashes! I am surprised that the crash rate stays
high the entire week. This indicates that it takes even longer than a week for
people to catch up on sleep and for the crash rate to go back to normal.

## _t_-Test

So the "_chi-by-eye_" plot is suggestive, but I can quantify whether the
results are significant using a [two-tailed paired _t_-test][paired_t-test].
This is the method Varughese & Allen use. Doing so gives the following
results.

[paired_t-test]: https://en.wikipedia.org/wiki/Student%27s_t-test#Paired_samples

| Day          | _t_-value |   _p_-value |
|:-------------|----------:|------------:|
| **Monday**   |       2.7 |   **0.017** |
| **Tuesday**  |       2.5 |   **0.023** |
| Wednesday    |       1.6 |     0.122   |
| Thursday     |       1.4 |     0.191   |
| Friday       |       0.9 |     0.361   |
| **Saturday** |       2.6 |   **0.019** |
| Sunday (DST) |      -1.6 |     0.121   |

The increase in crashes on Monday is significant, as is Tuesday and Saturday.
Sunday is the only day that trends lower (matching the plot), but not
significantly.

So daylight savings time causes more crashes, but those of us in California
might be in luck! State Assembly member [Kansen Chu][chu] has introduced a
bill to [finally do away with DST][ab-385]! Hopefully it will pass and let us
all get that hour of sleep we deserve.

[chu]: https://en.wikipedia.org/wiki/Kansen_Chu
[ab-385]: https://leginfo.legislature.ca.gov/faces/billTextClient.xhtml?bill_id=201520160AB385

---

**Updated <time datetime="{{ page.seo.date_modified | date_to_xmlschema }}">{{
page.seo.date_modified | date: '%B %d, %Y' }}</time>**: _I have rewritten part
of this article to make my methodology clearer and add a t-test. The changes
can be found in git; the [first set][changes_1] and the [second
set][changes_2]._

[changes_1]: https://github.com/agude/agude.github.io/commit/1092c8ce001a946eb47ae07cc0c65324a1417a82
[changes_2]: https://github.com/agude/agude.github.io/commit/2661f23d005a97206a03eca02f1078de9ae0fec4

[^1]: It is also possible to use the week before or the week directly after the DST change to normalize. For the curious, I have also made [a plot using the week before for normalization][before_plot] and [the week after][after_plot]. They both show the same trend.
[^2]: I assume that people are back to normal after three weeks, and so I use that week as a control. I then compare that ratios of the control week with [one week after the DST change][1_vs_3] and [two weeks after the DST change][2_vs_3] to see which is more normal. One week after has Monday and Thursday high, indicating people are still having more crashes than we expect. Two weeks after the ratios are near one, and so I conclude people are back to normal by then. 

[before_plot]: {{ file_dir }}/accidents_after_dst_change_in_california_before.svg
[after_plot]: {{ file_dir }}/accidents_after_dst_change_in_california.svg
[1_vs_3]: {{ file_dir }}/accidents_one_and_three_weeks_after_dst_change_in_california.svg
[2_vs_3]: {{ file_dir }}/accidents_two_and_three_weeks_after_dst_change_in_california.svg
