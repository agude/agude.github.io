---
layout: post
title: "SWITRS: Car Crashes After Daylight Saving Time Ends"
description: >
  Day light saving time leaves leads to more traffic collisions, but what
  about when DST ends? Some researchers have found that it does lead to more
  crashes, so I take a look using California's SWITRS data.
image: /files/switrs-dst/a_woman_sets_the_clocks_forward.jpg
image_alt: >
  A blonde woman adjusts the time on a row of clocks at a store.
categories: 
  - data-science
  - california-traffic-data 
---

{% capture file_dir %}/files/switrs-dst{% endcapture %}

We all hate the change to [daylight saving time][dst] (DST) in the spring; it
makes us tired, grumpy, but worst of all it [causes us to crash our cars at a
higher rate][dst_article]! The end of DST is not as universally reviled,
probably because we get back the hour of sleep we lost earlier in the year,
but [Varughese & Allen][varughese] found that there was still a "significant
increase in number of crashes on the Sunday of the fall shift from
DST".[^varughese_cite]

[^varughese_cite]:
    {% citation
      author_last="J. Varughese and R. Allen"
      work_title="Fatal accidents following changes in daylight savings time: the American experience"
      container_title="Sleep Medicine"
      volume="2"
      number="1"
      first_page="31"
      last_page="36"
      date="2000"
      doi="10.1016/S1389-9457(00)00032-0"
      url="https://doi.org/10.1016/S1389-9457(00)00032-0"
    %}

[dst]: https://en.wikipedia.org/wiki/Daylight_saving_time
[dst_article]: {% post_url 2017-03-20-switrs_daylight_saving_time_accidents %}
[varughese]: https://doi.org/10.1016/S1389-9457(00)00032-0

With the [SWIRTS data][s2s_post] that I collected, and the analysis code I
developed for [my post last year looking at car crashes after the DST
change][dst_article], it should be pretty easy to check if I see the same
trend as Varughese & Allen.

[s2s_post]: {% post_url 2016-11-01-switrs_to_sqlite %}

The Jupyter notebook used to perform this analysis can be found
[here][notebook] ([rendered on Github][rendered]).

{% capture notebook_uri %}{{ "SWITRS Daylight Saving Time Crashes.ipynb" | uri_escape }}{% endcapture %} 

[notebook]: {{ file_dir }}/{{ notebook_uri }}
[rendered]: https://github.com/agude/agude.github.io/blob/master{{ file_dir }}/{{ notebook_uri }}

## Crash Ratio

Just like [last time][dst_ar], I will look at the number of crashes on the
days following the end of DST. In order to help cancel out effects other than
the time change---like the fact that [crash rates vary by 30% depending on the
year][apw]---I will divide each day's total by the number of crashes a week
later, when people are presumably back to normal. 

[apw]: {% post_url 2016-12-02-switrs_crashes_by_date %}#crashes-per-week
[dst_ar]: {% post_url 2017-03-20-switrs_daylight_saving_time_accidents %}#crash-ratio

Unlike last time, I am not normalizing by the number of crashes two weeks
after the change. The reason for this is simple: that's Thanksgiving week, and
[as I showed before][thanksgiving] the number of crashes is greatly reduced
during the holidays.

[thanksgiving]: {% post_url 2016-12-02-switrs_crashes_by_date %}#day-by-day

Just as last time, the [violin plots][violin] below show the distribution of
these ratios from the years 2001 to 2017. A value greater than 1 means that
there are more crashes during the week when DST ends than the week after.

[violin]: https://en.wikipedia.org/wiki/Violin_plot

[![Violin plot showing the ratio of crashes per day of the week for the week
daylight saving time ends, divided by the week
after.][ratio_plot]][ratio_plot]

[ratio_plot]: {{ file_dir }}/accidents_after_end_dst_in_california.svg

There is, on average, a larger number of crashes on Sunday when the time
changes as seen by Varughese & Allen. However, the same excess is not seen
when a different normalization is chosen, like using the [week
before][before_plot] or [two weeks after][after_plot].[^after] The week before
has different lighting during commute times and so it is easier to dismiss,
but two weeks after has similar lighting.

[before_plot]: {{ file_dir }}/accidents_after_end_dst_in_california_before.svg
[after_plot]: {{ file_dir }}/accidents_two_weeks_after_end_dst_in_california.svg
[^after]: The large deviations on the two week plot for Thursday and Friday are explained by Thanksgiving and Black Friday.

## _t_-Test

Instead, we turn away from our "_chi-by-eye_" test and do an actual
statistical test: a [_two-tailed paired t-test_][paired_t-test], the same test
used by Varughese & Allen. They find a significant (_p_ < 0.002) increase in
the number of deadly crashes on the Sunday that DST ends, but I do not (_p_
= 0.082).

Our methods are different in a few key ways: 

- They look only at fatal crashes while I look at all.

- They compare to the mean of the week before and after while I use only the week after.

If I reproduce their methods with my dataset, I still do not find a
significant result (_p_ = 0.158).

[paired_t-test]: https://en.wikipedia.org/wiki/Student%27s_t-test#Paired_samples

As for California, [Kansen Chu][chu] has once again given us a chance to get
rid of the time change with [Prop 7][prop7]. His [earlier bill
failed][ab-385], so he has gone directly to the voters this time. Although
[permanent DST is not the ideal solution][usc], I'm still for getting rid of
the time change itself!

[chu]: https://en.wikipedia.org/wiki/Kansen_Chu
[prop7]: https://ballotpedia.org/California_Proposition_7,_Permanent_Daylight_Saving_Time_Measure_(2018)
[usc]: https://medium.com/@USC/why-proposition-7-is-bad-for-public-health-825905ba54f6
[ab-385]: https://leginfo.legislature.ca.gov/faces/billTextClient.xhtml?bill_id=201520160AB385
