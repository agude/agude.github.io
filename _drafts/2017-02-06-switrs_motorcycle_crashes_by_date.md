---
layout: post
title: "SWITRS: On What Days Do Motorcycles Crash?"
description: >
  On what day of the year do motorcycles crash? Do riders take the day off for
  Christmas? Do they even ride in the winter? Find out when I look at SWITRS crash
  data!
image: /files/switrs-motorcycle-accidents-by-date/african-american-mp-wwii.jpg
---

![A policeman on a motorcycle in Stockholm, 1959]({{ site.url
}}/files/switrs-motorcycle-accidents-by-date/police_in_stockholm.jpg)

A few months ago I wrote a post in which [I explored when accidents happen in
California][lastpost]. This time I'm going to go through the same analysis but
restrict myself to looking at accidents involving motorcycles. Motorcycle
accidents are the original reason I tracked down the [SWITRS][switrs] data: my
father rode motorcycles for years (he only recently stopped) and we wanted to
better understand what sort of risks that brought.

[lastpost]: {% post_url 2016-12-02-switrs_crashes_by_date %}
[switrs]: http://iswitrs.chp.ca.gov/Reports/jsp/userLogin.jsp

I expected the general trends to match the trends I found when [looking at all
motor-vehicles][lastpost]. There I found that commute accidents accounted for
the majority of accidents, and so holidays where people got the day off
resulted in many fewer accidents, while holidays where people did not get the
day off resulted in more accidents as people commuted and then drove to
holiday events after work.

One thing before we get started: the number of riders on a given day (or more
accurately, the [number of miles ridden by them][vmot]) has the most impact on
the number of crashes. If there are more riders, there are going to be more
crashes. From now on I'll treat the two numbers as equivalent, even though
there are some confounding factors, like weather; I hope to look at these
other factors in a later post.

[vmot]: https://en.wikipedia.org/wiki/Vehicle_miles_of_travel

As per usual, the Jupyter notebook used to perform this analysis can be found
[here][notebook] ([rendered on Github][rendered]).

[notebook]: {{ site.url }}/files/switrs-motorcycle-accidents-by-date/SWITRS Crash Dates With Motorcycles.ipynb
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

This gave me 193,336 data points to examine spanning 2001 to 2015. [Just as
before][ds], accidents from 2016 are rejected because there is not yet
complete data for the year.

[ds]: {% post_url 2016-12-02-switrs_crashes_by_date %}#data-selection

## Accidents per Week

For all motor-vehicles [I found that there was a decrease in accidents][apw]
starting in 2008 as people stopped driving to work during the [Great
Recession][gr], but otherwise that week-to-week rate changed relatively
slowly, with holidays providing the largest increases and decreases. For just
motorcycles, plotted below, the trends are completely different.

[apw]: {% post_url 2016-12-02-switrs_crashes_by_date %}#accidents-per-week
[gr]: https://en.wikipedia.org/wiki/Great_Recession

![Line plot showing accidents per week from 2001 to 2015]({{ site.url
}}/files/switrs-motorcycle-accidents-by-date/motorcycle_accidents_per_week_in_california.svg)

As expected there are far fewer accidents because there are far fewer
motorcycles: there are about [27 million vehicles in California but only
770,000 motorcycles][dot]. There is, however, a strong seasonal effect---even
in sunny California motorcycle ridership drops drastically in the winter!
Unlike for trend for all vehicles, there is not a large decrease due to the
recession, and there is an overall upward trend.

[dot]: https://www.fhwa.dot.gov/policyinformation/statistics/2012/mv1.cfm

These trends suggest that commute traffic is not dominant for motorcycles.
People keep riding even when out of work, but they also stop riding when the
weather is poor. We'll look at accidents by day of the year instead of a week
at a time.

## Day-by-day

When looking at all motor-vehicle accidents [I observed that holidays were the
maxima and minima][dbd] in the average number of crashes by day of the year.
On holidays where people have the day off the number of crashes decrease,
whereas the number increases on holidays where people work and then go out
afterward. Motorcycle accidents do not follow this trend. Instead, the
holidays show higher variance: some holidays dip, some spike, others show
almost deviation from a normal day.

[dbd]: {% post_url 2016-12-02-switrs_crashes_by_date %}#day-by-day

![Line plot showing average accidents by day of the
year]({{ site.url }}/files/switrs-motorcycle-accidents-by-date/mean_motorcycle_accidents_by_date.svg)

The summer holidays are muted, many hardly visible in the data. Winter
holidays, but contrast show both peaks and valleys. I would interpret this as
due to the seasonal weather: during the summer any day is a good day to ride,
but during the winter the weather provides either an excuse to stay in most
days, but some holidays provide the extra motivation to get out on the bike.

There is one outlier that I must address. The sharp peak between Washington's
Birthday and St. Patrick's Day is [leap day][leapday]. This peak is a
statistical artifact. The mean for all other days is calculated with `n = 15`,
but only `n = 3` for leap day.

[leapday]: https://en.wikipedia.org/wiki/February_29

## Day of the Week

The weekends [showed a decrease in the number of all motor-vehicle
accidents][dotw], but for motorcycles weekends are prime riding time and so we
actually see an increase on the weekends. Weekends are actually like a
mini-holiday, so they provide a way to look at the same seasonal holiday
phenomenon [discussed above][this_dbd].

[dotw]: {% post_url 2016-12-02-switrs_crashes_by_date %}#day-of-the-week
[this_dbd]: #day-by-day

These [violin plots][violin] show the distribution of accidents by day of the
week over the 15 years. They are divided into two seasons: summer
(May--October) and winter (November--April).

[violin]: https://en.wikipedia.org/wiki/Violin_plot

![Violin plot showing accidents by day of the week in summer and winter]({{
site.url
}}/files/switrs-motorcycle-accidents-by-date/motorcycle_accidents_by_day_of_the_week_and_season.svg)

There is lower ridership in winter over all, but there is also a smaller
increase in the number of riders out on the weekend. However, the
distributions are elongated as compared to summer meaning on some days there
are many riders, and some days there are almost none. Like the trends for
holidays, this could be due to weather. Summer weekends have consistently high
ridership.

## Conclusion

Motorcycle accidents do not follow the same trends as for all motor-vehicles.
Motorcyclists continue riding even when they do not have a job, but seasons
have a large effect on the number of riders out on the road.
Riders are also out on holidays in the summer when other vehicles take the day
off, and have high variance for winter holidays and weekends when the weather
may turn against them. There are many more ways to explore motor cycle
accidents---time of day, type of motorcycle, vehicle at fault---but those will
have to wait for another day.
