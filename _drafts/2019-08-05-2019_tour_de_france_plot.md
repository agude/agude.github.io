---
layout: post
title: "Plotting the 2019 Tour de France"
description: >
  The Tour de France is a sporting event decided be mere minutes; to see
  exactly how those minutes were earned, read on for my plots!
image: /files/tour-de-france/tour_de_france_1932.jpg
image_alt: >
  A black and white photo of the competitors in the 1932 Tour de France.
categories: plotting
---

{% capture file_dir %}/files/tour-de-france/{% endcapture %}

There is no bigger event in cycling than the [Tour de France][tour], a race which
takes most of July as its 21 stages meander around France before bringing the
riders to a fateful final sprint in Paris on the Champs-Élysées. I love both
cycling and plots, as I [mentioned last month][last_post], so once again I
found a way to combine the two.

[tour]: https://en.wikipedia.org/wiki/Tour_de_France
[last_post]: {% post_url 2019-07-09-hour_record_plot_improvements %}

## The Race for Yellow

The [yellow jersey][yellow] is awarded to the rider with the lowest combined
time across all 21 stages of the tour. Only a few riders are really in
contention for yellow; the vast majority of the others are brought along to
support their team leaders. Going into the 2019 Tour, defending champion
[Geraint Thomas][thomas] was the favorite, but there were several strong
challengers.

[yellow]: https://en.wikipedia.org/wiki/General_classification_in_the_Tour_de_France
[thomas]: https://en.wikipedia.org/wiki/Geraint_Thomas

Below I show how the top-finishing riders did throughout the race by plotting
how far behind the leader they were after each stage. Where a rider's line is
near the top they are close to taking over the lead; when they drop down they
are losing time.

[![A line plot showing how far behind the leader each top-finishing rider was after each stage.][gc_plot]][gc_plot]

[gc_plot]: {{ file_dir }}/2019_tour_de_france_top_5.svg

[Julian Alaphilippe][alaphillippe]---a dark horse contender who surprised the
experts---held the jersey for the most days. He lost it for two days on stage
5 to a sprinter [Giulio Ciccone][ciccone], but took it back on stage 8 and
held until the shortened stage 19, when [Egan Bernal][bernal] took it with a
decisive attack. Surprisingly, Alaphilippe won the [individual time
trial][itt] and gained a minute on the climbers Bernal and [Emanuel
Buchmann][buchmann], even distancing time-trialist Thomas. Alaphilippe, who is
not a pure climber, lost time on most mountain stages. He began to slip on
stage 15, lost the jersey on 19, and lost his podium spot on stage 20,
finishing 5th when they rolled through the Champs-Élysées.

[alaphillippe]: https://en.wikipedia.org/wiki/Julian_Alaphilippe
[ciccone]: https://en.wikipedia.org/wiki/Giulio_Ciccone
[bernal]: https://en.wikipedia.org/wiki/Egan_Bernal
[itt]: https://en.wikipedia.org/wiki/Individual_time_trial
[buchmann]: https://en.wikipedia.org/wiki/Emanuel_Buchmann

## The Rest of the Race

From the above plot you might think that all riders finish within a few
minutes of each other. But they do not. The last place rider, the [lanterne
rouge][lanterne], was four and a half **hours** behind Egan Bernal.

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
sprints, so he took it easy on mountain stages as you can see in the steep
declines on stages 14 and 15 (the Pyrenees) and Stages 18--20 (the Alps). Most
other riders had similar performance, as you can see, although some recovered
time on stage 17 when the favorites let a large break away group escape and
take a 20 minute advantage. Sagan did not make that group, as we can see.

[Romain Bardet][bardet], the [polka dot jersey][polka_dot] winner, was
fighting for the yellow jersey until stage 14 where he cracked and lost 20
minutes. This forced him to pivot to going for the climbing jersey. To win
this, he had to be one of the first at the top of the major climbs, so for the
remaining stages he stayed with the favorites or attacked early, keeping his
time behind pretty consistent.

[sagan]: https://en.wikipedia.org/wiki/Peter_Sagan
[green]: https://en.wikipedia.org/wiki/Points_classification_in_the_Tour_de_France
[bardet]: https://en.wikipedia.org/wiki/Romain_Bardet
[polka_dot]: https://en.wikipedia.org/wiki/Mountains_classification_in_the_Tour_de_France
