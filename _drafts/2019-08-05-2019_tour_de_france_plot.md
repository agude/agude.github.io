---
layout: post
title: "Plotting the 2019 Tour de France"
description: >
  I love Wikipedia, I love cycling, and I love data! So today, I improve
  Wikipedia's Hour Record Plot! Come take a look!
image: /files/hour-record/bicycle_race_by_calvert_litho_co_1895.jpg
image_alt: >
  A chromolithograph showing six men in colorful clothing racing bikes on a
  dirt track.
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

The [Yellow Jersey][yellow] is awarded to the rider with the lowest combined
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
experts---held the Jersey for the most days. He lost it for two days on stage
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
minutes of each other. But they do not. The last place rider, the [laterne
rouge][laterne], was four and a half **hours** behind Egan Bernal.

[laterne]: https://en.wikipedia.org/w/index.php?title=Special:Search&search=laterne+rogue&ns0=1&searchToken=9a18cf0pz7eygcn020bcbg80t

[![A line plot showing how far behind the leader every rider was for each stage.][full_plot]][full_plot]

[full_plot]: {{ file_dir }}/2019_tour_de_france.svg
