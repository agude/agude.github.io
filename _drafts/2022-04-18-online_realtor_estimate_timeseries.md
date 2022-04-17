---
layout: post
title: "Comparing Pre- and Post-sale Estimates of the Price of a House"
description: >
  Can Zillow and Redfin predict prices accurately? I look at a house sold in
  my neighborhood and compare the sale price to the price predicted by Zillow
  and Redfin before they knew it was for sale.
image: /files/online-realtor-estimate-comparison/1935_house_plans.jpg
image_alt: >
  A line drawing of a two bedroom home done for a 1935 architecture
  competition.
categories:
  - data-science
  - data-visualization
---

{% capture file_dir %}/files/online-realtor-estimate-comparison/{% endcapture %}


[previous_post]: {% post_url 2022-02-07-online_realtor_estimate_comparison %}

I [wrote about the pre- and post-sale estimates][previous_post] of a house's
sale price from four online brokers a little while ago. Zillow, Redfin, and
Realtor.com where pretty badly off, whereas Xome did pretty well. The biggest
limitation of my experiment was that I only collected data for one house, but
another limitation was that I only collected that data at one point in time
for the house. I wrote down one value for each broker before the listing, one
value for each after the list, and a final value after the sale.

You can find the Jupyter notebook used to perform this analysis
[here][notebook] ([rendered on Github][rendered]). The data can be found
[here][data].

{% capture notebook_uri %}{{ "House Price Estimate Timeseries Plot.ipynb" | uri_escape }}{% endcapture %}

[notebook]: {{ file_dir }}/{{ notebook_uri }}
[rendered]: https://github.com/agude/agude.github.io/blob/master{{ file_dir }}/{{ notebook_uri }}
[data]: {{ file_dir }}/home_price_estimate_timeseries_data.csv

## Data Collection

I recorded the estimated sales price everyday from Zillow and Redfin. I
excluded Realtor.com and Xome because they do not update their estimate
frequently (they seem to only update when the status of the house changes from
pre-listing to listing to pending to sold). I occasionally missed a day of
data because I was collecting it manually.[^script]

[^script]: I automated the data collection with a Python script. It worked
    when I ran it manually and then silently failed when run via cron. It took
    me a few weeks to debug by which time the experiment was already over. I
    never actually figured out what was wrong, I just finally wrapped it in a
    shell script and that worked immediately. 🤷

## Plot

Here a plot comparing the estimates for the sales price from Zillow and Redfin
in time:

[![A comparison of four different real estate brokers estimate for the sales
price of a single house in my neighborhood before and after it was listed and
sold.][my_plot]][my_plot]

[my_plot]: {{ file_dir }}/home_price_estimate_timeseries_comparison.svg

The daily price estimates from Redfin are shown using red circles, the
estimates for Zillow are shown using blue triangles.

### Comments

Redfin's initial estimate, before the home was listed, was $1,189k. Zillow's
initial estimated was $883k. The final sale price was $1,275k. Redfin reverted
to just above the list price when the house was listed for sale. I missed
Zillow's price on that date but based on my [last post on the
subject][previous_post] they almost certainly did the same.

Redfin's estimate had increased by about $150k over the list price by the time
the house went pending. I suspect their model takes into account the
popularity of the listing on the site, and based on how popular the property
was in real life I suspect it must have been garnering a lot of attention
online as well.

Zillow also increased it's estimate after the house went pending, but not as
much.
