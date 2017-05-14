---
layout: post
title: "SWITRS: On What Days Do Motorcycles Crash?"
description: >
  Motorcycles riders are a different breed, born to chase excitment! So when
  do they crash? Using California's SWITRS data I find out! I'll give you a
  hint: it is not on the way to their 9-5!
image: /files/switrs-motorcycle-accidents-by-date/police_in_stockholm.jpg
---

{% capture file_dir %}{{ site.url }}/files/switrs-motorcycle-accidents-by-date{% endcapture %}

![A policeman on a motorcycle in Stockholm, 1959]({{ file_dir
}}/police_in_stockholm.jpg)

A few months ago I wrote a post in which [I explored when accidents happen in
California][lastpost]. This time I'm going to go through the same analysis but
restrict myself to looking at accidents involving motorcycles. Motorcycle
accidents are the original reason I tracked down the [SWITRS][switrs] data: my
father rode motorcycles for years (he only recently stopped) and we wanted to
better understand what sort of risks that brought.

[lastpost]: {% post_url 2016-12-02-switrs_crashes_by_date %}
[switrs]: http://iswitrs.chp.ca.gov/Reports/jsp/userLogin.jsp

I expected the general trends to match the trends I found when [looking at all
motor vehicles][lastpost]. There I found that commute accidents accounted for
the majority of accidents, and so holidays and weekends that most people have
off result in fewer accidents. Motorcycles, we will see, do not follow these
trends.

One thing before we get started: the number of riders on a given day (or more
accurately, the [number of miles ridden by them][vmot]) has the most impact on
the number of crashes. If there are more riders, there are going to be more
crashes. From now on I'll treat the two numbers as equivalent, even though
there are some confounding factors, like weather, which would change the ratio
of accidents to number of riders on the road; I hope to look at these other
factors in a later post.

[vmot]: https://en.wikipedia.org/wiki/Vehicle_miles_of_travel

As per usual, the Jupyter notebook used to perform this analysis can be found
[here][notebook] ([rendered on Github][rendered]).

[notebook]: {{ file_dir }}/SWITRS Crash Dates With Motorcycles.ipynb
[rendered]: https://github.com/agude/agude.github.io/blob/master/files/switrs-motorcycle-accidents-by-date/SWITRS%20Crash%20Dates%20With%20Motorcycles.ipynb

## Data Selection

I selected accidents involving motorcycles from the [SQLite database][s2s]
([discussed previously][s2s_post]) with the following query:

[s2s]: https://github.com/agude/SWITRS-to-SQLite
[s2s_post]: {% post_url 2016-11-01-switrs_to_sqlite %}

{% highlight sql %}
SELECT Collision_Date FROM Collision
WHERE Collision_Date IS NOT NULL
AND Motorcycle_Collision == 1       -- Involves a motorcycle
AND Collision_Date <= '2015-12-31'  -- 2016 is incomplete
{% endhighlight %}

This gave me 193,336 data points (accidents) to examine spanning 2001 to 2015.
[Just as before][ds], accidents from 2016 are rejected because there is not
yet complete data for the year.

[ds]: {% post_url 2016-12-02-switrs_crashes_by_date %}#data-selection

## Accidents per Week

For all motor vehicles, [I found that there was a decrease in accidents][apw]
starting in 2008 as people stopped driving to work during the [Great
Recession][gr]; but apart from that trend, I found that the week-to-week rate
changed relatively little, with holidays providing the largest increases and
decreases. When I looked at just motorcycles, I expected to see similar
trends. However, the trends (plotted below) are completely different.

[apw]: {% post_url 2016-12-02-switrs_crashes_by_date %}#accidents-per-week
[gr]: https://en.wikipedia.org/wiki/Great_Recession

![Line plot showing accidents per week from 2001 to 2015]({{ file_dir
}}/motorcycle_accidents_per_week_in_california.svg)

As expected, there are far fewer accidents because there are far fewer
motorcycles: there are about [27 million vehicles in California, but of those
only 770,000 are motorcycles][dot]. The next observation is that, unlike for
all vehicles, there is a strong seasonal effect---even in sunny California,
motorcycle ridership drops drastically in the winter! And unlike the trend for
all vehicles, there is not a large decrease due to the recession. Finally, I
note that there is an overall upward trend in the number of motorcycle
accidents.

[dot]: https://www.fhwa.dot.gov/policyinformation/statistics/2012/mv1.cfm

As I noted above, commute accidents for all vehicles account for the majority
of accidents. However, the data suggest that for accidents involving
motorcycles, commute traffic is not dominant. Moreover, unlike the results for
all vehicles, people keep riding even when out of work; but they also stop
riding when the weather is poor. Next we'll look at accidents by day of the
year instead of by week.

## Day-by-Day

When looking at all motor-vehicle accidents [I observed that holidays were the
maxima and minima][dbd] in the average number of crashes by day of the year.
On holidays where people have the day off, the number of crashes decreases,
whereas the number increases on holidays where people work and then go out
afterward, like Halloween. Motorcycle accidents do not follow this trend.
Instead, the holidays show quite disparate results: some holidays dip, some spike,
others show almost no deviation from a normal day.

[dbd]: {% post_url 2016-12-02-switrs_crashes_by_date %}#day-by-day

![Line plot showing average motorcycle accidents by day of the year]({{
file_dir }}/mean_motorcycle_accidents_by_date.svg)

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

![Violin plot showing accidents by day of the week in summer and winter]({{
file_dir }}/motorcycle_accidents_by_day_of_the_week_and_season.svg)

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
