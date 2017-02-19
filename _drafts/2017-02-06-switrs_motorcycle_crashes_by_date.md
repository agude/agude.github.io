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
accidents are the original reason I tracked down the [SWITRS][switrs] data; my
father rode motorcycles for years (he only recently stopped) and we wanted to
better understand what sort of risks that brought ([clearly, not very much][survivorship_bias]).

[lastpost]: {% post_url 2016-12-02-switrs_crashes_by_date %}
[switrs]: http://iswitrs.chp.ca.gov/Reports/jsp/userLogin.jsp
[survivorship_bias]: https://en.wikipedia.org/wiki/Survivorship_bias

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

This gives me 193,336 data points to examine spanning 2001 to 2015. [Just as
before][ds], accidents from 2016 are rejected because there is not yet
complete data for the year.

[ds]: {% post_url 2016-12-02-switrs_crashes_by_date %}#data-selection

## Accidents per Week

The number of riders on a given day (or more accurately, the number of miles
ridden by them) has the most impact on the number of crashes. From now on
I'll treat the two as equivalent, even though there are some confounding factors,
like weather; I hope to look at these other factors in a later post.

[apw]: {% post_url 2016-12-02-switrs_crashes_by_date %}#accidents-per-week

To start, I plot the amount of motorcycle crashes week-by-week for all 15
years:

![Line plot showing accidents per week from 2001 to
2015]({{ site.url }}/files/switrs-motorcycle-accidents-by-date/motorcycle_accidents_per_week_in_california.svg)

The trend is strikingly different from [the one involving all accidents][apw]!
There are roughly 9000 accidents a week in California but only about 300 of
them involve motorcycles. There is also a much stronger seasonal effect---even
in sunny California people do not ride motorcycles in the winter! The general
trend is upwards with a small dip from the [Great Recession][gr], but it is
much less pronounced than the dip seen in the statistics for all accidents.
I can think of two possibilities:

1. There are many recreational motorcycle riders who continue riding even if
   out of work.
2. Motorcycle commuters were not as affected by the layoffs as the general
   population.

Of course some combination is also possible: perhaps commuters who were laid
off used their free time to ride more. I'll discuss the evidence for this "two
rider model" as we continue through the data.

[gr]: https://en.wikipedia.org/wiki/Great_Recession

## Day-by-day

There are clear seasonal trends, but there are even finer-grained effects. To
explore these I'll plot the average number of crashes by day of the year; this
plot was created in the exact same manner as the one looking at all vehicle
accidents from [last time][dbd]:

[dbd]: {% post_url 2016-12-02-switrs_crashes_by_date %}#day-by-day

![Line plot showing average accidents by day of the
year]({{ site.url }}/files/switrs-motorcycle-accidents-by-date/mean_motorcycle_accidents_by_date.svg)

The small number of motorcycle accidents leads to more "noise" in our time
series than we saw previously: even just five more motorcycle accidents
in a day leads to a 15-20% change! This is the reason we average the 15 years
together, it helps to smooth out single days where something horrible
happened, and lets us look at trends that depend on the date itself.

Once we account for the noise and the seasonal trend, we can see a few
differences from the [same plot for all vehicles][dbd]. During the first part
of the year there are some large swings, with MLK's Birthday and Valentine's
Day showing about 20% increases as compared to the surrounding days while
Washington's Birthday has about a 20% decrease. In the summer, holidays have a
minor effect, with only Memorial day showing a major deviation. As we head
into fall and winter, holidays start to show up again as decreases in the
number of accidents.

Using the two rider model mentioned above could explain these trends:
commuters ride more consistently through inclement weather because they have
to get to work while recreational riders are more likely to take the day off
if it is cold and rainy. Summer holidays show little deviation because
commuters who have the day off are replaced by recreational riders, whereas
drops are seen for winter holidays because the weather and shorter days keeps
recreational riders home.

This still leaves MLK's Birthday to explain, and I admit I do not have a good
theory. Perhaps, having not ridden all winter, the recreational riders are a
bit rusty (and hence have more accidents) but decide to make use of the
three-day weekend to get out and ride.

Finally, there is one outlier that I must address: the sharp peak between
Washington's Birthday and St. Patrick's Day is [leap day][leapday]. I believe
this peak is a statistical artifact; the mean for all other days is calculated
with `n = 15`, but only `n = 3` for leap day. A few more accidents than normal
would skew the mean high. The number of accidents are 36 in 2004, 49 in 2008,
and 22 in 2012.

[leapday]: https://en.wikipedia.org/wiki/February_29

## Day of the Week

Finally, each weekend is like a mini-holiday, so if my two rider model holds
then I would expect to see a similar seasonal trend: recreational riders
should fill in for missing commuters during the summer, and not as much during
the winter. To check, I [plotted][violin] the number of accidents by day of the
week, divided into winter (November--April) and summer (May--October) seasons.

[violin]: https://en.wikipedia.org/wiki/Violin_plot

![Violin plot showing accidents by day of the week in summer and winter]({{
site.url
}}/files/switrs-motorcycle-accidents-by-date/motorcycle_accidents_by_day_of_the_week_and_season.svg)

The weekday trend is similar for both seasons: Monday has the fewest
accidents, and the rest of the days are roughly equal. The weekends are where
the real differences lie. During the summer, there is a substantial increase in
the number of accidents (including on Friday), while in the winter the
increase is there but less prominent. This suggests that there are
recreational riders at all times, but especially during the summer.

This is not the exact trend we observed for holidays, where we saw a constant
number of riders during the summer, and a decrease in winter. However, this
might be accounted for by the fact that riders, or all types, are less likely
to ride on holidays, perhaps because they have social events to attend.

## Conclusion

The idea that there are two types of motorcycle riders is an interesting one,
and one I think riders themselves would support. I see hints of it in the
data, but nothing conclusive. In the future I'd like to try exploring it more
by looking at the types of motorcycles, where they crash, and the types of
accidents. I suspect all three of these will be quite different between the
two populations.
