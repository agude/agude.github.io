---
layout: post
title: "Comparing Pre- and Post-sale Estimates of House Price"
description: >
  Can Zillow and Redfin predict prices accurately? I look at a house sold in
  my neighborhood and compare the sale price to the price predicted by Zillow
  and Redfin before they knew it was for sale.
image: /files/realtor-estimate-comparison/1935_house_plans.jpg
image_alt: >
  A line drawing of a two bedroom home done for a 1935 architecture
  competition.
categories:
  - data-visualization
---

{% capture file_dir %}/files/realtor-estimate-comparison/{% endcapture %}

When I bought my house several years ago I was unsure how much money it would
take to actually buy it. There was the list-price, of course, but I didn't
expect that to be the actual price the seller would accept. Zillow and Redfin
estimated two different prices, both slightly higher than the list price, and
my realtor suggested a forth based on comprable homes. In the end we made up a
number combining all four prices, nudged it up a bit as a hedge, and had our
offer accepted. It left me wondering if there was a better way to predict
prices, and if Zillow and Redfin had been right with their predicted prices.

Recently a house in my neighborhood recently put up a "For Sale" sign which
prompted me to look online for the listing. I couldn't find one. None of the
online real estate brokers had picked up the listing yet. I realized I had a
chance to compare their current price estimates with the actual listing and
sales price.

## Data Collection

I recorded the pre-listing estimates for four brokers: Redfin, Realtor.com,
Zillow, and Xome. Xome provides both an estimate and a high and low range. All
the others only present a single estimate. I also collected the same estimates
after the listing was picked up and again after the sale was complete. The
data is summarized in the table below:

{% comment %} Aliasing some long numbers to make the table prettier.{% endcomment %}
{% capture xome_pre %}$1,040K<span class="supsub"><sup>+90K</sup><sub>-91K</sub></span>{% endcapture %}
{% capture xome_post %}$1,074K<span class="supsub"><sup>+91K</sup><sub>-113K</sub></span>{% endcapture %}

| Company         |  Pre-listing | Post-listing |     Post-sale |
|:----------------|-------------:|-------------:|--------------:|
| **Zillow**      |        $938K |        $941K |       $1,077K |
| **Realtor.com** |        $977K | Not Recorded |       $1,105K |
| **Xome**        | {{xome_pre}} |    Unchanged | {{xome_post}} |
| **Redfin**      |      $1,144K |        $963K |       $1,090K |


I could not find Realtor.com's estimate after the listing went up, so it is
not included. Xome did not change their estimate after the listing was posted.

The house was listed at $948K and sold for $1,070K.

## Plot

Here a plot comparing the three estimates from each company to the list and
sales price:

[![A comparison of four different real estate brokers estimate for the sales
price of a single house in my neighborhood before and after it was listed and
sold.][my_plot]][my_plot]

[my_plot]: {{ file_dir }}/home_price_estimate_comparison.svg

{% comment %}The Unicode characters matching the points in the plot. See:
https://en.wikipedia.org/wiki/Geometric_Shapes_(Unicode){% endcomment %}
{% capture circle %}&#x25CF;{% endcapture %}
{% capture triangle %}&#x25B2;{% endcapture %}
{% capture square %}&#x25A0;{% endcapture %}

The three price estimates are:

- **Pre-listing**: Before the listing was picked up by the brokers,
   represented with a circle: {{circle}}
- **Post-listing**: After the listing was posted but before the sale,
   represented with a triangle: {{triangle}}
- **Post-sale**: After the sale was made public, represented with a square:
   {{square}}

I have slightly offset the date points for each company---with the circle on
left, the triangle in the middle, and the square on the right---to give a
quick indication of how the price trended in time if you read from left to
right. The Xome estimates include error bars for their high and low estimates.
The listing and sale price are shown as lines. I have colored each company's
estimates to match their brand color. The companies are sorted from lowest to
highest pre-listing estimate.

### Comments

Zillow and Redfin _strongly_ disagree about what the value of the house is
initially, with a difference between their estimates of $200k. Both estimates
poorly predict the final sales price, with Zillow underestimating by $132k and
Redfin overestimating by $74k.

Both estimates revert towards the list price when it is posted, with Redfin's
slightly higher than the listing and Zillow's slightly lower. This makes some
sense, as the list price contains new information about the current market
conditions and more importantly about the condition of the house and property
relative to its neighbors. However, in this case the list price was obviously
too low and likely intended to entice buyers.

Xome's pre-list estimate is the closest to the sale value, missing by just
about 3%, although they gave themselves a lot of room with their uncertainty.
Here are the four pre-listing estimates ranked from lowest to highest absolute
error:

| Company         |  Absolute Error| Percent Error |
|:----------------|---------------:|--------------:|
| **Xome**        |           $30k |          2.8% |
| **Redfin**      |           $74K |          6.9% |
| **Realtor.com** |           $93K |          8.7% |
| **Zillow**      |          $132K |         12.3% |
