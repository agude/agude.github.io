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

[![Marey visual train schedule for Caltrain on weekdays in January 2026][weekday_2026]][weekday_2026]
[![Marey visual train schedule for Caltrain on weekdays in April 2017][weekday_2017]][weekday_2017]

But beyond those two facts, it's tough to see details unless we focus on a
smaller portion.

[weekday_2017]: {{ apr2017 }}/weekday.svg
[weekday_2026]: {{ now }}/weekday.svg

[north_2017]: {{ apr2017 }}/weekday_north.svg
[south_2017]: {{ apr2017 }}/weekday_south.svg
[north_2026]: {{ now }}/weekday_north.svg
[south_2026]: {{ now }}/weekday_south.svg

### Morning Commute

The morning commute schedule has become much more regular. In 2017, there were
several different flavors of limited and baby bullets, but they've been
standardized in 2026 and so every limited stops at the same stations, and
likewise every express does as well. It makes it much easier to figure out
what train you need to take!

The starting times have been standardized as well.

And Caltrain isn't making use of their double tracking for passing much
anymore either. They used to have bullets overtake the limiteds, but now
that's almost completely eliminated.

[![Marey visual train schedule for Caltrain during the weekday morning commute in January 2026][morning_2026]][morning_2026]
[![Marey visual train schedule for Caltrain during the weekday morning commute in April 2017][morning_2017]][morning_2017]

[morning_2017]: {{ apr2017 }}/weekday_morning.svg
[morning_2026]: {{ now }}/weekday_morning.svg

### Evening Commute

[![Marey visual train schedule for Caltrain during the weekday evening commute in January 2026][evening_2026]][evening_2026]
[![Marey visual train schedule for Caltrain during the weekday evening commute in April 2017][evening_2017]][evening_2017]

[evening_2017]: {{ apr2017 }}/weekday_evening.svg
[evening_2026]: {{ now }}/weekday_evening.svg

### South County

[![Marey visual train schedule for Caltrain on weekdays in January 2026, including the South County Connector trains to Gilroy][gilroy_2026]][gilroy_2026]
[![Marey visual train schedule for Caltrain on weekdays in April 2017, including the stations south of San Jose to Gilroy][gilroy_2017]][gilroy_2017]

[gilroy_2017]: {{ apr2017 }}/weekday_gilroy.svg
[gilroy_2026]: {{ now }}/weekday_gilroy.svg

## Weekend

### Saturday

[![Marey visual train schedule for Caltrain on Saturday in January 2026][saturday_2026]][saturday_2026]
[![Marey visual train schedule for Caltrain on Saturday in July 2017][saturday_jul2017]][saturday_jul2017]
[![Marey visual train schedule for Caltrain on Saturday in April 2017][saturday_apr2017]][saturday_apr2017]

[saturday_apr2017]: {{ apr2017 }}/saturday.svg
[saturday_jul2017]: {{ jul2017 }}/saturday.svg
[saturday_2026]: {{ now }}/saturday.svg

### Sunday

[![Marey visual train schedule for Caltrain on Sunday in January 2026][sunday_2026]][sunday_2026]
[![Marey visual train schedule for Caltrain on Sunday in July 2017][sunday_jul2017]][sunday_jul2017]
[![Marey visual train schedule for Caltrain on Sunday in April 2017][sunday_apr2017]][sunday_apr2017]

[sunday_apr2017]: {{ apr2017 }}/sunday.svg
[sunday_jul2017]: {{ jul2017 }}/sunday.svg
[sunday_2026]: {{ now }}/sunday.svg

{% comment -%}
Unused chart files, available if the post needs them:
{{ jul2017 }}/weekday.svg, weekday_north.svg, weekday_south.svg,
weekday_gilroy.svg, weekday_morning.svg, weekday_evening.svg.
{{ apr2017 }}/weekday_north.svg and weekday_south.svg are defined above as
north_2017 and south_2017 but not shown.
{%- endcomment %}

## Stations

{% comment -%}
TODO: Atherton (closed; weekend-only in 2017), Broadway (weekend-only),
College Park (four weekday trains), Hayward Park.
{%- endcomment %}

## How I Made These

{% comment -%}
TODO: GTFS feed, station distances from shape_dist_traveled, 2017 feeds
re-drawn with 2026 distances, the code link.
{%- endcomment %}
