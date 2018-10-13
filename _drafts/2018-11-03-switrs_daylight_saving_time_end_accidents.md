---
layout: post
title: "SWITRS: Accidents After Daylight Saving Time Ends"
description: >
  Day light saving time leaves leads to more traffic accidents, but what about
  when DST ends? Some researchers have found that it does lead to more
  accidents, so I take a look using California's SWITRS data.
image: /files/switrs-dst/a_woman_sets_the_clocks_forward.jpg
image_alt: >
  A blonde woman adjusts the time on a row of clocks at a store.
categories: switrs
---

{% capture file_dir %}/files/switrs-dst{% endcapture %}

{% include lead_image.html %}

We all hate the change to [daylight saving time][dst] (DST) in the spring; it
makes us tired, grumpy, but worst of all it [causes us to crash our cars at a
higher rate][dst_article]! The end of DST is not as universally reviled,
probably because we get the hour of sleep we lost back, but [Varughese &
Allen][varughese] found that there was a "significant increase in number of
accidents on the Sunday of the fall shift from DST".[^1]

[dst]: https://en.wikipedia.org/wiki/Daylight_saving_time
[dst_article]: {% post_url 2017-03-20-switrs_daylight_saving_time_accidents %}
[varughese]: https://doi.org/10.1016/S1389-9457(00)00032-0

With the [SWIRTS data][s2s_post] that I collected, and the analysis code I
developed for [my post last year looking at car accidents after the DST
change][dst_article], it should be pretty easy to check if I see the same
trend as Varughese & Allen.

[s2s_post]: {% post_url 2016-11-01-switrs_to_sqlite %}

The Jupyter notebook used to perform this analysis can be found
[here][notebook] ([rendered on Github][rendered]).

{% capture notebook_uri %}{{ "SWITRS Daylight Saving Time Crashes.ipynb" | uri_escape }}{% endcapture %} 

[notebook]: {{ file_dir }}/{{ notebook_uri }}
[rendered]: https://github.com/agude/agude.github.io/blob/master{{ file_dir }}/{{ notebook_uri }}

## Accident Ratio

Just like [last time][dst_ar], I will look at the number of accidents on the
days following the end of DST. In order to help cancel out effects other than
the time change---like the fact that [accident rates vary by 30% depending on
the year][apw]---I will divide each day's total by the number of accidents a
week later, when people are presumably back to normal. 

[apw]: {% post_url 2016-12-02-switrs_crashes_by_date %}#accidents-per-week
[dst_ar]: {% post_url 2017-03-20-switrs_daylight_saving_time_accidents %}#accident-ratio

Unlike last time, I am not normalize by the number of accidents two weeks
after the change. The reason for this is simple: that's Thanksgiving week, and
[as I showed before][thanksgiving] the number of accidents is greatly reduced
during the holidays.

[thanksgiving]: {% post_url 2016-12-02-switrs_crashes_by_date %}#day-by-day

Just as last time, the [violin plots][violin] below show the distribution of
these ratios from the years 2001 to 2017. A value greater than 1 means that
there are more accidents during the week when DST starts than two weeks after.

[violin]: https://en.wikipedia.org/wiki/Violin_plot

[![Violin plot showing the ratio of accidents per day of the week for the week
after the start of daylight saving time, divided by the week two weeks
after.][ratio_plot]][ratio_plot]

[ratio_plot]: {{ file_dir }}/accidents_after_end_dst_in_california.svg

There is, on average, a larger number of crashes on Sunday when the time
changes as seen by [Varughese & Allen][varughese]. However, the same excess is
not seen when a different normalization is chosen, like using the [week
before][before_plot] or [two weeks after][after_plot].[^2] The week before has
different lighting during commute times and so it is easier to dismiss, but
two weeks after has similar lighting.

[before_plot]: {{ file_dir }}/accidents_after_end_dst_in_california_before.svg
[after_plot]: {{ file_dir }}/accidents_two_weeks_after_end_dst_in_california.svg

## _t_-Test

Instead, we turn away from our "_chi-by-eye_" test and do an actual statistical
test: a [_two-tailed paired t-test_][paired_t-test], the same test used by
[Varughese & Allen][varughese]. They find a significant (_p_ < 0.002) increase
in the number of deadly accidents on the Sunday that DST ends, but I do not
(_p_ = 0.082).

Our methods are different in a few key ways: 

- They look only at fatal accidents while I look at all.
- They compare to the mean of the week before and after while I use only the week after.

If I reproduce their methods with my dataset, I still do not find a
significant result (_p_ = 0.158).

[paired_t-test]: https://en.wikipedia.org/wiki/Paired_difference_test

## Prop 7

I do not find a significant increase in the number of accidents when
DST ends.

As for California, [Kansen Chu][chu] has once again given us a chance to get
rid of the time change with [Prop 7][prop7]. His [earlier bill
failed][ab-385], so he has gone directly to the voters this time. I, for one,
am voting yes!

[chu]: https://en.wikipedia.org/wiki/Kansen_Chu
[prop7]: https://ballotpedia.org/California_Proposition_7,_Permanent_Daylight_Saving_Time_Measure_(2018)
[ab-385]: https://leginfo.legislature.ca.gov/faces/billTextClient.xhtml?bill_id=201520160AB385

---

[^1]: Varughese, J. and Allen, R., _Fatal accidents following changes in daylight savings time: the American experience_, Sleep Medicine, Volume 2, Issue 1, p. 31 - 36, doi: [https://doi.org/10.1016/S1389-9457(00)00032-0][varughese]
[^2]: The large deviations on the two week plot for Thursday and Friday are explained by Thanksgiving and Black Friday.
