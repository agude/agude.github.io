---
layout: post
title: "Caltrain Visual Schedule: 2026"
description: >
  Caltrain electrified and rebuilt its schedule since I last drew it as a
  Marey chart in 2017. Here is the 2026 schedule, side by side with 2017.
image: /files/caltrain-schedule/two_sp_trains_in_millbrae_ca_in_january_1985_by_roger_puta.jpg
hide_lead_image: False
image_alt: >
  A Southern Pacific commuter train in Millbrae in January 1985, seen head-on
  on a curve through eucalyptus trees. The lead locomotive is grey with a red
  nose, the letters 'SP' in white, and the number 51. The second locomotive is
  painted in Caltrain's colors: silver with red, blue, and teal stripes.
  Double-decker passenger cars follow.
categories:
  - data-visualization
---

{% comment -%}
TODO: Opening paragraph. It becomes the excerpt, so it must come before any
capture block.
{%- endcomment %}

{% capture file_dir %}/files/caltrain-schedule{% endcapture %}
{% capture apr2017 %}{{ file_dir }}/caltrain-20170308{% endcapture %}
{% capture jul2017 %}{{ file_dir }}/caltrain-20170715{% endcapture %}
{% capture now %}{{ file_dir }}/caltrain-20261113{% endcapture %}

{% comment %}Earlier posts{% endcomment %}

[first_post]: {% post_url 2017-05-21-caltrain_visual_schedule %}
[update_post]: {% post_url 2017-10-07-caltrain_visual_schedule_updates %}

{% comment %}Marey and Ibry, for the recap of the first post{% endcomment %}

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

[![Marey visual train schedule for Caltrain on weekdays in April 2017][weekday_2017]][weekday_2017]
[![Marey visual train schedule for Caltrain on weekdays in January 2026][weekday_2026]][weekday_2026]

[weekday_2017]: {{ apr2017 }}/weekday.svg
[weekday_2026]: {{ now }}/weekday.svg

### Northbound and Southbound

[![Marey visual train schedule for Caltrain on weekdays in January 2026, northbound trains highlighted][north_2026]][north_2026]
[![Marey visual train schedule for Caltrain on weekdays in January 2026, southbound trains highlighted][south_2026]][south_2026]

[north_2017]: {{ apr2017 }}/weekday_north.svg
[south_2017]: {{ apr2017 }}/weekday_south.svg
[north_2026]: {{ now }}/weekday_north.svg
[south_2026]: {{ now }}/weekday_south.svg

### Morning Commute

[![Marey visual train schedule for Caltrain during the weekday morning commute in April 2017][morning_2017]][morning_2017]
[![Marey visual train schedule for Caltrain during the weekday morning commute in January 2026][morning_2026]][morning_2026]

[morning_2017]: {{ apr2017 }}/weekday_morning.svg
[morning_2026]: {{ now }}/weekday_morning.svg

### Evening Commute

[![Marey visual train schedule for Caltrain during the weekday evening commute in April 2017][evening_2017]][evening_2017]
[![Marey visual train schedule for Caltrain during the weekday evening commute in January 2026][evening_2026]][evening_2026]

[evening_2017]: {{ apr2017 }}/weekday_evening.svg
[evening_2026]: {{ now }}/weekday_evening.svg

### South County

[![Marey visual train schedule for Caltrain on weekdays in April 2017, including the stations south of San Jose to Gilroy][gilroy_2017]][gilroy_2017]
[![Marey visual train schedule for Caltrain on weekdays in January 2026, including the South County Connector trains to Gilroy][gilroy_2026]][gilroy_2026]

[gilroy_2017]: {{ apr2017 }}/weekday_gilroy.svg
[gilroy_2026]: {{ now }}/weekday_gilroy.svg

## Weekend

### Saturday

[![Marey visual train schedule for Caltrain on Saturday in April 2017][saturday_apr2017]][saturday_apr2017]
[![Marey visual train schedule for Caltrain on Saturday in July 2017][saturday_jul2017]][saturday_jul2017]
[![Marey visual train schedule for Caltrain on Saturday in January 2026][saturday_2026]][saturday_2026]

[saturday_apr2017]: {{ apr2017 }}/saturday.svg
[saturday_jul2017]: {{ jul2017 }}/saturday.svg
[saturday_2026]: {{ now }}/saturday.svg

### Sunday

[![Marey visual train schedule for Caltrain on Sunday in April 2017][sunday_apr2017]][sunday_apr2017]
[![Marey visual train schedule for Caltrain on Sunday in July 2017][sunday_jul2017]][sunday_jul2017]
[![Marey visual train schedule for Caltrain on Sunday in January 2026][sunday_2026]][sunday_2026]

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
