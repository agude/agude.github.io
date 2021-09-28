---
layout: post
title: "SWITRS: Differences in Vehicle Collision Rates by Manufacturer During COVID-19"
description: >
  California was put under a stay-at-home order in March, 2020. Toyota drivers
  stayed home, Ford drivers did not; why?!
image: /files/switrs-covid/mail_truck_tries_to_climb_tree_in_boston_1927.jpg
hide_lead_image: True
image_alt: >
  A black and white photo from 1927 of an old USPS truck crashed into a tree at the side
  of the road.
categories: 
  - california-traffic-data 
  - data-science
---

{% capture file_dir %}/files/switrs-covid{% endcapture %}

As I prepared to write my post on the [increase in traffic fatalities during
COVID-19][last_post], I made some exploratory plots. One plot made me stop and
stare. Here it is:

[last_post]: {% post_url 2021-07-19-switrs_covid_19_lockdown_fatal_traffic_collisions %}

[![The number of traffic collisions involving Fords compared to those
involving Toyotas before and after the COVID-19 stay at home order in
California][f_vs_t]][f_vs_t]

[f_vs_t]: {{ file_dir }}/covid_pandemic_ford_vs_toyota_collisions.svg

This plot isn't perfect---I will fix it below---but even so it is striking.
Before the [stay-at-home order][order] the number of collisions involving
[Toyotas][toyota] was much higher than those involving [Fords][ford]. After
the order, the trend flips. Fords have more collisions. I had to figure out
why.

[order]: https://en.wikipedia.org/wiki/California_government_response_to_the_COVID-19_pandemic
[toyota]: https://en.wikipedia.org/wiki/Toyota
[ford]: https://en.wikipedia.org/wiki/Ford_Motor_Company

The code for this analysis can be found [here][notebook] ([rendered on
Github][rendered]). The data is available on [Kaggle][db_link] or
[Zenodo][zen_link]. There is a [hosted Kaggle Notebook][kn] version of this
post as well to help you dive right in.

{% capture notebook_uri %}{{ "SWITRS Ford vs Toyota During Lockdown.ipynb" | uri_escape }}{% endcapture %} 
[notebook]: {{ file_dir }}/{{ notebook_uri }}
[rendered]: https://github.com/agude/agude.github.io/blob/master{{ file_dir }}/{{ notebook_uri }}

[db_link]: https://www.kaggle.com/alexgude/california-traffic-collision-data-from-switrs
[zen_link]: https://zenodo.org/record/4284843
[kn]: https://www.kaggle.com/alexgude/switrs-vehicle-collision-rates-difference-by-make/

## Data

I select all collisions between 2019 and November 30, 2020 that involve a
Toyota or a Ford, with this query:

```sql
SELECT c.collision_date
    , p.vehicle_make
    , count(1) as total
FROM collisions AS c
LEFT JOIN parties as p
ON p.case_id = c.case_id
WHERE c.collision_date IS NOT NULL 
AND c.collision_date BETWEEN '2019-01-01' AND '2020-11-30'
AND p.vehicle_make IN ('ford', 'toyota')
GROUP BY 1, 2;
```

I start the data in 2019 because I need a sample from _before_ the pandemic
changed behavior, but I didn't want to go too far back because [collision
rates vary drastically year-to-year][collision_rates]. I cut off the data in
November because the reporting is not yet complete for December.

[collision_rates]: {% post_url 2016-12-02-switrs_crashes_by_date %}/#crashes-per-week

## Normalized Collision Rate

The number of collisions depends on many factors, primary among them is
[vehicle miles traveled][vmt].[^mn_pub_safety] To help control for VMT, I
normalize the mean number of collisions for each make of vehicle from January
through June of 2019. This gives me a baseline to compare against. Here is the
normalized plot:

[vmt]: https://en.wikipedia.org/wiki/Units_of_transportation_measurement#Fatalities_by_VMT
[^mn_pub_safety]: 

    From the Minnesota Department of Public Safety:

    > Volume of traffic, or vehicle miles traveled (VMT), is a predictor of
    > crash incidence. All other things being equal, as VMT increases, so will
    > traffic crashes. The relationship may not be simple, however; after a
    > point, increasing congestion leads to reduced speeds, changing the
    > proportion of crashes that occur at different severity levels.

    Minnesota Department of Public Safety, Office of Traffic Safety (2014).
    [_Minnesota Traffic Crashes in 2014_][mn_report], Page 2

[mn_report]: https://dps.mn.gov/divisions/ots/reports-statistics/Documents/2014-crash-facts.pdf

[![The collision rate for Fords compared to Toyotas before and after the COVID-19 stay at home order in
California, with mean normalized from January 2019 through June 2019.][f_vs_t_norm]][f_vs_t_norm]

[f_vs_t_norm]: {{ file_dir }}/covid_pandemic_normalized_ford_vs_toyota_collisions.svg

## Interpretation

The normalized rates match up well through the [Christmas and New Year
holidays][xmas], which is the two-week dip caused by people taking time off
work and hence not commuting. But right after, the series diverge:

[xmas]: {% post_url 2016-12-02-switrs_crashes_by_date %}/#day-by-day

- Toyota collisions trend down a few weeks before the stay-at-home
  order and drop off significantly the week before. Ford collisions stay
  constant until the order. This suggests that Toyota drivers made a decision
  to stay home by themselves while Ford drivers waited until the state
  mandated it.
- Toyota collisions drop much more the week of the order, likely indicating
  that more Toyota drivers stayed at home when told to do so.
- Ford collisions recovered towards their pre-pandemic level faster than
  Toyota collisions, indicating that Ford drivers were quicker to get back on
  the road when allowed to.

Taken together, I think these observations suggest the difference is due to a
[white-collar][white_collar]--[blue-collar][blue_collar] divide. White-collar
workers generally have more flexible work arrangements and their jobs are
easier to do from home, whereas blue-collar workers have to travel to a job
site to perform their work. Blue-collar workers are more conservative than
white-collar workers and more likely to buy American branded cars like
Fords.[^political_cars]

[white_collar]: https://en.wikipedia.org/wiki/White-collar_worker
[blue_collar]: https://en.wikipedia.org/wiki/Blue-collar_worker

[^political_cars]: 

    The type of car and brand both are driven by political leaning:

    > The most left-leaning models with at least a dozen sightings in Mr.
    > MacMichael's project were the Honda Civic (80-20 left-leaning), Toyota
    > Corolla (78-19) and Toyota Camry (74-26). The list of most right-leaning
    > was led by another Toyota, but a midsize SUV, the Toyota 4Runner
    > (86-14), followed by the Ford Expedition (76-24) and Ford F-150 (75-25).

    Tierney, John. (April 1, 2005). [_Your Car: Politics on Wheels_][nyt_car],
    The New York Times.

[nyt_car]: https://www.nytimes.com/2005/04/01/automobiles/your-car-politics-on-wheels.html

Initially I thought this difference would be driven purely by the prevalence
of Ford trucks, but as we shall see it is not just trucks versus cars.

### Trucks

Is it just that there are more Ford trucks? No.

[![The collision rate for Ford trucks compared to Toyota trucks before and
after the COVID-19 stay at home order in California, with mean normalized from
January 2019 through June 2019.][f_vs_t_norm_truck]][f_vs_t_norm_truck]

[f_vs_t_norm_truck]: {{ file_dir }}/covid_pandemic_normalized_ford_vs_toyota_collisions_trucks.svg

The same pattern holds, although both makes recover faster, with Fords
returning to pre-pandemic levels and Toyota getting to 80%, which is much
higher than the 50% Toyota reached when including non-trucks.

### Location

Perhaps Ford owners just live in areas with looser restrictions, like the
Central Valley? No. Here is data from Contra Costa County, part of the Bay
Area:

[![The collision rate for Fords compared to Toyotas in Contra Costa County
before and after the COVID-19 stay at home order in California, with mean
normalized from January 2019 through June
2019.][f_vs_t_norm_cc]][f_vs_t_norm_cc]

[f_vs_t_norm_cc]: {{ file_dir }}/covid_pandemic_normalized_ford_vs_toyota_collisions_contra_costa.svg

It is the same pattern, but with a lot more noise due to the smaller
population.

### Age

Young drivers get in more accidents. Perhaps there is a strong age difference
driving the trend? There is an age difference, see:

[![Area normalized distribution of Toyota and Ford driver ages during the
COVID-19 stay at home order in California.][age_dist]][age_dist]

[age_dist]: {{ file_dir }}/covid_pandemic_ford_vs_toyota_collisions_age_distribution.svg

But that alone doesn't account for the pattern:

[![The collision rate for Fords compared to Toyotas for drivers aged 30 to 50 
before and after the COVID-19 stay at home order in California, with mean
normalized from January 2019 through June
2019.][f_vs_t_norm_age]][f_vs_t_norm_age]

[f_vs_t_norm_age]: {{ file_dir }}/covid_pandemic_normalized_ford_vs_toyota_collisions_age_30_to_50.svg

### Putting It All Together

A person's identity is made up of many traits: their age, their politics,
where they live, what job they do, and yes, what car they drive. I looked at
three different traits---vehicle type, location, and age---and none of them
explain the entirety of the collision rate difference between Toyotas and
Fords after the COVID-19 stay-at-home order. My conclusion is that Ford
drivers are just different from Toyota drivers, in multiple ways, each of
which contributes to the trend.
