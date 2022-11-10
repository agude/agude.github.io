---
layout: post
title: "SWITRS: On What Days Do Pedestrians Get Hit?"
description: >
image: /files/switrs-covid/mail_truck_tries_to_climb_tree_in_boston_1927.jpg
hide_lead_image: True
image_alt: >
categories: 
  - california-traffic-data 
  - data-science
---

{% capture file_dir %}/files/switrs-pedestrian-incidents-by-date{% endcapture %}

It has been a while since I have used the [SWITRS data][switrs] to look at
vehicle collisions in California. Since my last article---[_On What Days Do
Cyclists Crash?_][last_post]---we have lived through a massive
[pandemic][covid] that **significantly changed** how people drive, including
[a huge increase to fatalities][fatalities_post] and changing [what type of
drivers have crashes][toyota_post].

[switrs]: {% post_url 2020-11-24-switrs_sqlite_hosted_dataset %}
[last_post]: {% post_url 2019-02-20-switrs_bicycle_crashes_by_date %}
[covid]: https://en.wikipedia.org/wiki/COVID-19_pandemic_in_California 
[fatalities_post]: {% post_url 2021-07-19-switrs_covid_19_lockdown_fatal_traffic_collisions %} 
[toyota_post]: {% post_url 2021-09-27-switrs_ford_vs_toyota_during_covid_19 %}

This time I am going to look at the most vulnerable road users: pedestrians.

## Data Selection 

I selected crashes involving pedestrians from the [SQLite database][s2s] with
the following query:

[s2s]: https://github.com/agude/SWITRS-to-SQLite

```sql
SELECT collision_date
     , collision_time 
     , pedestrian_killed_count
FROM collisions 
WHERE collision_date IS NOT NULL 
AND pedestrian_Collision = 1        -- Involves a pedestrian
AND collision_date <= '2020-12-31'  -- 2021 is incomplete
```

This gave me 282,039 data points to examine spanning the years 2001 through
2020\. Incidents after 2020 are rejected because the database dump comes from
mid-2021, and so that year is incomplete.

## Crashes per Week

For bicycle involved incidents, [I found there was an increase from about 2008
through 2013 followed by a decrease][bike_apw]. For both bicycles [as well as
motorcycles][mc_apw], I found strong seasonality with many more crashes during
the summer when people are out riding to take advantage of the weather.
Pedestrian involved incidents defy both these trends:

[bike_apw]: {% post_url 2019-02-20-switrs_bicycle_crashes_by_date %}#crashes-per-week
[mc_apw]: {% post_url 2017-02-21-switrs_motorcycle_crashes_by_date %}#crashes-per-week

[![Step plot showing pedestrian involved incidents per week in California from
2001 through 2020.][per_month_plot]][per_month_plot]

[per_month_plot]: {{ file_dir }}/pedestrian_incidents_per_month_in_california.svg

Pedestrian involved incidents were flat or slightly down until about 2013,
when instead of decreasing like bicycle collisions they **increased
strongly**. Like both bicycles and motorcycle crashes,
pedestrian incidents are strongly seasonal but they decrease in the summer
(when there is a lot of light for cars to see them) and **increase in the
winter** when it gets dark early and cars can't see them.

## Day-by-day

[Cars are involved in crashes][car_dbd] on days when drivers have to commute
to work _and_ on holidays when people travel. The worst day is Halloween when
people work and then go out and have fun after. I wondered when looking at the
car data if the large increase in Halloween was due to a large increase in
pedestrian collisions; the answer is no:

[car_dbd]: {% post_url 2016-12-02-switrs_crashes_by_date %}#day-by-day

[![Step plot showing mean pedestrian involved incidents by date in California
average over 2001 through 2020.][per_date_plot]][per_date_plot]

[per_date_plot]: {{ file_dir }}/mean_pedestrian_incidents_by_date.svg

Halloween has by far the most incidents where pedestrians are hit by drivers.
But its only about 15 to 20 more incidents than on any other October day, and
there are almost 200 additional car crashes on Halloween. A number of
additional pedestrian incidents does not account for much of the increase in
car crashes.

I will look at Halloween related incidents in my next post.
{%comment%}TODO: UPDATE THIS{%endcomment%}

Otherwise there are some interesting patterns. Many holidays trend the same
direction as cars: New Years, Memorial Day, Veterans Day, Thanksgiving, and
Christmas all see a large reduction in both car crashes and pedestrian
incidents. Halloween, as covered above, sees a large increase in both.

One outlier is the 4th of July. Car crashes decrease because people do not
have to commute, but pedestrian incidents increase. I think this is because
people are walking around in the dark going to and coming back from watching
fireworks, and drivers have trouble seeing them.

## Hour-by-hour

Finally we can look at when cars hit pedestrians by hour and whether it is a
weekend or not:

[![Histogram showing the number of pedestrian involved incidents on average
per hour of the day for weekends and weekdays,][per_hour_plot]][per_hour_plot]

[per_hour_plot]: {{ file_dir }}/pedestrian_incidents_by_hour.svg

The most striking feature is the large increase in the number of incidents
during the morning commute (07--09) and again in the during the evening
commute (17--19)! Commuters in cars are dangerous to pedestrians! 

There is also an increase in incidents on both weekends and weekdays at about
17:00. This is probably because that is around sunset.[^sunset]

[^sunset]: 
    This dataset covers the whole year so the exact time of sunset changes. It
    would be interesting to make a similar chart but relative to sunrise and
    sunset.

The weekend curve rises smoothly through the day, but the weekday curve has a
large increase at 14. I suspect this is from school pickup which is generally
earlier than the commute.

Finally, it is interesting that the number of late night and early morning
incidents is much higher on the weekend. This is likely due to people going
out to bars, as the number drops off at 02:00 which is [when the bars close in
California][last_call].

[last_call]: https://en.wikipedia.org/wiki/Last_call
