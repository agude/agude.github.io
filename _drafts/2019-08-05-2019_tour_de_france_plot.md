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

{% capture file_dir %}/files/hour-record/{% endcapture %}

There is no bigger event in cycling than the [Tour de France][tour], a race which
takes most of July as its 21 stages meander around France before bringing the
riders to a fated final sprint in Paris on the Champs Elysée. I love both
cycling and plots, as I [mentioned last month][last_post], so once again I
found a way to combine the two.

[tour]: https://en.wikipedia.org/wiki/Tour_de_France
[last_post]: {% post_url 2019-07-09-hour_record_plot_improvements %}

<!--
## The Races Within the Race

The Tour is said to have multiple races within the race because there are
multiple prizes that can be won and different groups of riders have set their
sights on them. They are:

- The [Yellow Jersey][yellow]: Most prestigious; awarded to the rider with the
lowest combined time across all 21 stages. When we say [PERSON X won the Tour
de France][winner], we mean he won the Yellow Jersey.
- The [White Jersey][white]: Awarded to the rider under 27 with the lowest
combined time on all the stages.
- The [Green Jersey][green]: Awarded to the rider with the most sprint points,
earned for winning or placing in various sprints during the stages.
- The [Polka Dot Jersey][polka_dot]: Awarded to the rider with the most
mountain points, earned for being one of the first few riders to reach the
summits of the various mountains.

[yellow]:
[winner]:
[white]:
[green]:
[polka_dot]:

-->

## The Race for Yellow

Only a few riders are really in contention for the Yellow Jersey; the vast
majority of the others are brought along to support their team leaders. Going
into the 2019 Tour, defending champion [Geraint Thomas][thomas], but there
were several strong challengers. [Julian Alaphillippe][alaphillippe], who held
the Jersey for the most days, was a dark horse contender who surprised the
experts; he was a rider who had traditionally excelled at hunting stage wins
and single day races.

[thomas]:
[alaphillippe]: 

Below I have plotted how the top-finishing riders did throughout the race by
showing how far behind the leader they were after each stage. Where a rider's
line is near the top they are close to taking over the lead; when they drop
down they are losing time.

[![A line plot showing how far behind the leader each top-finishing rider was after each stage.][gc_plot]][gc_plot]

[gc_plot]: {{ file_dir }}/mens_hour_records_progression.svg

## The Rest of the Race

From the above plot you might think that all riders finish within a few
minutes of each other. But they do not. The last place rider, the [laterne
rouge], was nearly XX HOURS <!-- TODO --> behind the winner.

[![A line plot showing how far behind the leader every rider was for each stage.][full_plot]][full_plot]

[full_plot]: {{ file_dir }}/mens_hour_records_progression.svg
