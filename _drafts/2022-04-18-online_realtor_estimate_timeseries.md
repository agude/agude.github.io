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



I [wrote about the pre- and post-sale estimates][previous_post] of a house's
sale price from four online brokers a little while ago. One limitation of that
experiment was that I only collected the data at one point in time for the
house. I wrote down one value for each broker before the listing, one value
for each after the list, and a final value after the sale.

[previous_post]: {% post_url 2022-02-07-online_realtor_estimate_comparison %}

But what if the estimates change day-to-day? [Christopher Moody][chris] posted
[this on Twitter][twitter]:

[chris]: https://twitter.com/chrisemoody
[twitter]: https://twitter.com/chrisemoody/status/1493686691378315264

> I suspect that their algos factor in impressions. I bet there's a
> fascinating time series in between pre- and post-listing price estimates

So I decided to look.

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
data because I was collecting it manually.

Unfortunately the idea to collect the time series came after the house was
already pending, so I missed some of the most interesting changes. I have set
up a script to scrape listings for a few other houses and should have a better
time series for another article.

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

There is _a lot_ of movement in the estimates. Redfin and Zillow start of far
apart. Redfin reverts strongly to the list price once the house if official on
the market (I missed Zillow's price on the day of listing). As the house goes
pending, both estimates have increased drastically.

This suggests that some impression metric is used in the model, because there
is not much other information available that could cause such a large
increase. It will be interesting to see what a better time series will reveal.

Both estimates vary day-to-day even after the house is pending. You would
think all the information you need to determine the sale price would be
present once the offer is made, but I'm sure facts you can observe after the
listing is pending---like how long the closing period is---have predictive
power. Redfin's estimate remains pretty tight while Zillow's changes wildly,
sometimes by 20% between days!

Finally, both estimates completely miss the actual sales price. It is not
immediate though; they take about a week to do so. Possibly a model update is
triggered immediately for newly listed properties---notice how the Redfin
price adjusts the same day it was listed---but not for sales? This makes some
sense. A listing is an event these business care about because they can profit
off it, but a sale does not provide that opportunity.
