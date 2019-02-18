---
layout: post
title: "SWITRS: On What Days Do Cyclists Crash?"
description: >
  Motorcycles riders are a different breed, born to chase excitment! So when
  do they crash? Using California's SWITRS data I find out! I'll give you a
  hint: it is not on the way to their 9-5!
image: /files/switrs-bicycle-accidents-by-date/wilhelmina_cycle_co.jpg
image_alt: >
  An 1890s advertisement for Wilhelmina Cycle Co. Ltd. showing a family on bicycles.
use_latex: True
categories: switrs
---

{% capture file_dir %}/files/switrs-bicycle-accidents-by-date{% endcapture %}

{% include lead_image.html %}

It is time use [SWITRS data][switrs] to look at traffic accidents in
California again. I have previously used the data to look [when cars
crash][car_switrs]---during holidays when people both drive to work and to
parties after---and [when motorcycles crash][mc_switrs]---during the summer
when its good riding weather. Today I want to look at something a little
closer to my heart: **bicycle accidents**.

[switrs]: http://iswitrs.chp.ca.gov/Reports/jsp/userLogin.jsp
[car_switrs]: {% post_url 2016-12-02-switrs_crashes_by_date %}
[mc_switrs]: {% post_url 2017-02-21-switrs_motorcycle_crashes_by_date %}

I have been commuting on my bike for years now, and before I had kids I put in
thousands of miles a year for fun.

As per usual, the Jupyter notebook used to perform this analysis can be found
[here][notebook] ([rendered on Github][rendered]).

{% capture notebook_uri %}{{ "SWITRS Crash Dates With Bicycles.ipynb" | uri_escape }}{% endcapture %} 

[notebook]: {{ file_dir }}/{{ notebook_uri }}
[rendered]: https://github.com/agude/agude.github.io/blob/master{{ file_dir }}/{{ notebook_uri }}

## Data Selection

I selected accidents involving bicycles from the [SQLite database][s2s]
([discussed previously][s2s_post]) with the following query:

[s2s]: https://github.com/agude/SWITRS-to-SQLite
[s2s_post]: {% post_url 2016-11-01-switrs_to_sqlite %}

{% highlight sql %}
SELECT Collision_Date FROM Collision
WHERE Collision_Date IS NOT NULL
AND Bicycle_Collision == 1          -- Involves a bicycle
AND Collision_Date <= '2017-12-31'  -- 2018 is incomplete
{% endhighlight %}

This gave me 223,772 data points (accidents) to examine spanning 2001 to 2017.
[Just as before][ds], accidents from the most recent year are rejected because
the data has not been fully 

[ds]: {% post_url 2016-12-02-switrs_crashes_by_date %}#data-selection

## Accidents per Week

I have a simple model for how bicycle accidents happen. I got it 

$$ \sigma_{bike} = \lambda l \rho_{car}$$

Where $$\sigma_{bike}$$  $$\lambda l \rho_{car}$$

For car crashes, [I found that that was a large dip in 2008][car_apw] as
people stopped driving to work during the [Great Recession][gr]. For
motorcycle crashes, [I found strong seasonality][mc_apw] as people hung up
their helmets during the winter. For bicycles, we have the following pattern:

[car_apw]: {% post_url 2016-12-02-switrs_crashes_by_date %}#accidents-per-week
[mc_apw]: {% post_url 2017-02-21-switrs_motorcycle_crashes_by_date %}#accidents-per-week
[gr]: https://en.wikipedia.org/wiki/Great_Recession

[![Line plot showing bicycles accidents per week from 2001 through
2017][per_week_plot]][per_week_plot]

[per_week_plot]: {{ file_dir }}/bicycle_accidents_per_week_in_california.svg

## Day-by-Day

When looking at all motor-vehicle accidents [I observed that holidays were the
maxima and minima][dbd] in the average number of crashes by day of the year.
On holidays where people have the day off, the number of crashes decreases,
whereas the number increases on holidays where people work and then go out
afterward, like Halloween. Motorcycle accidents do not follow this trend.
Instead, the holidays show quite disparate results: some holidays dip, some spike,
others show almost no deviation from a normal day.

[dbd]: {% post_url 2016-12-02-switrs_crashes_by_date %}#day-by-day

[![Line plot showing average motorcycle accidents by day of the
year][average_accidents]][average_accidents]

[average_accidents]: {{ file_dir }}/mean_bicycle_accidents_by_date.svg

The summer holidays do not stand out; only Memorial Day is readily visible.
Winter holidays, by contrast, show both peaks and valleys. I would interpret
this as due to the seasonal weather: during the summer, any day is a good day
to ride; but during the winter the weather keeps many riders off the roads on
most days. But it would appear that some winter holidays provide riders with
the extra motivation to get out on the bike. Look, for example, at Martian
Luther King Jr. Day, which occurs in January.

There is one outlier that I must address. The sharp peak between Washington's
Birthday and St. Patrick's Day is [leap day][leapday]. This peak is a
statistical artifact. The mean for all other days is calculated with `n = 15`,
but only `n = 3` for leap day.

[leapday]: https://en.wikipedia.org/wiki/February_29

## Day of the Week

The weekends [showed a decrease in the number of all motor-vehicle
accidents][dotw]. But for motorcycles, for whom weekends are the prime riding
time, there is actually an increase on the weekends. If we think of weekends
as a kind of mini-holiday, they provide a way to look at the same seasonal
holiday phenomenon [discussed above][this_dbd]. Winter holidays showed high
variance, so I would expect to see some weekends with high winter ridership,
and some with low ridership. Summer holidays had low variance, so I expect to
see similar ridership on all summer weekends.

[dotw]: {% post_url 2016-12-02-switrs_crashes_by_date %}#day-of-the-week
[this_dbd]: #day-by-day

The [violin plots][violin] below show the distribution of accidents by day of
the week over the 15 year period. They are divided into two seasons: summer
(May--October) and winter (November--April).

[violin]: https://en.wikipedia.org/wiki/Violin_plot

[![Violin plot showing accidents by day of the week in summer and
winter][accident_violin_plot]][accident_violin_plot]

[accident_violin_plot]: {{ file_dir }}/bicycle_accidents_by_day_of_the_week.svg

There is lower ridership in winter over all (top row), as indicated by the
central dotted line indicating average number of accidents. And we can see an
increase on weekends; but during the winter, that weekend increase is small as
compared with summer (bottom row). However, the winter distributions are more
elongated than those from summer, meaning that on some days there are many
riders, and on others there are almost none. Summer weekends, by contrast,
have consistently high ridership.

Thus, it appears we can conclude that weekend rider behavior does seem to
track seasonal holiday riding behavior. And like the trends for holidays, the
weekend results could be due to weather.

## Conclusion

Motorcycle accidents do not follow the same trends as for all motor vehicles.
Motorcyclists continue riding even when they do not have a job.  Seasons have
a large effect on the number of riders out on the road. Riders are also out on
holidays in the summer when other vehicles take the day off, and have high
variance for winter holidays and weekends when the weather may turn against
them. There are many more ways to explore motorcycle accidents---time of day,
type of motorcycle, vehicle at fault---but those will have to wait for another
day.
