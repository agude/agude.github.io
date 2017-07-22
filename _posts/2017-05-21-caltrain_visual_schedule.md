---
layout: post
title: "Caltrain Visual Schedule"
description: >
  In 1878, Marey published a famous visual train schedule based on work by Ibry. What would it look like for Silicon Valley's Caltrain? Come find out!
image: /files/caltrain-schedule/sp_3208_with_train_128_in_redwood_city_ca_in_august_1980_by_roger_puta.jpg
---

{% capture file_dir %}{{ site.url }}/files/caltrain-schedule{% endcapture %}

In 1878, [Étienne-Jules Marey][ejm] published [_La Méthode
Graphique_][original_graphique],[^1] a manual on using graphs for data
analysis. The book included Ibry's[^2] [famous visualization of a French train
schedule][schedule_image] which shows the position (y-axis) of trains
traveling from Paris to Lyon as a function of the time of day (x-axis). The
schedule elegantly packs a lot of information into a small space: the speed
and direction of trains are indicated by their slope, and when lines cross it
indicates that the trains pass each other. The schedule is such an iconic
visualization that [Tufte][tufte] used it as the cover of _The Visual
Display of Quantitative Information_.

[![Graph showing the progress of trains on a railway, according to the method
of Ibry][schedule_image]][schedule_image]

[ejm]: https://en.wikipedia.org/wiki/%C3%89tienne-Jules_Marey
[original_graphique]: https://archive.org/details/lamthodegraphiq00maregoog
[schedule_image]: {{ file_dir }}/ibry-trainschedule.png
[tufte]: https://en.wikipedia.org/wiki/Edward_Tufte

While Ibry's schedule is the most famous example, it was not the first: [an
earlier example was produced by Serjev in Russia][paper]. Nor was it the last,
as many people have produced similar diagrams for [the T in Boston][boston],
[BART][bart], and [Caltrain][caltrain_vis] (and [over][caltrain_vis2], and
[over][caltrain_vis3], and [over][caltrain_vis4] again). As a frequent
[Caltrain][caltrain] commuter, I thought I would try to put my spin on it. You
can find the Jupyter notebook used to make these schedules [here][notebook]
([rendered on Github][rendered]). The schedule data is from [Caltrain's
developer site][dev].

[paper]: http://dx.doi.org/10.1080/09332480.2013.772394
[boston]: http://mbtaviz.github.io/
[bart]: http://www.drones.com/bart.html
[caltrain_vis]: http://vis.berkeley.edu/courses/cs294-10-sp10/wiki/index.php/A4-PaulIvanov
[caltrain_vis2]: https://mbostock.github.io/protovis/ex/caltrain-full.html
[caltrain_vis3]: https://www.davidstarke.com/projects/caltrain/
[caltrain_vis4]: http://www.svds.com/wp-content/uploads/2016/05/DataEDGE_2016.pdf#page=14
[caltrain]: https://en.wikipedia.org/wiki/Caltrain
[notebook]: {{ file_dir}}/Caltrain Marey Schedule.ipynb
[rendered]: https://github.com/agude/agude.github.io/blob/master/files/caltrain-schedule/Caltrain%20Marey%20Schedule.ipynb
[dev]: http://www.caltrain.com/developer.html

## Caltrain

The three types of train are color coded as follows: local trains are blue,
limited-stop trains are green, and baby bullets are red. Every stop for a
train is indicated by a circle. The spacing between the stations on the y-axis
is scaled to the actual distance [recorded on the track
mileposts][mileposts].[^3] Click the schedules for larger versions.

[mileposts]: https://en.wikipedia.org/wiki/List_of_Caltrain_stations

### Weekday

On the weekday there are so many trains that the full schedule is hard to
read, so instead I have focused on the morning and evening commute times. The
full weekday schedule is [here][weekday] ([northbound only][weekday_north] and
[southbound only][weekday_south]). The full schedule with Gilroy included is
[here][weekday_gilroy].

[weekday]: {{ file_dir }}/caltrain_weekday.svg
[weekday_north]: {{ file_dir }}/caltrain_weekday_north.svg
[weekday_south]: {{ file_dir }}/caltrain_weekday_south.svg
[weekday_gilroy]: {{ file_dir }}/caltrain_weekday_gilroy.svg

[![Caltrain][weekday_morning]][weekday_morning]
[![Caltrain][weekday_evening]][weekday_evening]

[weekday_morning]: {{ file_dir }}/caltrain_weekday_morning.svg
[weekday_evening]: {{ file_dir }}/caltrain_weekday_evening.svg

In the morning there are six northbound bullets and five southbound while in
the evening the numbers are reversed. There are pairs of limited trains where
one of the pair makes most southern stops, and the other makes most northern
stops; the train making fewer stops initially catches up but then falls back
again as the lead train starts making fewer stops. We can see that the bullets
overtake the limited and local trains [near Bayshore and Lawrence][ctx].
Finally, it is tough to see because I have cut off stations after
[Tamien][tamien], but three trains head north from [Gilroy][gilroy] early in
the morning, and three trains end there in the evening, ready for the next
morning's commute.

[ctx]: https://en.wikipedia.org/wiki/Caltrain_Express
[tamien]: https://en.wikipedia.org/wiki/Tamien_Station
[gilroy]: https://en.wikipedia.org/wiki/Gilroy_station

### Weekend

[![Caltrain][saturday]][saturday]
[![Caltrain][sunday]][sunday]

[saturday]: {{ file_dir }}/caltrain_saturday.svg
[sunday]: {{ file_dir }}/caltrain_sunday.svg

The weekends have far fewer trains. A local train runs in each direction
hourly, and there are four bullets each day. Only one bullet is running at a
time, and so it is possible they use the same [rolling stock][rs] for the
north and southbound trips. Saturday has two more north bound, and one more
southbound train than Sunday.

[rs]: https://en.wikipedia.org/wiki/Rolling_stock

---

[^1]: The full title is _La Méthode Graphique Dans les Sciences Expérimentales et Principalement en Physiologie et en Médecine_, or roughly _The Graphical Method in Experimental Sciences and Mainly in Physiology and Medicine_.
[^2]: The caption in Marey's book reads: _"Graphique de la marche des trains sur un chemin de fer, d'après la méthode de Ibry"_ or _"Graph showing the progress of trains on a railway, according to the method of Ibry"_. Unfortunately, little else is know of Ibry, and so this type of chart is often named for Marey instead.
[^3]: The mileposts markers are off by up to 100m for stations south of [Lawrence][lawrence]. I tried to measure the actual track distances using [OpenStreetMap][osm] but found that I could not do so more accurately than the milepost numbers.

[lawrence]: https://en.wikipedia.org/wiki/Lawrence_station_(Caltrain)
[osm]: https://www.openstreetmap.org/#map=11/37.5574/-122.3050&layers=T
