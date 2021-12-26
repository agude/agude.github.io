---
layout: post
title: "Comparing Pre- and Post-sale Estimates of House Price"
description: >
image: /files/realtor-estimate-comparison/
hide_lead_image: True
image_alt: >
categories:
  - data-visualization
---

{% capture file_dir %}/files/realtor-estimate-comparison/{% endcapture %}


{% comment %} Aliasing some long numbers to make the table prettier.{% endcomment %}
{% capture xome_pre %}$1,040,140<span class="supsub"><sup>+89,860</sup><sub>-91,140</sub></span>{% endcapture %}
{% capture xome_post %}$1,074,820<span class="supsub"><sup>+90,535</sup><sub>-113,483</sub></span>{% endcapture %}

| Company         |  Pre-listing | Post-listing |     Post-sale |
|:----------------|-------------:|-------------:|--------------:|
| **Zillow**      |     $938,000 |     $941,000 |    $1,077,400 |
| **Realtor.com** |    $977,1000 | Not Recorded |    $1,105,000 |
| **Xome**        | {{xome_pre}} |    Unchanged | {{xome_post}} |
| **Redfin**      |   $1,144,535 |     $962,551 |    $1,090,365 |

[![A comparison of four different real estate brokers estimate for the sales
price of a single house in my neighborhood before and after it was listed and
sold.][my_plot]][my_plot]

[my_plot]: {{ file_dir }}/home_price_estimate_comparison.svg
