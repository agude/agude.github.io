---
layout: post
title: "SWITRS: On What Days Do People Crash?"
description: >
  What day of the year has the most car crashes? The fewest? Find out as I
  look at California's crash data! Hint: they're both holidays!
image: /files/switrs-accidents-by-date/1923_dc_car_crash.jpg
show_lead_image: True
image_alt: >
  A black and white photo of about a dozen men and boys standing around a
  broken car taken in Washington D.C. in 1923. One of the car's wheels has
  splintered and the car is tilted over.
categories: 
  - california-traffic-data 
  - data-science
seo:
  date_modified: 2018-09-24T21:19:35-0700
---

{% capture file_dir %}/files/switrs-accidents-by-date{% endcapture %}

The [Statewide Integrated Traffic Records System (SWITRS)][switrs] contains a
wealth of information, enough to determine who, where, when, and sometimes why
and how for every traffic collision in California. Today, with the assistance
of my [SWITRS-to-SQLite script][s2s] ([discussed previously][lastpost]), I'm
going to look at when car crashes happen, and specifically on what dates.

[switrs]: http://iswitrs.chp.ca.gov/Reports/jsp/userLogin.jsp
[s2s]: https://github.com/agude/SWITRS-to-SQLite
[lastpost]: {% post_url 2016-11-01-switrs_to_sqlite %}

As always, the Jupyter notebook used to do this analysis can be found
[here][notebook] ([rendered on Github][rendered]).

{% capture notebook_uri %}{{ "SWITRS Crash Dates.ipynb" | uri_escape }}{% endcapture %}

[notebook]: {{ file_dir }}/{{ notebook_uri }}
[rendered]: https://github.com/agude/agude.github.io/blob/master{{ file_dir }}/{{ notebook_uri }}

## Data Selection

The data was selected using the following query:

```sql
SELECT Collision_Date FROM Collision
WHERE Collision_Date IS NOT NULL
AND Collision_Date <= '2015-12-31'  -- 2016 is incomplete
-- We only want car crashes
AND Bicycle_Collision IS NOT 1
AND Motorcycle_Collision IS NOT 1
AND Pedestrian_Collision IS NOT 1
AND Truck_Collision IS NOT 1

```

This selects every car crash that happened before 2016 that has a collision
date stored. The current year, 2016, is excluded because the data from it is
incomplete.

## Crashes per Week

The first thing to look at is crashes as a function of time. Below, I plot
crashes per week to make the trends clearer; plotting per day results in too
many points to separate by eye.

[![Line plot showing crashes per week from 2001 to
2015][per_week_plot]][per_week_plot]

[per_week_plot]: {{ file_dir }}/accidents_per_week_in_california.svg

The week-to-week variation is rather significant, but two major trends are
obvious:

1. The total number of crashes has been decreasing over the past few years,
   with a big drop in 2008, but is now rising sharply in 2015.
2. Each year is similar, with a mid-year lull and wildly varying
   increases and decrease right before the end of the year.

The first trend is easy to explain: the [Great Recession][gr] put many people
out of work, who then stopped commuting. The second trend is also due to
reduced driving; we'll look at it in detail below.

[gr]: https://en.wikipedia.org/wiki/Great_Recession

## Day-by-Day

To explore the second trend, we'll need to look at the data day-by-day instead
of a week at a time. Below is a plot of the average number of crashes on
each day of the year. The average is calculated by summing the number of
crashes on a specific day (say, September 22nd) across the years 2001 to
2015\. The sum is then divided by the number of times that specific day
appeared in the timespan (15, except for the [leap day][leapday], which only
appears 3 times).

[leapday]: https://en.wikipedia.org/wiki/February_29

[![Line plot showing average crashes by day of the
year][average_accidents]][average_accidents]

[average_accidents]: {{ file_dir }}/mean_accidents_by_date.svg

Holidays account for the extrema, with the minimum number of crashes taking
place on Christmas, and the maximum number taking place on Halloween. In fact,
many of the local maxima and minima are also holidays! Some create obvious,
multi-day patterns (like Thanksgiving) because they are floating holidays
while others (like Christmas and Halloween) create massive, single-day dips or
spikes because they happen on the same day every year. Holidays that fewer
people get off from work, like Washington's Birthday and Columbus Day, show
almost no deviation from the surrounding dates.

But perhaps the most interesting dates are the holidays where the number of
crashes **increases**! Halloween is the most obvious of these, and sets the
record for the **highest number of crashes**, but Valentine's Day and St.
Patrick's Day also show increases. I believe there are two reasons these
holidays have higher than normal crash counts. First, these are not
generally paid holidays, so the normal number of commute-related crashes
happen. Second, these are holidays are celebrated away from home after work
(for drinks, dates, or candy), and so people drive more on these days than
they would otherwise. I suspect that there is a third reason behind
Halloween's high crash count: a higher than average number of pedestrians
being out and about leading to a higher than average number of collisions
involving pedestrians. I plan to look at pedestrian incidents in a later blog
post.

## Day of the Week

Finally, let's look at crashes by day of the week. On weekends, like holidays,
we would expect most people to not go to work. Below is a [violin
plot][violin] of crashes by day of the week. The width of each "violin"
indicates the number of days with that value while the center line indicates
the median, and the two outer lines indicate the interquartile.

[violin]: https://en.wikipedia.org/wiki/Violin_plot

[![Violin plot showing crashes by day of the
week][accident_violin_plot]][accident_violin_plot]

[accident_violin_plot]: {{ file_dir }}/accidents_by_day_of_the_week.svg

The distribution for each day of the week is bimodal. This is due to the [two
plateaus in crash rates][apw]: a high one from 2001--2006, and a lower one
from 2011--2014. The first four weekdays have roughly the same number of
crashes. Friday has more, presumably because people are more likely to go out
after work. Saturday drops to a level slightly below the weekdays, though not
by much, and Sunday has the lowest crash count.

[apw]: #crashes-per-week

In the end the results are not too surprising: car crashes happen when people
are driving, not when they're sitting at home celebrating!

---

**Updated <time datetime="{{ page.seo.date_modified | date_to_xmlschema }}">{{
page.seo.date_modified | date: '%B %d, %Y' }}</time>**: _Replaced the
[univariate dot plot][dot_plot] in the [Day of the Week][dow] section with a
[violin plot][violin_plot]; see this [git diff][changes_1]. Also removed
Trucks, [Motorcycles][mc_switrs], Bicycles, and pedestrians from the data set;
see this [git diff][changes_2]. This removed about 10% of the crashes, but did
not qualitatively change the results. These results will be covered in their
own posts._

[dot_plot]: {{ file_dir }}/accidents_by_day_of_the_week_dot.svg
[violin_plot]: {{ file_dir }}/accidents_by_day_of_the_week.svg

[dow]: #day-of-the-week
[mc_switrs]: {% post_url 2017-02-21-switrs_motorcycle_crashes_by_date %}

[changes_1]: https://github.com/agude/agude.github.io/commit/d03b7b23535fcc80155fdd50fa2838a739484659#diff-773b58bce0ad600cf854e41c88b640cc
[changes_2]: https://github.com/agude/agude.github.io/commit/677643568d459cb58684416759e4dc86d7110476#diff-773b58bce0ad600cf854e41c88b640cc
