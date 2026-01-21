---
layout: post
title: "SWITRS: Pedestrian Safety on Halloween"
description: >
  Halloween can be a dangerous time for pedestrians. In this post, I explore
  the statistics on pedestrian-vehicle collisions, including when these
  incidents are most likely to occur.
image: /files/switrs-pedestrian-halloween/auto_accident_loc_2016819574_1920.jpg
hide_lead_image: False
image_alt: >
  Black and white photo from around 1920 of men in suits with hats crowded
  around a car that has driven over a curb and lost its front left wheel.
categories: 
  - california-traffic-data 
  - data-science
---

{% capture file_dir %}/files/switrs-pedestrian-halloween{% endcapture %}

In my last post, I found that Halloween is the [most dangerous day of the year
for pedestrians][last_post], with a higher number of incidents than any other
day, according to [data from SWITRS][switrs]. I also found that the risk of
pedestrian incidents is higher during commute hours, regardless of the date.
In this article, I will explore these patterns in more detail using the same
SWITRS data, but with a focus on Halloween.

[last_post]: {% post_url 2022-11-10-switrs_pedestrian_incidents_by_date %}
[switrs]: {% post_url 2020-11-24-switrs_sqlite_hosted_dataset %}

As per usual, the Jupyter notebook used to perform this analysis can be found
[here][notebook] ([rendered on Github][rendered]).

{% capture notebook_uri %}{{ "SWITRS Incident Dates With Pedestrians On Halloween.ipynb" | uri_escape }}{% endcapture %} 

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
-- and it happens on Halloween
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

    {% citation
      author_last="Walker"
      author_first="Alissa"
      work_title="The most terrifying part of Halloween for kids is our deadly streets"
      container_title="Curbed"
      publisher="Vox Media"
      date="October 25, 2019"
      url="https://archive.curbed.com/2019/10/25/20927701/halloween-safety-pedestrian-deaths-kids"
    %}

[![Average number of incidents involving pedestrians per hour on Halloween
from 2001 to 2020, separated by weekend and
weekdays.][by_hour_plot]][by_hour_plot]

[by_hour_plot]: {{ file_dir }}/pedestrian_incidents_by_hour_on_halloween.svg

As we saw in the data for all dates, weekdays [have two major peaks in
collisions during the morning and evening commutes, as well as a peak during
school pickup times][last_post_hbh]. Examining the data for Halloween
specifically, we see that when it falls on a weekday the three expected peaks
(morning and evening commutes, and school pick-up) are present, but there is
also a fourth peak at 18:00, likely due to a combination of darkness making it
difficult for drivers to see pedestrians and trick-or-treating bringing more
people out walking. This data supports Walker's observation that commuter
traffic contributes significantly to the number of pedestrian incidents.

[last_post_hbh]: {% post_url 2022-11-10-switrs_pedestrian_incidents_by_date %}#hour-by-hour

## Fatality Rates

But Walker makes a very specific claim: that fatalities involving children
increase on weekday Halloweens. Does the data support this claim? To find out,
we need to look at the fatality rate instead of the total number of fatalities
because the number of people driving and walking changes year-by-year and
using the rate helps to normalize some of this variation. Below is a plot of
the fatality rates for each year's Halloween, separated into weekday and
weekend:

[![Fatality rate for pedestrians per year on Halloween separated by weekday vs
weekend.][fatality_plot]][fatality_plot]

[fatality_plot]: {{ file_dir }}/pedestrian_fatality_rate_by_day_type_on_halloween.svg

The data above includes all pedestrian fatalities, not just those involving
children. At first glance, the distributions for weekday and weekend Halloween
fatalities appear similar. A [Mann--Whitney U test][mwut] confirms this, with
a _p_-value of 0.93, indicating that the difference between the two is not
statistically significant.

But what about children alone (defined as pedestrians under 18)? Here is that
data:

[mwut]: https://en.wikipedia.org/wiki/Mann%E2%80%93Whitney_U_test

[![Fatality rate for child pedestrians per year on Halloween separated by
weekday vs weekend.][child_fatality_plot]][child_fatality_plot]

[child_fatality_plot]: {{ file_dir }}/children_pedestrian_fatality_rate_by_day_type_on_halloween.svg

One interesting observation is that no children have been killed by cars on
weekend Halloweens, whereas about half of the weekdays have seen at least one
child death. This suggests that there is something about weekday Halloweens
that makes them particularly dangerous for children, consistent with Walker's
claim.

Despite this, the data does not show a significant difference between the two
distributions, with a _p_-value of 0.08. However, this lower _p_-value as
compared to the all-ages data does indicate some evidence for the specific
claim about child deaths. 
