---
layout: post
title: "SWITRS: Halloweed Pedestrians Safety"
description: >
image: /files/switrs-covid/mail_truck_tries_to_climb_tree_in_boston_1927.jpg
hide_lead_image: True
image_alt: >
categories: 
  - california-traffic-data 
  - data-science
---

{% capture file_dir %}/files/switrs-pedestrian-halloween{% endcapture %}

Last time I wrote about [when pedestrians are hit by cars][last_post]. I
discovered that [Halloween is the day with _the most_ pedestrian
incidents][last_post_dbd], and that [the commute hours][last_post_hbh] are
when most pedestrians are hit. Now I'll dive a little deeper into those
patterns using the same [SWITRS data][switrs].

[last_post]: {% post_url 2022-11-10-switrs_pedestrian_incidents_by_date %}
[last_post_dbd]: {% post_url 2022-11-10-switrs_pedestrian_incidents_by_date %}#day-by-day
[last_post_hbh]: {% post_url 2022-11-10-switrs_pedestrian_incidents_by_date %}#hour-by-hour
[switrs]: {% post_url 2020-11-24-switrs_sqlite_hosted_dataset %}

As per usual, the Jupyter notebook used to perform this analysis can be found
[here][notebook] ([rendered on Github][rendered]).

{% capture notebook_uri %}{{ "SWITRS Incident Dates With Pedestrians.ipynb" | uri_escape }}{% endcapture %} 

[notebook]: {{ file_dir }}/{{ notebook_uri }}
[rendered]: https://github.com/agude/agude.github.io/blob/master{{ file_dir }}/{{ notebook_uri }}

## Data Selection 

I selected crashes involving pedestrians from the [SQLite database][s2s] with
the following query:

[s2s]: https://github.com/agude/SWITRS-to-SQLite

```sql
SELECT collision_date,
       collision_time,
       pedestrian_killed_count
FROM collisions
WHERE Collision_Date IS NOT NULL
AND pedestrian_Collision = 1        -- Involves a pedestrian
AND collision_date <= '2020-12-31'  -- 2021 is incomplete
-- and it happens on Haloween
AND strftime('%m-%d', Collision_Date) = '10-31'
```

This gave me 1168 data points, of which 64 involve a pedestrian fatality,
spanning the years 2001 through 2020\. Incidents after 2020 are rejected
because the database dump comes from mid-2021, and so that year is incomplete.

## Incidents Per Hour

[Alissa Walker][aw_curbed] wrote[^aw_quote] that it is not just drivers that make
Halloween deadly, it is commuters. The best way to explore this point is to
look at when in the day crashes happen:

[aw_curbed]: https://archive.curbed.com/2019/10/25/20927701/halloween-safety-pedestrian-deaths-kids

[^aw_quote]:
    > But when the commuting drivers are removed from the equation, deaths
    > seem to go down. A study by AutoInsurance.org used FARS data to compare
    > 24 years of crash data by days of the week. Halloweens that fell on
    > workdays had an 83 percent increase in deadly crashes involving kids
    > compared to weekend days. The worst day? Friday. Since 1994, the three
    > deadliest Halloween nights for kids have all been Friday nights.

    From: Walker, Alissa (October 25, 2019). [_The most terrifying part of
    Halloween for kids is our deadly streets_][aw_curbed]. _Curbed_ Vox Media.

[![Average number of incidents involving pedestrians per hour on Halloween
from 2001 to 2020, separated by weekend and
weekdays.][by_hour_plot]][by_hour_plot]

[by_hour_plot]: {{ file_dir }}/pedestrian_incidents_by_hour_on_halloween.svg

Just like we saw in the "all days" data, weekdays [have two large commute
peaks and a school pickup peak][last_post_hbh]. There is a large increase in
the number of collisions around 18:00 on both days which is likely due to a
combination of darkness making it hard for drivers to see pedestrians and
trick-or-treating bring more people out walking. This data supports Walker's
observation that commute traffic causes a large increase in pedestrian
incidents.

## Fatality Rates

But Walker actually makes a very specific claim: that fatalities involving
children increase on Halloween. So does it? We need to look at the fatality
rate instead of just counts because the number of people driving and walking
changes year-by-year and using the rate helps to normalize some of this out.
Here is a plot of the fatality rates for each year's Halloween, separated into
weekday and weekend:

[![Fatality rate for pedestrians per year on Halloween separated by weekday vs
weekend.][fatality_plot]][fatality_plot]

[fatality_plot]: {{ file_dir }}/pedestrian_fatality_rate_by_day_type_on_halloween.svg

This is all pedestrians, not just children. By eye, the distributions look
pretty similar. A [Mann--Whitney U test][mwut] confirms with a _p_-value of
0.93; not significantly different.

But what about children (pedestrians under 18)? Here is that data:

[mwut]: https://en.wikipedia.org/wiki/Mann%E2%80%93Whitney_U_test

[![Fatality rate for child pedestrians per year on Halloween separated by
weekday vs weekend.][child_fatality_plot]][child_fatality_plot]

[child_fatality_plot]: {{ file_dir }}/children_pedestrian_fatality_rate_by_day_type_on_halloween.svg

Notice the number of children killed by cars on weekend Halloweens is 0!
Whereas during weekday about half of the Halloweens have a child death. But
are these distributions different? Still not significantly so, with a
_p_-value of 0.08, but the lower _p_-value does indicate that there is more
evidence for the specific claim about child deaths than for all pedestrians.
