---
layout: post
title: "SWITRS: On What Days Do Motorcycles Crash?"
description: >
  Motorcycles riders are a different breed, born to chase excitment! So when
  do they crash? Using California's SWITRS data I find out! I'll give you a
  hint: it is not on the way to their 9-5!
image: /files/switrs-motorcycle-accidents-by-date/police_in_stockholm.jpg
show_lead_image: True
image_alt: >
  A black and white photo from 1959 of a policeman in full-leather protective
  gear. He stands over a motorcycle on side of a street in Stockholm as
  traffic passes by.
categories: 
  - california-traffic-data 
  - data-science
seo:
  date_modified: 2019-02-20T20:13:43-0800
---

{% capture file_dir %}/files/switrs-motorcycle-accidents-by-date{% endcapture %}

A few months ago I wrote a post in which [I explored when car crashes happen
in California][lastpost]. This time I'm going to go through the same analysis
but restrict myself to looking at crashes involving motorcycles. Motorcycle
crashes are the original reason I tracked down the [SWITRS][switrs] data: my
father rode motorcycles for years (he only recently stopped) and we wanted to
better understand what sort of risks that brought.

[lastpost]: {% post_url 2016-12-02-switrs_crashes_by_date %}
[switrs]: http://iswitrs.chp.ca.gov/Reports/jsp/userLogin.jsp

I expected the crash trend for motorcycles to match the one I found when
[looking at cars][lastpost]. There I found that commute crashes accounted for
the majority of crashes, and so holidays and weekends that most people have
off result in fewer crashes. Motorcycles, we will see, do not follow this
pattern.

One thing before we get started: the number of riders on a given day (or more
accurately, the [number of miles ridden by them][vmot]) has the most impact on
the number of crashes. If there are more riders, there are going to be more
crashes. From now on I'll treat the two numbers as equivalent, even though
there are some confounding factors, like weather, which would change the ratio
of crashes to number of riders on the road; I hope to look at these other
factors in a later post.

[vmot]: https://en.wikipedia.org/wiki/Vehicle_miles_of_travel

As per usual, the Jupyter notebook used to perform this analysis can be found
[here][notebook] ([rendered on Github][rendered]).

{% capture notebook_uri %}{{ "SWITRS Crash Dates With Motorcycles.ipynb" | uri_escape }}{% endcapture %} 

[notebook]: {{ file_dir }}/{{ notebook_uri }}
[rendered]: https://github.com/agude/agude.github.io/blob/master{{ file_dir }}/{{ notebook_uri }}

## Data Selection

I selected crashes involving motorcycles from the [SQLite database][s2s]
([discussed previously][s2s_post]) with the following query:

[s2s]: https://github.com/agude/SWITRS-to-SQLite
[s2s_post]: {% post_url 2016-11-01-switrs_to_sqlite %}

```sql
SELECT Collision_Date FROM Collision
WHERE Collision_Date IS NOT NULL
AND Motorcycle_Collision == 1       -- Involves a motorcycle
AND Collision_Date <= '2015-12-31'  -- 2016 is incomplete
```

This gave me 193,336 data points (crashes) to examine spanning 2001 through
2015\. [Just as before][ds], crashes from 2016 are rejected because there is
not yet complete data for the year.

[ds]: {% post_url 2016-12-02-switrs_crashes_by_date %}#data-selection

## Crashes per Week

For cars, [I found that there was a decrease in crashes][apw] starting in 2008
as people stopped driving to work during the [Great Recession][gr]. Apart from
that, I found that the week-to-week rate changed relatively little, with
holidays providing the largest increases and decreases. When I looked at just
motorcycles, I expected to see a similar pattern. However, the trends (plotted
below) are completely different.

[apw]: {% post_url 2016-12-02-switrs_crashes_by_date %}#crashes-per-week
[gr]: https://en.wikipedia.org/wiki/Great_Recession

[![Line plot showing crashes per week from 2001 to
2015][per_week_plot]][per_week_plot]

[per_week_plot]: {{ file_dir }}/motorcycle_accidents_per_week_in_california.svg

There are far fewer crashes because there are far fewer motorcycles; there are
about [27 million vehicles in California, but of those only 770,000 are
motorcycles][dot]. There is also a strong seasonal effect---even in sunny
California, motorcycle ridership drops drastically in the winter! And unlike
for cars, there is not a large decrease due to the recession. Finally, there
is an overall upward trend in the number of motorcycle crashes.

[dot]: https://www.fhwa.dot.gov/policyinformation/statistics/2012/mv1.cfm

Commute crashes account for the majority of car crashes. However, this does
not appear to be the case for motorcycles, because the numbers were relatively
unchanged by the Great Recession; people kept riding at the same levels when
out of work.

## Day-by-Day

For car, [the days with the most and least crashes were holidays][dbd]. The
largest number of crashes were on holidays where people went to work and then
out afterwards, like Halloween. Motorcycle crashes do not follow that pattern.
Instead, the holidays show quite disparate results: some holidays dip, some
spike, others show almost no deviation from a normal day.

[dbd]: {% post_url 2016-12-02-switrs_crashes_by_date %}#day-by-day

[![Line plot showing average motorcycle crashes by day of the
year][average_accidents]][average_accidents]

[average_accidents]: {{ file_dir }}/mean_motorcycle_accidents_by_date.svg

The summer holidays do not stand out; only Memorial Day is readily visible.
Winter holidays, by contrast, show both peaks and valleys. I would interpret
this as due to the seasonal weather:

- In summer, any day is a good day to ride.
- In the winter, the weather keeps riders off the road, except when a holiday
  gives them the extra motivation they need.

One final outlier to address: the sharp peak at the end of February is [leap
day][leapday]. The peak not an error, but is a statistical artifact. The mean
for all other days is calculated with `n = 15`, but only `n = 3` for leap day.

[leapday]: https://en.wikipedia.org/wiki/February_29

## Day of the Week

Car crashes [happen less during the weekend, when people aren't
commuting][dotw]. For motorcycles the weekends are prime riding times, and so
the number of crashes increases.

If we think of weekends as a kind of mini-holiday, they provide a way to look
at the same seasonal holiday phenomenon [discussed above][this_dbd]. Winter
holidays showed high variance, so I would expect to see some weekends with
high winter ridership, and some with low ridership. Summer holidays had low
variance, so I expect to see similar ridership on all summer weekends.

[dotw]: {% post_url 2016-12-02-switrs_crashes_by_date %}#day-of-the-week
[this_dbd]: #day-by-day

The [violin plots][violin] below show the distribution of crashes by day of
the week over the 15 year period. They are divided into two seasons: summer
(May--October) and winter (November--April).

[violin]: https://en.wikipedia.org/wiki/Violin_plot

[![Violin plot showing crashes by day of the week in summer and
winter][accident_violin_plot]][accident_violin_plot]

[accident_violin_plot]: {{ file_dir }}/motorcycle_accidents_by_day_of_the_week_and_season.svg

There is lower ridership in winter over all (top row), as indicated by the
central dotted line indicating average number of crashes. And we can see an
increase on weekends; but during the winter, that weekend increase is small as
compared with summer (bottom row). The winter distributions are more elongated
than those from summer, meaning that on some days there are many riders, and
on others there are almost none, just as we expected. Summer weekends, by
contrast, have consistently high ridership.

We can conclude that weekend rider behavior does seem to track seasonal
holiday riding behavior. And like the trends for holidays, the weekend results
could be due to weather.

## Conclusion

Motorcycle crashes do not follow the same trends as for cars. Motorcyclists
continue riding even when they do not have a job to commute to. Seasons have a
large effect on the number of riders out on the road. Motorcycle ridership has
variance for winter holidays and weekends when the weather may turn against
them. There are many more ways to explore motorcycle crashes---time of day,
type of motorcycle, vehicle at fault---but those will have to wait for another
day.

---

**Updated <time datetime="{{ page.seo.date_modified | date_to_xmlschema }}">{{
page.seo.date_modified | date: '%B %d, %Y' }}</time>**: _Edited post for
brevity, clarity, and correctness; see [this git diff][changes_1] and [this
git diff][changes_2]._

[changes_1]: https://github.com/agude/agude.github.io/commit/bf38e9a48a9933d55a2b03191f08a5517d879a05#diff-e120a9b3b16bca5a999f11e031230e3b
[changes_2]: https://github.com/agude/agude.github.io/commit/b0d5f8010df6f0d419bf1c3f36409f8a16165fc4#diff-e120a9b3b16bca5a999f11e031230e3b
