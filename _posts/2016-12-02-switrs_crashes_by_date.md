---
layout: post
title: "SWITIRS: On What Days Do People Crash?"
description: >
  What day of the year has the most car crashes? The fewest? Find out as I
  look at California's accident data! Hint: they're both holidays!
image: /files/switrs_accidents_by_date/1923_dc_car_crash.jpg
---

![Men gathered around a crashed car in Washington DC, 1923]({{ site.url
}}/files/switrs_accidents_by_date/1923_dc_car_crash.jpg)

The [Statewide Integrated Traffic Records System
(SWITRS)](http://iswitrs.chp.ca.gov/Reports/jsp/userLogin.jsp) contains a
wealth of information, enough to determine who, where, when, and sometimes why
and how for every traffic accident in California. Today, with the assistance of my
[SWITRS-to-SQLite script](https://github.com/agude/SWITRS-to-SQLite)
([discussed previously]({% post_url 2016-11-01-switrs_to_sqlite %})), I'm
going to look at when accidents happen, and specifically on what dates.

As always, the Jupyter notebook used to do this analysis can be found
[here]({{ site.url }}/files/switrs_accidents_by_date/SWITRS Crash Dates.ipynb)
([rendered on
Github](https://github.com/agude/agude.github.io/blob/master/files/switrs_accidents_by_date/SWITRS%20Crash%20Dates.ipynb)).

## Data Selection

The data was selected using the following query:

{% highlight sql %}
SELECT Collision_Date
FROM Collision AS C
WHERE Collision_Date IS NOT NULL
AND Collision_Date <= '2015-12-31'  -- 2016 is incomplete
{% endhighlight %}

This selects every accident that happened before 2016 that has a collision
date stored. The current year, 2016, is excluded because the data from it is
incomplete.

The first thing to look at is crashes as a function of time. Below, I plot
accidents per week to make the trends clearer; plotting per day results in too
many points to separate by eye.

![Line plot showing accidents per week from 2001 to
2015]({{ site.url }}/files/switrs_accidents_by_date/accidents_per_week_in_california.svg)

The week-to-week variation is rather significant, but two major trends are
obvious:

1. The total number of accidents has been decreasing over the past few years,
   with a big drop in 2008, but is now rising sharply in 2015.
2. Each year is similar, with a mid-year lull and wildly varying
   increases and decrease right before the end of the year.

The first trend is easy to explain: the [Great
Recession](https://en.wikipedia.org/wiki/Great_Recession) put many people
out of work, who then stopped commuting. The second trend is also due to
reduced driving; we'll look at it in detail below.

## Day-by-day

To explore the second trend, we'll need to look at the data day-by-day instead
of a week at a time. Below is a plot of the average number of accidents on
each day of the year. The average is calculated by summing the number of
accidents on a specific day (say, September 22nd) across the years 2001 to 2015. The
sum is then divided by the number of times that specific day appeared in the
timespan (15, except for the [leap day](https://en.wikipedia.org/wiki/February_29),
which only appears 3 times).

![Line plot showing average accidents by day of the
year]({{ site.url }}/files/switrs_accidents_by_date/mean_accidents_by_date.svg)

Holidays account for the extrema, with the minimum number of accidents taking
place on Christmas, and the maximum number taking place on Halloween. In fact,
many of the local maxima and minima are also holidays! Some create obvious,
multi-day patterns (like Thanksgiving) because they are floating holidays
while others (like Christmas and Halloween) create massive, single-day dips or
spikes because they happen on the same day every year. Holidays that fewer
people get off from work, like Washington's Birthday and Columbus Day, show
almost no deviation from the surrounding dates.

But perhaps the most interesting dates are the holidays where the number of
accidents **increases**! Halloween is the most obvious of these, and sets the
record for the **highest number of accidents**, but Valentine's Day and St.
Patrick's Day also show increases. I believe there are two reasons these
holidays have higher than normal accident counts. First, these are not
generally paid holidays, so the normal number of commute-related accidents
happen. Second, these are holidays are celebrated away from home after work
(for drinks, dates, or candy), and so people drive more on these days than
they would otherwise. I suspect that there is a third reason behind
Halloween's high accident count: a higher than average number of pedestrians
being out and about leading to a higher than average number of accidents
involving pedestrians. I plan to look at pedestrian accidents in a later blog
post.

## Day of the Week

Finally, let's look at accidents by day of the week. On weekends, like
holidays, we would expect most people to not go to work. Below is a plot of
accidents by day of the week. It is a strip plot (or sometimes a univariate
dot plot) where each day in the dataset is plotted as a dot. The y position of
the dot indicates the number of accidents, while the x position only indicates
the day of the week with random jitter added to reduce overlap. For each
collection of dots I have also plotted one and two standard
deviations using error bars. The black dot in the middle is the mean.

![Strip plot showing accidents by day of the
week]({{ site.url }}/files/switrs_accidents_by_date/accidents_by_day_of_the_week.svg)

The first four weekdays have roughly the same number of crashes. Friday has
more, presumably because people are more likely to go out after work. Saturday
drops to a level slightly below the weekdays, though not by much, and Sunday
has the lowest accident count.

So in the end the results are not too surprising: accidents happen when people
are driving, not when they're sitting at home celebrating!
