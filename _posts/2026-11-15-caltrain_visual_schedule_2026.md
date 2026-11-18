---
layout: post
title: "Caltrain Visual Schedule: 2026"
description: >
  Caltrain electrified and rebuilt its schedule since I last drew it as a
  Marey chart in 2017. Here is the 2026 schedule, side by side with 2017.
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

On January 27, 2026, [Caltrain _once again_ updated their
schedule][caltrain_2026_schedule]. They've actually made several schedule
changes since [I last wrote about them][update_post], but I haven't bothered
to plot them because, even though I have already written the script to do so,
it still takes a lot of work to process the data and adjust bounds, etc. But
that's changed now.

[caltrain_2026_schedule]: https://www.caltrain.com/news/caltrain-announces-new-schedule

[first_post]: {% post_url 2017-05-21-caltrain_visual_schedule %}
[update_post]: {% post_url 2017-10-07-caltrain_visual_schedule_updates %}

In the fall of 2025, Anthropic released [Opus 4.5][opus_45] and coding changed
forever. At the time, I was writing about 95% of code by hand, with the rest
being filled in a smart completions from older LLM models. Now I write
[essentially no code by hand][python_free]. I figured AI could probably take
the tedium out of making these plots as well. So I told Opus 5.5:

[opus_45]: https://www.anthropic.com/news/claude-opus-4-5

[python_free]: {% post_url 2025-08-30-llms_make_python_free %}

```
It's time to update the Caltrain plots. See:

- https://alexgude.com/blog/caltrain-visual-schedule.md
- https://alexgude.com/blog/caltrain-visual-schedule-updates.md

Create a library in this folder to do it and generate the same set of plots
for the newest schedule.
```

And five minutes later it had taken my code, turned it into a library, pulled
the new data, and made the plots. I spent another few turns iterating on some
plot tweaks, but I never touched the code myself.

Here is what's changed in the intervening 9 years:

[marey]: https://en.wikipedia.org/wiki/%C3%89tienne-Jules_Marey
[la_methode]: https://archive.org/details/lamthodegraphiq00maregoog

[ibry]: {{ file_dir }}/ibry-trainschedule.jpg

{% comment %}Data and code{% endcomment %}

[dev]: https://www.caltrain.com/developer-resources
[gtfs_feed]: https://data.trilliumtransit.com/gtfs/caltrain-ca-us/caltrain-ca-us.zip
[gtfs_ref]: https://gtfs.org/documentation/schedule/reference/
[mileposts]: https://en.wikipedia.org/wiki/List_of_Caltrain_stations

{% comment -%}
TODO: Link to the code. The caltrain_schedule_2026 project has no public
repository yet.
[code]: https://github.com/agude/TODO
{%- endcomment %}

{% comment %}What changed on the line{% endcomment %}

[caltrain]: https://en.wikipedia.org/wiki/Caltrain
[schedules]: https://www.caltrain.com/schedules
[pcep]: https://en.wikipedia.org/wiki/Electrification_of_Caltrain
[atherton]: https://en.wikipedia.org/wiki/Atherton_station
[broadway]: https://en.wikipedia.org/wiki/Broadway_station_(Caltrain)
[college_park]: https://en.wikipedia.org/wiki/College_Park_station_(Caltrain)
[gilroy]: https://en.wikipedia.org/wiki/Gilroy_station

{% comment %}Lead image{% endcomment %}

[peninsula_commute]: https://en.wikipedia.org/wiki/Peninsula_Commute
[southern_pacific]: https://en.wikipedia.org/wiki/Southern_Pacific_Transportation_Company
[lead_photo]: https://commons.wikimedia.org/wiki/File:Roger_Puta%27s_slides_of_two_Southern_Pacific_trains_in_Millbrae,_CA_in_January_1985._(30930157171).jpg
[roger_puta]: https://commons.wikimedia.org/wiki/Category:Photographs_by_Roger_Puta

## Weekday

The first thing you notice when comparing the new schedule (top) to the old
schedule (bottom) is: there are a lot more trains! Two local trains an hour
for the entire day, compared to one earlier.

And there is a new type of train, the "South County" that travels exclusively
from Gilroy to Diridon. This is a consequence of the electrification of the
northern-half of the line. Gilroy to Diridon uses part of the old diesel
fleet, while Diridon to San Francisco uses the new electric trains.

[![Marey visual train schedule for Caltrain on weekdays in January 2026, including the South County Connector trains to Gilroy][gilroy_2026]][gilroy_2026]
[![Marey visual train schedule for Caltrain on weekdays in April 2017, including the stations south of San Jose to Gilroy][gilroy_2017]][gilroy_2017]

[gilroy_2017]: {{ apr2017 }}/weekday_gilroy.svg
[gilroy_2026]: {{ now }}/weekday_gilroy.svg

But beyond those two facts, it's tough to see details unless we focus on a
smaller portion.

### Morning Commute

The morning commute schedule has become much more regular. In 2017, there were
several different flavors of limited and baby bullets, but they've been
standardized in 2026 and so every limited stops at the same stations, and
likewise every express does as well. It makes it much easier to figure out
what train you need to take!

The starting times have been standardized as well. The express always leaves
San Francisco 20 minutes after the hour, and Diridon 22 minutes after, morning
and evening. The local leaves at the same minute of the hour for the entire
day.

And Caltrain isn't making use of their double tracking for passing much
anymore either. They used to have bullets overtake the limiteds, but now
that's almost completely eliminated.

[![Marey visual train schedule for Caltrain during the weekday morning commute in January 2026][morning_2026]][morning_2026]
[![Marey visual train schedule for Caltrain during the weekday morning commute in April 2017][morning_2017]][morning_2017]

[morning_2017]: {{ apr2017 }}/weekday_morning.svg
[morning_2026]: {{ now }}/weekday_morning.svg

## Electricity

What allows all these changes? Electricity! The new electric trains accelerate
much faster than the old diesel locomotives. This lets them make the trip much
faster, or stop in more places and _still_ beat out the old trains. For
example compare the new local train (solid blue line) with the old one
(dashed):

[![Marey chart comparing Local train 101 in April 2017 and January 2026, from San Jose Diridon to San Francisco][local_comparison]][local_comparison]

Same number of stops, but making the trip in 78 minutes instead of 95! 17
whole minutes faster! The limited is just as drastic:

[![Marey chart comparing Limited train 207 in April 2017 with Limited train 401 in January 2026, from San Jose Diridon to San Francisco][limited_comparison]][limited_comparison]

Here I matched two trains with a similar stop pattern since the 2017 limited
stopped at a different set of stations depending on the exact train. Notice
the new train is 15 minutes faster _and_ makes more stops! Finally, the
express:

[![Marey chart comparing Baby Bullet train 371 in April 2017 with Express train 519 in January 2026, from San Jose Diridon to San Francisco][express_comparison]][express_comparison]

The express shows the least improvement, actually running slower for the first
part of the trip, but making it up in the end to finish 6 minutes faster and
again it makes more stops!

[local_comparison]: {{ file_dir }}/comparison/local.svg
[limited_comparison]: {{ file_dir }}/comparison/limited.svg
[express_comparison]: {{ file_dir }}/comparison/express.svg

## Weekend

Finally, the weekend is drastically different, see Saturday:

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
