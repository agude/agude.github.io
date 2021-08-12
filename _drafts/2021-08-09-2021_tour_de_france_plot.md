---
layout: post
title: "Plotting the 2021 Tour de France"
description: >
  The Tour de France is a race decided by mere minutes; to see
  exactly how those minutes were earned, read on for my plots!
image: /files/tour-de-france/tour_de_france_1932_swiss_team.jpg
hide_lead_image: True
image_alt: >
  A black and white photo of the Swiss team in the 1932 Tour de France.
categories:
  - cycling
  - data-visualization
---

{% capture file_dir %}/files/tour-de-france/{% endcapture %}

The 108th edition of the [Tour de France][tour] started in late June this
year. The race was shifted back slightly to avoid overlapping the Summer
Olympics.

In this post, just like [last year's][last_post], I will use plots to explore how the Tour unfolded.

[tour]: https://en.wikipedia.org/wiki/2020_Tour_de_France
[covid]: https://en.wikipedia.org/wiki/COVID-19_pandemic
[last_post]: {% post_url 2020-10-16-2020_tour_de_france_plot %}

The code that generated the plots can be found [here][plot_code]
([rendered on Github][rendered]). The data [is here][data].

{% capture notebook_uri %}{{ "Tour de France 2021 Plot.ipynb" | uri_escape }}{% endcapture %}
[plot_code]: {{ file_dir }}/{{ notebook_uri }}
[rendered]: https://github.com/agude/agude.github.io/blob/master{{ file_dir }}/{{ notebook_uri }}
[data]: {{ file_dir }}/2021-tdf-dataframe.json

## The Race for Yellow

The top award in the Tour is the [yellow jersey][yellow], which is awarded to
the rider with the lowest combined time across the 21 stages of the race.
[Tadej Pogačar][pogacar], the incredibly young[^young] and surprisingly dominant
winner of last year's race, was the clear favorite.

[yellow]: https://en.wikipedia.org/wiki/General_classification_in_the_Tour_de_France
[pogacar]: https://en.wikipedia.org/wiki/Tadej_Poga%C4%8Dar

[^young]: 
    Pogačar is the second youngest winner of the Tour at 21, with only [Henri
    Cornet][cornet]--the winner of the 1904 edition of the Tour--having won
    just 10 days short of 20.

[cornet]: https://en.wikipedia.org/wiki/Henri_Cornet



[Primož Roglič][roglic] was another favorite. He had won last year's [Vuelta a
España][vuelta], taken 4th in a previous Tour, and his team,
[Jumbo--Visma][jumbo], included a star-studded support roster.

[roglic]: https://en.wikipedia.org/wiki/Primo%C5%BE_Rogli%C4%8D
[vuelta]: https://en.wikipedia.org/wiki/2019_Vuelta_a_Espa%C3%B1a
[jumbo]: https://en.wikipedia.org/wiki/Team_Jumbo%E2%80%93Visma

After three weeks of racing, here is how the top five riders fared through the
stages:

[![A line plot showing how far behind the leader each top-finishing rider was
after each stage of the 2020 Tour de France.][gc_plot]][gc_plot]

[gc_plot]: {{ file_dir }}/2020_tour_de_france_top_5.svg

Stage 7 stands out in this plot. Although large time gaps normally occur
during mountain finishes, this completely flat stage shook up the race for
yellow. Instead of a steep climb, strong winds split the [peloton][peloton] in
two and several top riders were stuck in the chasing group where they lost
1′21″.

[peloton]: https://en.wikipedia.org/wiki/Peloton


But the long defense left Roglič vulnerable. In a ride that caused 17-time
Tour rider [George Hincapie][hincapie] to declare it ["the greatest Tour I
have ever seen"][themove], Pogačar stormed back on [La Planche des Belles
Filles][planche], taking first on the stage by 1′21″. Every other top rider
lost time on the stage as well, even [Richie Porte][porte] who came in third
for the stage and knocked [Miguel Ángel López][lopez] out of the top three
overall.

[hincapie]: https://en.wikipedia.org/wiki/George_Hincapie
[themove]: https://wedu.team/themove/2020-tour-de-france-stage-20
[planche]: https://en.wikipedia.org/wiki/La_Planche_des_Belles_Filles
[porte]: https://en.wikipedia.org/wiki/Richie_Porte
[lopez]: https://en.wikipedia.org/wiki/Miguel_%C3%81ngel_L%C3%B3pez_(cyclist)

### Disappointing Results

Many riders set their sights on the yellow jersey but ultimately fall short.
Crashes, illness, and simply not being in form can drag down even top riders.
Here are the riders who went for the glory but could not keep it up for the
full three weeks:

[![A line plot showing how some of the under-performing riders fell in the
rankings.][under_plot]][under_plot]

[under_plot]: {{ file_dir }}/2020_tour_de_france_underperforming.svg

Notice that the y-axis now extends to over two hours behind the leader, not
the minutes behind in the first chart.

It might be hard to call a top 6 finish a disappointment, but for Lopez is
was. He was on the podium in 3rd place when he started stage 20, but he lost
over 6 minutes in a disastrous time trial.

[Guillaume Martin][martin] finished 11th, his highest ever place, but he had
been in the top three for much of the early race, keeping up with favorites
Bernal and Roglič. He lost time during stage 13 after holding strong during
the first real test in the Pyrenees.

[martin]: https://en.wikipedia.org/wiki/Guillaume_Martin

Both Bernal---last years winner---and [Nario Quintana][quintana]---two time
runner up to Chris Froome---defended well in the early mountains but lost time
in the high [Massif Central][mc]. They were suffering from injuries incurred
during crashes earlier in the race. In a controversial move, Bernal withdrew
from the race after he lost time.[^sportsmanship] Quintana fought on and
finished in Paris, but lost lots of time in the Alps.

[quintana]: https://en.wikipedia.org/wiki/Nairo_Quintana
[mc]: https://en.wikipedia.org/wiki/Massif_Central
[^sportsmanship]: Ineos said Bernal dropped out to "focus on recovery", but many fans felt that Bernal---who had won last year, placed as high as second this year, and worn the [white jersey][white] for the best young rider---was abandoning the most prestigious race of the season to avoid embarrassment at the hands of his opponents. 
[white]: https://en.wikipedia.org/wiki/White_jersey

Thibaut Pinot crashed on stage 1. [Emanuel Buchmann][buchmann] crashed in a
previous race and his ability to start was in question. Both lost time in the
first mountains and never recovered, but nevertheless stayed in the race
through the end.

[pinot]: https://en.wikipedia.org/wiki/Thibaut_Pinot
[buchmann]: https://en.wikipedia.org/wiki/Emanuel_Buchmann

## The Rest of the Race

More than 100 riders finished the Tour, but most of them were not competing
for the yellow jersey. Here are the paths taken by all 146 riders who finished
in Paris:

[![A line plot showing how far behind the leader every rider was for each
stage.][full_plot]][full_plot]

[full_plot]: {{ file_dir }}/2020_tour_de_france.svg

Buchmann, the lowest placed rider in our previous plot, is actually ahead of
most of the riders! We can also see the race started out tough, probably due
to the chance that it might be canceled after the first rest day, with large
time gaps opening up even before the first mountains.

The latter half of the second week was also tough with the hilly Massif
Central and mountainous Alps. By the last few stages, the time gaps were
pretty much set and most riders maintained their relative positions.

Two riders of note are [Peter Sagan][sagan] and [Sam Bennett][bennett], who
were competing for the [green jersey][green]. Both of them saved their energy,
and hence lost time, on mountainous stages so they could give it their all in
the sprints. Even though Sagan finished about an hour ahead of Bennett, he
lost the Jersey. Bennett had done a better job of managing his energy and
using it where it counted.

[bennett]: https://en.wikipedia.org/wiki/Sam_Bennett_(cyclist)
[sagan]: https://en.wikipedia.org/wiki/Peter_Sagan
[green]: https://en.wikipedia.org/wiki/Points_classification_in_the_Tour_de_France
[froome]: https://en.wikipedia.org/wiki/Chris_Froome

Finally, [Roger Kluge][kluge] won the [lanterne rouge][lanterne], finishing
six hours behind Pogačar. His job in the race had been to escort his team's
sprinter, [Caleb Ewan][ewan], through the race. This often meant falling back
on climbs and waiting for Ewan so they could tackle the mountains together and
avoid being cut for being too slow.

[kluge]: https://en.wikipedia.org/wiki/Roger_Kluge
[lanterne]: https://en.wikipedia.org/wiki/Lanterne_rouge
[ewan]: https://en.wikipedia.org/wiki/Caleb_Ewan

This year's Tour was unique due to needing to adjust to the COVID pandemic,
but it turned out to be one of the most exciting races in the history of the
sport! And what's more, it gave us some much-needed entertainment during these
dark time.
