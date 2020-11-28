---
layout: post
title: "Plotting the 2019 Tour de France"
description: >
  The Tour de France is a sporting event decided by mere minutes; to see
  exactly how those minutes were earned, read on for my plots!
image: /files/tour-de-france/tour_de_france_1932.jpg
image_alt: >
  A black and white photo of the competitors in the 1932 Tour de France.
categories:
  - cycling
  - data-visualization
---

{% capture file_dir %}/files/tour-de-france/{% endcapture %}

There is no bigger event in cycling than the [Tour de France][tour], a race
which takes most of July as it crisscrosses France before bringing the riders
to a fateful final sprint in Paris on the Champs-Élysées. I love both cycling
and plots (as I [mentioned last month][last_post]), so once again I found a
way to combine the two, by graphically exploring how the race unfolded.

[tour]: https://en.wikipedia.org/wiki/Tour_de_France
[last_post]: {% post_url 2019-07-09-hour_record_plot_improvements %}

The code that generated the plots can be found [here][plot_code]
([rendered on Github][rendered]). The data [is here][data].

{% capture notebook_uri %}{{ "Tour de France Plot.ipynb" | uri_escape }}{% endcapture %}
[plot_code]: {{ file_dir }}/{{ notebook_uri }}
[rendered]: https://github.com/agude/agude.github.io/blob/master{{ file_dir }}/{{ notebook_uri }}
[data]: {{ file_dir }}/2019-tdf-dataframe.json

## The Race for Yellow

The [yellow jersey][yellow] is awarded to the rider with the lowest combined
time across all 21 stages of the tour. Only a few riders are really in
contention for yellow; the vast majority of the others are brought along to
support their team leaders. Going into the 2019 Tour, defending champion
[Geraint Thomas][thomas] was the favorite, but there were several strong
challengers.

[yellow]: https://en.wikipedia.org/wiki/General_classification_in_the_Tour_de_France
[thomas]: https://en.wikipedia.org/wiki/Geraint_Thomas

Below I show how the top riders did throughout the race by plotting how far
behind the leader they were after each stage. Where a rider's line is near the
top they are close to taking the lead; when they drop down they are losing
time.

[![A line plot showing how far behind the leader each top-finishing rider was after each stage.][gc_plot]][gc_plot]

[gc_plot]: {{ file_dir }}/2019_tour_de_france_top_5.svg

[Julian Alaphilippe][alaphillippe] held the jersey for the most days, even
defending it on the [individual time trial][itt] against expert time trialist
Thomas. But Alaphilippe is not a climber, and after a brave defense of the
jersey in the Pyrenees, he lost time in the Alps to [Egan Bernal][bernal],
[Steven Kruijswijk][kruijswijk], [Emanuel Buchmann][buchmann], and [Thibaut
Pinot][pinot]. Pinot had looked out of contention earlier, but stormed back
with a massive attack on stage 15. Unfortunately, he was forced to withdraw on
stage 19 due to an injury.

Alaphilippe finally fell behind during that stage as well, losing the yellow
jersey to Bernal. He lost his podium spot on stage 20 when he cracked during
the final part of the climb. Alaphilippe finished 5th when the peloton rolled
through the Champs-Élysées.

[alaphillippe]: https://en.wikipedia.org/wiki/Julian_Alaphilippe
[itt]: https://en.wikipedia.org/wiki/Individual_time_trial
[bernal]: https://en.wikipedia.org/wiki/Egan_Bernal
[kruijswijk]: https://en.wikipedia.org/wiki/Steven_Kruijswijk
[buchmann]: https://en.wikipedia.org/wiki/Emanuel_Buchmann
[pinot]: https://en.wikipedia.org/wiki/Thibaut_Pinot

## The Rest of the Race

From the above plot you might think that all the riders in the Tour finish
within a few minutes of each other. But they do not. The last place rider, the
[lanterne rouge][lanterne], was four and a half **hours** behind Egan Bernal.

[lanterne]: https://en.wikipedia.org/wiki/Lanterne_rouge

[![A line plot showing how far behind the leader every rider was for each stage.][full_plot]][full_plot]

[full_plot]: {{ file_dir }}/2019_tour_de_france.svg

Bernal and Alaphilippe, who looked so far apart in the first plot, are now
seen to be neck-and-neck. [Yoann Offredo][offredo] looked like a lock to win
the lanterne rogue when he fell ill on stage 8, but [Sebastian
Langeveld][langeveld] took it in the penultimate stage after suffering an
injury in the second week of the race.

[offredo]: https://en.wikipedia.org/wiki/Yoann_Offredo
[langeveld]: https://en.wikipedia.org/wiki/Sebastian_Langeveld

[Peter Sagan][sagan], the [green jersey][green] winner, was only interested in
sprints. He took it easy on the mountain stages to conserve energy, as you can
see in the steep declines on stages 14 and 15 (in the Pyrenees) and Stages 18--20
(in the Alps). Most other riders performed similarly, although some recovered
time on stage 17 when the favorites let a large breakaway group escape and
gain a 20 minute advantage. Sagan did not make that group, which is clear from
his lack of rise on the plot.

[Romain Bardet][bardet], the [polka dot jersey][polka_dot] winner, was
fighting for the yellow jersey until stage 14 where he cracked and lost 20
minutes. This forced him to pivot to trying to win the climbing jersey, which
meant he needed to be one of the first riders to reach the top of the
remaining climbs. For the last few climbing stages he stayed with the
favorites or attacked early, keeping his time behind pretty consistent.

[sagan]: https://en.wikipedia.org/wiki/Peter_Sagan
[green]: https://en.wikipedia.org/wiki/Points_classification_in_the_Tour_de_France
[bardet]: https://en.wikipedia.org/wiki/Romain_Bardet
[polka_dot]: https://en.wikipedia.org/wiki/Mountains_classification_in_the_Tour_de_France
