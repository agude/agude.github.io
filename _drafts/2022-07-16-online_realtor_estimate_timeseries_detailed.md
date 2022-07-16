---
layout: post
title: "Comparing Zillow, Redfin, and Realtor.com Price Estimates in Time"
description: >
  How do various online brokers' home price estimates change in time? I use a
  recently sold house near my neightborhood to find out. Come check it out!
image: /files/online-realtor-estimate-comparison/1935_mission_style_house.jpg
image_alt: >
  A line drawing of a mission style home from Architect and Engineer magazine.
categories:
  - data-science
  - data-visualization
---

{% capture file_dir %}/files/online-realtor-estimate-comparison/{% endcapture %}

A few months ago I [built a time series][previous_post] of a house's
price estimate from Zillow and Redfin. But there were some problems:

[previous_post]: {% post_url 2022-04-25-online_realtor_estimate_timeseries %}

- I only collected dense data starting right before the property went pending.
- I collected data by hand so I often missed days.

When another nearby house put a sign out saying "coming soon", I wrote a
script to automate the scraping and collected a much denser time series from
Zillow, Redfin, and Realtor.com. Let's see what we can learn with more
complete data!

You can find the Jupyter notebook used to perform this analysis
[here][notebook] ([rendered on Github][rendered]). The data can be found
[here][data].

{% capture notebook_uri %}{{ "House Price Estimate Timeseries Plot Automated.ipynb" | uri_escape }}{% endcapture %}

[notebook]: {{ file_dir }}/{{ notebook_uri }}
[rendered]: https://github.com/agude/agude.github.io/blob/master{{ file_dir }}/{{ notebook_uri }}
[data]: {{ file_dir }}/home_price_estimate_20220701.json

## Data Collection

I wrote a script to download the entire page for the specific house from each
of the three sites. I ran it on my Raspberry Pi everyday using `cron`. I
parsed the HTML using Python and a wrote the [cleaned data][data] to JSON.
That parsing notebook can be found [here][notebook] ([rendered on
Github][rendered]). I won't include the raw data, you will have to collect
some yourself.

{% capture notebook_uri %}{{ "parse_zillow.ipynb" | uri_escape }}{% endcapture %}

[notebook]: {{ file_dir }}/{{ notebook_uri }}
[rendered]: https://github.com/agude/agude.github.io/blob/master{{ file_dir }}/{{ notebook_uri }}

## Plot

Here is a plot comparing the estimates for the sales price from Zillow and
Redfin in time:

[![A plot showing three time series, one is the estimated value of a house
according to Zillow, one is the estimate for the same house from
Redfin, and the last is the estimate from Realtor.com.][my_plot]][my_plot]

[my_plot]: {{ file_dir }}/home_price_estimate_timeseries_comparison_automated.svg

The daily price estimates from Redfin are shown using red circles, the
estimates for Zillow are shown using blue triangles, the estimates for
Realtor.com are shown using purple diamonds.

### Comments

I wrote a script to ensure that I would get data for every day, but as you can
see there are still many missing points. 

#### Realtor.com

Realtor.com is the most frustrating! As soon as the house was actually listed
on the market they stopped providing estimates! Realtor.com starts estimating
again only after the sale price is posted. **This defeats the entire point!**
The estimate is most important when the house is actually for sale and
Realtor.com just punts completely. Embarrassing.

Still we can see that, when the house is _not_ for sale, they update their
estimate roughly every two weeks. Their initially estimates are not too bad,
just about 6% low from the final sale price.

#### Zillow

Zillow similarly is missing estimates for most of the time when the home is
actually for sale. Their page shows _"Zestimate: None"_ with an error
explanation blaming county transactional data.[^error] I am sure that's _true_
but I am unimpressed. Dealing with missing data is a key part of building a
robust machine learning model.

[^error]: The error message:

    > **Where's the Zestimate?**
    > 
    > County transactional data for this home is insufficient so we cannot
    > calculate a Zestimate. We are adding data all the time, so be sure to come
    > back.

Zillow's model updates more frequently than Realtor.com's. It slowly climbs
until it abruptly stops estimating a few days after the listing is posted.
This suggests they make use of a different model for currently on-the-market
homes and that that model requires more and different data than the
off-the-market model.

The Zillow estimate does return at the end of the pending period but... I do
not have anything nice to say about it. Just look at that variance!

Zillow underestimates the final price by about 10%.

#### Redfin

Redfin is the only company that keeps posting estimates once the house is
actually for sale! Their pre-listing estimate is almost exactly right, but
once the house is listed their on-the-market model over estimates by about
10%.

Before the listing is posted, Redfin updates its estimate roughly weekly, and
like Zillow it takes 5 days to switch to the on-the-market model. This
suggests that both sites get their data indicating the house is for sale from
the same source. After the listing the model updates daily.

The on-the-market model trends upwards at first and then stabilizes after the
house is pending, but because the time between listing and pending was so
short it is impossible to tell if the stabilization was due to the listing
going pending or not.

## Conclusions

With the denser data and all three sites to compare, I conclude the following:

- Zillow and Redfin both use separate models for the time pre/post-listing
  and the time when the house is listed. It's likely Realtor.com does as well
  which is why it stopped updating as soon as the house was listed.
- The on-the-market model, used during the listing period, are updated more
  frequently, this is probably due to the fact that they have more
  high-frequency data (views, time on market, etc.) and the possibility of
  making a commission on the property increases the amount of money they're
  willing to spend running the models.
- Zillow and Redfin are both using the same data source to determine when to
  switch their models, and it appears to be different than the source they use
  to display if a home is actually listed or not. I don't know why that would
  be. Possibly their models require data that is not immediately available?
- Zillow and Realtor.com require the same data for their model during the
  listing period and fail if that source is unavailable. Redfin continues
  estimating, but does so poorly.
