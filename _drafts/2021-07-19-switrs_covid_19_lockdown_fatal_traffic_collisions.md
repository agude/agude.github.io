---
layout: post
title: "SWITRS: Increase In Traffic Fatalities After COVID-19 Lock Down"
description: >
  California was put under a stay-at-home order in March, 2020. As expected,
  traffic volume decreased, but what happened to rate of fatal accidents? They
  skyrocketed!
image: /files/switrs-covid/auto_accident_on_bloor_street_west_in_1918.jpg
image_alt: >
  A black and white photo of an old car slid up against the curb, its front
  wheels completely buckled. A crowed stands on the sidewalk looking on.
categories: 
  - california-traffic-data 
  - data-science
---

{% capture file_dir %}/files/switrs-covid{% endcapture %}

California had its [first case of COVID-19][covid] on January 26, 2020. The
Governor mandated a [state-wide stay-at-home order][order] on March 19, 2020.
The morning and evening commutes stopped immediately. Traffic volume decreased
by more than 50% and stayed low for weeks. Slowly the restrictions were
relaxed and traffic returned, but has still not reached pre-pandemic levels.

[covid]: https://en.wikipedia.org/wiki/COVID-19_pandemic_in_California
[order]: https://en.wikipedia.org/wiki/California_government_response_to_the_COVID-19_pandemic

The number of traffic collisions **decreased** as you would expect with the
decreased volume but, surprisingly, the severity of the collisions
**increased**. The [rate of fatal accidents increased across the
country][fatal]. The National Highway Traffic Safety Administration attributes
the increase to a change in behavior by drivers who stayed on the road: they
drove more recklessly and wore their seatbelt less often.[^nhtsa]

[fatal]: https://www.nhtsa.gov/press-releases/2020-fatality-data-show-increased-traffic-fatalities-during-pandemic

[^nhtsa]: Specifically: 
    > NHTSA's research suggests that throughout the national public health
    > emergency and associated lockdowns, driving patterns and behaviors
    > changed significantly, and that drivers who remained on the roads
    > engaged in more risky behavior, including speeding, failing to wear seat
    > belts, and driving under the influence of drugs or alcohol. Traffic data
    > indicates that average speeds increased throughout the year, and
    > examples of extreme speeds became more common, while the evidence also
    > shows that fewer people involved in crashes used their seat belts.

    National Highway Traffic Safety Administration. (June 3rd, 2021). [_2020
    Fatality Data Show Increased Traffic Fatalities During Pandemic_][fatal]. 

I can't test that hypothesis with my [SWITRS data][hosted_dataset_post]---it
does not include much information about driving behavior, only about
collisions---but I can look at the fatality rate on California roads.

The code for this analysis can be found [here][notebook] ([rendered on
Github][rendered]). The data is available on [Kaggle][db_link] or
[Zenodo][zen_link].

{% capture notebook_uri %}{{ "SWITRS Fatalities During COVID Lockdown.ipynb" | uri_escape }}{% endcapture %} 
[notebook]: {{ file_dir }}/{{ notebook_uri }}
[rendered]: https://github.com/agude/agude.github.io/blob/master{{ file_dir }}/{{ notebook_uri }}

[hosted_dataset_post]: {% post_url 2020-11-24-switrs_sqlite_hosted_dataset %}
[db_link]: https://www.kaggle.com/alexgude/california-traffic-collision-data-from-switrs
[zen_link]: https://zenodo.org/record/4284843

## Data

I selected all collisions in the dataset between the start of 2019 and
November 30th, 2020, including whether their was a fatality as a result of the
collision, with this query:

```sql
SELECT collision_date
    , 1 AS crashes
    , IIF(collision_severity='fatal', 1, 0) AS fatalities
FROM collisions 
WHERE collision_date IS NOT NULL 
AND collision_date BETWEEN '2019-01-01' AND '2020-11-30'
```

I start the data in 2019 because I need a sample from _before_ the pandemic
changed behavior, but I didn't want to go too far back because [collision
rates vary drastically year-to-year][collision_rates]. I cut off the data in
November because the reporting is not yet complete for December.

[collision_rates]: {% post_url 2016-12-02-switrs_crashes_by_date %}/#crashes-per-week

## Fatality Rate

I calculate the weekly fatality rate. It is the number of traffic collisions
that resulted in a fatality divided by the total number of collisions during
the week. Here is what that rate looks like before and after the stay-at-home
order:

[![The traffic fatality rate in California before and after the COVID-19
stay-at-home order.][ts_plot]][ts_plot]

[ts_plot]: {{ file_dir }}/fatality_rate_per_week_in_california_after_covid.svg

You can see the fatality rate **immediately** jumps up to over 1% for the
first time in our dataset, and then goes even higher in the coming weeks. It
stays elevated for the entirety our data range.

Another way to look at this data is to plot of histogram of the rate before
and after the stay-at-home order. Here it is:

[![A histogram showing traffic fatality rate in California before and after
the COVID-19 stay-at-home order.][hist_plot]][hist_plot]

[hist_plot]: {{ file_dir }}/fatality_rate_per_week_in_california_after_covid_histograms.svg

The weeks with the highest fatality rate before the pandemic are between 0.8%
and 1%. These overlap with the _lowest_ fatality rate weeks after the
stay-at-home order. These are clearly different distributions, but we can
quantify that difference with a [Mann--Whitney _U_ test][mwu].

[mwu]: https://en.wikipedia.org/wiki/Mann%E2%80%93Whitney_U_test

The Mann--Whitney test compares the probability that a value randomly drawn
from the first distribution is larger than one randomly drawn from the second
distribution, with a correction for ties. If this probability is not 50% (as
it would be if they were the same) then the distributions must be different.
The test is nonparametric and only assumes that the observations are
independent, that they are orderable, that under the null hypothesis the
distributions are equal, and under the alternative hypothesis the
distributions are different.

The test confirms our eye test with a _p_-value of 3.6e-14. These
distributions are significantly different, meaning that the California
stay-at-home order increased the traffic fatality rate.
