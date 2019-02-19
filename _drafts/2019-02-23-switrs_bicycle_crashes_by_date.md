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

It is time to use [SWITRS data][switrs] to look at traffic accidents in
California again. I have previously used the data to look [when cars
crash][car_switrs]---during holidays when people both drive to work and to
parties after---and [when motorcycles crash][mc_switrs]---during the summer
when its good riding weather. Today I want to look at something a little
closer to my heart: **bicycle accidents**.

[switrs]: http://iswitrs.chp.ca.gov/Reports/jsp/userLogin.jsp
[car_switrs]: {% post_url 2016-12-02-switrs_crashes_by_date %}
[mc_switrs]: {% post_url 2017-02-21-switrs_motorcycle_crashes_by_date %}

I have been commuting on my bike for years now, and when I was younger I used
to put in thousands of miles a year for fun. So knowing more about when
accidents happen is something I am very interested in.

As per usual, the Jupyter notebook used to perform this analysis can be found
[here][notebook] ([rendered on Github][rendered]).

{% capture notebook_uri %}{{ "SWITRS Crash Dates With Bicycles.ipynb" | uri_escape }}{% endcapture %} 

[notebook]: {{ file_dir }}/{{ notebook_uri }}
[rendered]: https://github.com/agude/agude.github.io/blob/master{{ file_dir }}/{{ notebook_uri }}

## A Simple Model

Before we dig into the data, I have a simple model for how many bicycle
accidents there are. It is:

$$ N_{accidents} = P_{\textrm{car-bike}} L_{miles\textrm{ }biked} \rho_{car\textrm{ }density} $$

That is, the number of accidents involving bicycles ($$N$$) is the probability of an
accident happening when a bike encounters a car ($$P$$) times the number of cars
encountered ($$L\rho$$). The number of accidents goes up when more cars or more bikes are on the road,
but it can also go up if the probability changes, for example, from having
more distracted drivers.

This ignores some accidents, like solo accidents and those that do not involve
a car, but these are rarer in the dataset.[^1]

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

For car crashes, [I found that there was a large dip in 2008][car_apw] as
people stopped driving to work during the [Great Recession][gr]. For
motorcycle crashes, [I found strong seasonality][mc_apw] as people hung up
their helmets during the winter. For bicycles, we have the following pattern:

[car_apw]: {% post_url 2016-12-02-switrs_crashes_by_date %}#accidents-per-week
[mc_apw]: {% post_url 2017-02-21-switrs_motorcycle_crashes_by_date %}#accidents-per-week
[gr]: https://en.wikipedia.org/wiki/Great_Recession

[![Line plot showing bicycles accidents per week from 2001 through
2017][per_week_plot]][per_week_plot]

[per_week_plot]: {{ file_dir }}/bicycle_accidents_per_week_in_california.svg

It shows features similar to both cars and motorcycles:

- The number of accidents increases after 2008, and then begins decreasing
after 2013, almost exactly the **opposite** of the car pattern.
- Accidents are highly seasonal, just like motorcycles. Apparently neither
cyclists nor bikers like riding in the rain.

To me, this suggests that the number of cars on the road is not the dominant
factor in the number of bicycle accidents (which mostly involve collisions
with cars).

## Day-by-Day

Car drivers are involved in accidents [on holidays where they also
work][car_dbd], like St. Patrick's Day. Motorcycles are in accidents during
summer holidays. Bicycles, on the other hand, have no holidays with a large
excess in the number of accidents. Some holidays, like Christmas and
Thanksgiving, keep people from getting on their bikes, but none seem to
motivate to get on the road.

[car_dbd]: {% post_url 2016-12-02-switrs_crashes_by_date %}#day-by-day
[mc_dbd]: {% post_url 2017-02-21-switrs_motorcycle_crashes_by_date %}#day-by-day

[![Line plot showing average motorcycle accidents by day of the
year][average_accidents]][average_accidents]

[average_accidents]: {{ file_dir }}/mean_bicycle_accidents_by_date.svg

New Year's Day, St. Patrick's Day, and the 4th of July are all higher than
they would be if they were not holidays, although you can't tell from this
plot. On those days, people tend to go out and celebrate with alcohol, which
leads to solo crashes. I will examine that in a future post.

## Day of the Week

For cars, [weekends show a decrease in the number of accidents][car_dotw] as people stop
commuting. For motorcycles, [weekends show an increase in the number of
accidents][mc_dotw] as people use their time off to ride. As a recreational
cyclist, I expected accidents to increase on the weekend as people put on
their Lycra and took to the back roads for fun. But this is not the case:

[car_dotw]: {% post_url 2016-12-02-switrs_crashes_by_date %}#day-of-the-week
[mc_dotw]: {% post_url 2017-02-21-switrs_motorcycle_crashes_by_date %}#day-of-the-week

[![Violin plot showing the number of bicycle accidents by day of the
week][accident_violin_plot]][accident_violin_plot]

[accident_violin_plot]: {{ file_dir }}/bicycle_accidents_by_day_of_the_week.svg

These [violin plots][violin] show the distribution of accidents by day of the
week over the 17 year period. There is a large drop in the number of accidents
on weekends, indicating a decrease in the number of riders. This is surprising
to me, I did not realize bikes where so popular for commuting and weekday
errands.

[violin]: https://en.wikipedia.org/wiki/Violin_plot

## Conclusion

---

[^1]: SWITRS reports are filled out when the police or CHP are called to the scene. As such, they skew towards worse accidents. Of the recorded accidents, **TODO**: Fill in number.
