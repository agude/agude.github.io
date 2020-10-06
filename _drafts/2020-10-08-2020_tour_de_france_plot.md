---
layout: post
title: "Plotting the 2020 Tour de France"
description: >
  The Tour de France is a sporting event decided by mere minutes; to see
  exactly how those minutes were earned, read on for my plots!
image: /files/tour-de-france/tour_de_france_1932.jpg
image_alt: >
  A black and white photo of the competitors in the 1932 Tour de France.
categories: plotting
---

{% capture file_dir %}/files/tour-de-france/{% endcapture %}

The [Tour de France][tour] was postponed by [the pandemic][covid] this year,
but finally kicked off in late August. Although there were worries that the
race would have to be stopped in the middle, it made it all the way to the
final sprint on the Champs-Élysées in Paris. In this post, just like [last
year][last_post], I will explore how the Tour unfolded in plots.

[tour]: https://en.wikipedia.org/wiki/2020_Tour_de_France
[covid]: https://en.wikipedia.org/wiki/COVID-19_pandemic
[last_post]: {% post_url 2019-08-05-2019_tour_de_france_plot %}

The code that generated the plots can be found [here][plot_code]
([rendered on Github][rendered]). The data [is here][data].

{% capture notebook_uri %}{{ "Tour de France 2020 Plot.ipynb" | uri_escape }}{% endcapture %}
[plot_code]: {{ file_dir }}/{{ notebook_uri }}
[rendered]: https://github.com/agude/agude.github.io/blob/master{{ file_dir }}/{{ notebook_uri }}
[data]: {{ file_dir }}/2020-tdf-dataframe.json

## The Race for Yellow

The most prestigious award at the Tour is the [yellow jersey][yellow], which
is awarded to the rider with the lowest combined time across all 21 stages of
the race. [Egan Bernal][bernal] was the favorite going into this year as he
had won last year's race. Benefiting his chances was the fact that [Team
Ineos][ineos] left former winners [Chris Froome][froome] and [Geraint
Thomas][thomas] off their Tour roster, making Bernal the sole leader for his
team.

[yellow]: https://en.wikipedia.org/wiki/General_classification_in_the_Tour_de_France
[bernal]: https://en.wikipedia.org/wiki/Egan_Bernal
[ineos]: https://en.wikipedia.org/wiki/Ineos_Grenadiers
[froome]: https://en.wikipedia.org/wiki/Chris_Froome
[thomas]: https://en.wikipedia.org/wiki/Geraint_Thomas

Another favorite was [Primož Roglič][roglic] who had won last year's [Vuelta a
España][vuelta], taken 4th in a previous Tour, and whose team,
[Jumbo--Visma][jumbo], included a star-studded support roster.

[roglic]: https://en.wikipedia.org/wiki/Primo%C5%BE_Rogli%C4%8D
[vuelta]: https://en.wikipedia.org/wiki/2019_Vuelta_a_Espa%C3%B1a
[jumbo]: https://en.wikipedia.org/wiki/Team_Jumbo%E2%80%93Visma

Here is how the top five riders at the end of the race got there:

[![A line plot showing how far behind the leader each top-finishing rider was
after each stage of the 2020 Tour de France.][gc_plot]][gc_plot]

[gc_plot]: {{ file_dir }}/2020_tour_de_france_top_5.svg

Stage 7 stands out on this plot. Although large time-gaps are normally
happen on mountain finishes, this stage was completely flat. Instead of a
steep climb, strong winds split the [peloton][peloton] in two and several top
riders were stuck in the chasing group where they lost 1′21″.

[peloton]: https://en.wikipedia.org/wiki/Peloton

After leading for most of the race, Roglič lost nearly a minute to [Tadej
Pogačar][pogacar], a young Slovenian riding his first Tour ever, on the
penultimate stage. Roglič had defended the jersey since stage 9, possibly as
part of a strategy to take the jersey early in case the race had to be
canceled midway through.

[pogacar]: https://en.wikipedia.org/wiki/Tadej_Poga%C4%8Dar

But the long defense left Roglič vulnerable. In a ride that caused 17-time
Tour rider [George Hincapie][hincapie] to declare it ["the greatest Tour I have
ever seen"][themove], Pogačar stormed back on [La Planche des Belles Filles][planche],
taking first on the stage by 1′21″. Every other top rider lost time on the
stage as well, even [Richie Porte][porte] who came in third for the stage and
knocked [Miguel Ángel López][lopez] out of the top three overall.

[hincapie]: https://en.wikipedia.org/wiki/George_Hincapie
[themove]: https://wedu.team/themove/2020-tour-de-france-stage-20
[planche]: https://en.wikipedia.org/wiki/La_Planche_des_Belles_Filles
[porte]: https://en.wikipedia.org/wiki/Richie_Porte
[lopez]: https://en.wikipedia.org/wiki/Miguel_%C3%81ngel_L%C3%B3pez_(cyclist)

### Disappointing Results

Many riders set their sights on the yellow jersey but fall short. Crashes,
illness, and simply not being in form drag even top riders down. Here are the
riders who went for the glory but could not keep it up for the full three
weeks:

[![A line plot showing how some of the under-performing riders fell in the
rankings.][under_plot]][under_plot]

[under_plot]: {{ file_dir }}/2020_tour_de_france_underperforming.svg

Notice that the y-axis now extends to over two hours behind the leader, not
the minutes behind in the first chart.

Lopez was on the podium when he started stage 20, but he lost over 6 minutes
in a disastrous time trial, falling to 6th overall.

[Guillaume Martin][martin] finished 11th, his highest ever place, but he had
been in the top three for much of the early race with Bernal and Pogačar. He
lost time during stage 13 after holding strong during the first real test of
the Pyrenees.

[martin]: https://en.wikipedia.org/wiki/Guillaume_Martin

Both Bernal---last years winner---and [Nario Quintana][quintana]---two time
runner up to Chris Froome---defended well in the early mountains but lost time
in the [Massif Central][mc]. They were suffering from injuries in earlier
crashes. In a controversial move, Bernal withdrew from the race after he lost
time, leading some to accuse him of not honoring the historic race. Quintana
fought on, but lost lots of time in the high Alps.

[quintana]: https://en.wikipedia.org/wiki/Nairo_Quintana
[mc]: https://en.wikipedia.org/wiki/Massif_Central

Thibaut Pinot crashed on stage 1 and tumbled out of contention as soon as the race hit
the mountains. [Emanuel Buchmann][buchmann] crashed in a previous race and his
ability to start was in question. Both were found out in the first mountains.

[pinot]: https://en.wikipedia.org/wiki/Thibaut_Pinot
[buchmann]: https://en.wikipedia.org/wiki/Emanuel_Buchmann

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
