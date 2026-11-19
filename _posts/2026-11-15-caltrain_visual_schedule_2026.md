---
layout: post
title: "Caltrain Visual Schedule: 2026"
description: >
  Caltrain electrified and rebuilt its schedule since I last drew it as a
  Marey chart in 2017. Check out the new 2026 schedule, side by side with
  2017.
image: /files/caltrain-schedule/two_sp_trains_in_millbrae_ca_in_january_1985_by_roger_puta.jpg
hide_lead_image: True
image_alt: >
  A Southern Pacific commuter train in Millbrae in January 1985, seen head-on
  on a curve through eucalyptus trees. The lead locomotive is grey with a red
  nose, the letters 'SP' in white, and the number 51. The second locomotive is
  painted in Caltrain's colors: silver with red, blue, and teal stripes.
  Double-decker passenger cars follow.
categories:
  - caltrain
  - data-visualization
---

{% capture file_dir %}/files/caltrain-schedule{% endcapture %}
{% capture apr2017 %}{{ file_dir }}/caltrain-20170308{% endcapture %}
{% capture jul2017 %}{{ file_dir }}/caltrain-20170715{% endcapture %}
{% capture now %}{{ file_dir }}/caltrain-20261113{% endcapture %}

In 2017, I created some [_Marey/Ibry/Serjev_ visual schedules for
Caltrain][first_post], just to have some fun tweaking plots. A few months
later, I [updated them when Caltrain changed their schedule][update_post] to
accommodate the upcoming [electrification program][caltrain_wiki]. Now, 9
years later, the electrification work is complete, so I updated the
plots[^code] to see what changed.

[first_post]: {% post_url 2017-05-21-caltrain_visual_schedule %}
[update_post]: {% post_url 2017-10-07-caltrain_visual_schedule_updates %}
[caltrain_wiki]: https://en.wikipedia.org/wiki/Caltrain_Modernization_Program

[^code]:
    I had put off updating these plots because, even though all the code was
    written, getting the new data, adjusting the code to handle any schema
    changes, and then tweaking the plot layout was tedious. But now that AI is
    so capable, I decided to see if Opus 5.5 could do the job with a simple
    prompt:

    <div class="chatgpt-edit-block">
    <div class="chatgpt-prompt-only" markdown="1">
    > It's time to update the Caltrain plots. See:
    >
    > - https://alexgude.com/blog/caltrain-visual-schedule.md
    > - https://alexgude.com/blog/caltrain-visual-schedule-updates.md
    >
    > Create a library in this folder to do it and generate the same set of
    > plots for the newest schedule.
    </div>
    </div>

    And 5 minutes later I had them. It took a few more turns of tweaking to
    get them ready to publish, but the tedium was gone. Another example of how
    [LLMs make Python (and most other code) free now][python_free].

[python_free]: {% post_url 2025-08-30-llms_make_python_free %}

{% comment -%}
TODO: Link to the code. The caltrain_schedule_2026 project has no public
repository yet.
[code]: https://github.com/agude/TODO
{%- endcomment %}

## Weekday

The first thing you notice when comparing the new schedule (top) to the old
schedule (bottom) is: there are a lot more trains! Two local trains an hour
for almost the entire day, compared to just one earlier.

And there is a new type of train: the "South County", which travels
exclusively between Gilroy and Diridon. This is a consequence of the
electrification of the northern half of the line. The Gilroy to Diridon leg
uses the old diesel fleet, while Diridon to San Francisco uses the new
electric trains.

[![Marey visual train schedule for Caltrain on weekdays in January 2026, including the South County Connector trains to Gilroy][gilroy_2026]][gilroy_2026]
[![Marey visual train schedule for Caltrain on weekdays in April 2017, including the stations south of San Jose to Gilroy][gilroy_2017]][gilroy_2017]

[gilroy_2017]: {{ apr2017 }}/weekday_gilroy.svg
[gilroy_2026]: {{ now }}/weekday_gilroy.svg

But beyond those two facts, it's tough to see details unless we focus on a
smaller portion.

### Morning Commute

The morning commute schedule has become much more regular. In 2017, there were
several different flavors of limited and baby bullets (now called express),
but they've been standardized in 2026 so every limited stops at the same
stations, and every express does as well. It makes it much easier to figure
out what train you need to take!

The starting times have been standardized as well. The express always leaves
San Francisco 20 minutes after the hour, and Diridon 22 minutes after, morning
and evening. The locals follow a [clock-face schedule][wiki_clock], leaving at
the same minutes after the hour.

[wiki_clock]: https://en.wikipedia.org/wiki/Clock-face_scheduling

And Caltrain is hardly making use of their passing tracks for overtaking
anymore. They used to have bullets overtake slower trains regularly, but now
it only happens once: when southbound Express 506 passes Local 108 at about
08:20 near Diridon.

[![Marey visual train schedule for Caltrain during the weekday morning commute in January 2026][morning_2026]][morning_2026]
[![Marey visual train schedule for Caltrain during the weekday morning commute in April 2017][morning_2017]][morning_2017]

[morning_2017]: {{ apr2017 }}/weekday_morning.svg
[morning_2026]: {{ now }}/weekday_morning.svg

## Electricity

What allows all these changes? Electricity! The new electric trains accelerate
much faster than the old diesel locomotives. This lets them make the trip much
faster, or stop in more places and _still_ beat out the old trains. For
example, compare the new local train (solid blue line) with the old one
(dashed):

[![Marey chart comparing Local train 101 in April 2017 and January 2026, from San Jose Diridon to San Francisco][local_comparison]][local_comparison]

Same number of stops, but making the trip in 78 minutes instead of 95; 17
whole minutes faster! The limited is just as drastic:

[![Marey chart comparing Limited train 207 in April 2017 with Limited train 401 in January 2026, from San Jose Diridon to San Francisco][limited_comparison]][limited_comparison]

Here I matched two trains with similar stop patterns, since 2017's limiteds
varied from train to train. Notice the new train is 15 minutes faster _and_
makes more stops between Diridon and San Francisco! Finally, the express:

[![Marey chart comparing Baby Bullet train 371 in April 2017 with Express train 519 in January 2026, from San Jose Diridon to San Francisco][express_comparison]][express_comparison]

The express shows the least improvement, actually running slower for the first
part of the trip---but again, with more stops!---before making it up in the
end to finish 6 minutes faster.

[local_comparison]: {{ file_dir }}/comparison/local.svg
[limited_comparison]: {{ file_dir }}/comparison/limited.svg
[express_comparison]: {{ file_dir }}/comparison/express.svg

## Weekend

Finally, the weekend is drastically different. For example, see Saturday:

[![Marey visual train schedule for Caltrain on Saturday in January 2026][saturday_2026]][saturday_2026]
[![Marey visual train schedule for Caltrain on Saturday in July 2017][saturday_jul2017]][saturday_jul2017]

[saturday_2026]: {{ now }}/saturday.svg
[saturday_jul2017]: {{ jul2017 }}/saturday.svg

Wow! Double the number of trains! But in exchange we lose the express.

## All the Plots

I made far more plots than I could fit in this post. Here is every one:

| Chart           |         January 2026 |               July 2017 |              April 2017 |
| :-------------- | -------------------: | ----------------------: | ----------------------: |
| Weekday         |  [SVG][weekday_2026] |  [SVG][weekday_jul2017] |  [SVG][weekday_apr2017] |
| With Gilroy     |   [SVG][gilroy_2026] |   [SVG][gilroy_jul2017] |      [SVG][gilroy_2017] |
| Northbound      |    [SVG][north_2026] |    [SVG][north_jul2017] |    [SVG][north_apr2017] |
| Southbound      |    [SVG][south_2026] |    [SVG][south_jul2017] |    [SVG][south_apr2017] |
| Morning commute |  [SVG][morning_2026] |  [SVG][morning_jul2017] |     [SVG][morning_2017] |
| Evening commute |  [SVG][evening_2026] |  [SVG][evening_jul2017] |  [SVG][evening_apr2017] |
| Saturday        | [SVG][saturday_2026] | [SVG][saturday_jul2017] | [SVG][saturday_apr2017] |
| Sunday          |   [SVG][sunday_2026] |   [SVG][sunday_jul2017] |   [SVG][sunday_apr2017] |

[weekday_2026]: {{ now }}/weekday.svg
[weekday_jul2017]: {{ jul2017 }}/weekday.svg
[weekday_apr2017]: {{ apr2017 }}/weekday.svg
[north_2026]: {{ now }}/weekday_north.svg
[north_jul2017]: {{ jul2017 }}/weekday_north.svg
[north_apr2017]: {{ apr2017 }}/weekday_north.svg
[south_2026]: {{ now }}/weekday_south.svg
[south_jul2017]: {{ jul2017 }}/weekday_south.svg
[south_apr2017]: {{ apr2017 }}/weekday_south.svg
[evening_2026]: {{ now }}/weekday_evening.svg
[evening_jul2017]: {{ jul2017 }}/weekday_evening.svg
[evening_apr2017]: {{ apr2017 }}/weekday_evening.svg
[sunday_2026]: {{ now }}/sunday.svg
[sunday_jul2017]: {{ jul2017 }}/sunday.svg
[sunday_apr2017]: {{ apr2017 }}/sunday.svg
[morning_jul2017]: {{ jul2017 }}/weekday_morning.svg
[gilroy_jul2017]: {{ jul2017 }}/weekday_gilroy.svg
[saturday_apr2017]: {{ apr2017 }}/saturday.svg

## Other Writings on Caltrain

If you enjoyed this article, here are all the other articles I wrote about
[Caltrain][caltrain_topic]!

[caltrain_topic]: {% link topics/caltrain.md %}

{% display_category_posts
  topic="caltrain"
  exclude_current_page=true
%}
