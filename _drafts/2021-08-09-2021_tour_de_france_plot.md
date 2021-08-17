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
year. The start date was shifted back slightly to avoid overlapping with the
[rescheduled 2020 Summer Olympics][olympics], but the race was otherwise
unaffected by the [ongoing COVID pandemic][covid] which forced the
postponement of last year's race. In this post, just like [last
year's][last_post], I plot how the race unfolded.

[tour]: https://en.wikipedia.org/wiki/2021_Tour_de_France
[olympics]: https://en.wikipedia.org/wiki/2020_Summer_Olympics
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
winner of last year's race, was the clear favorite this year.

[yellow]: https://en.wikipedia.org/wiki/General_classification_in_the_Tour_de_France
[pogacar]: https://en.wikipedia.org/wiki/Tadej_Poga%C4%8Dar

[^young]: 
    Pogačar is the second youngest winner of the Tour at 21, with only [Henri
    Cornet][cornet]--the winner of the 1904 edition of the Tour--having won
    just 10 days short of 20.

[cornet]: https://en.wikipedia.org/wiki/Henri_Cornet

[Primož Roglič][roglic] was again a favorite, having [taking second place in
last year's Tour][last_post] and gone on to defend his title in the [Vuelta a
España][vuelta].

[roglic]: https://en.wikipedia.org/wiki/Primo%C5%BE_Rogli%C4%8D
[vuelta]: https://en.wikipedia.org/wiki/2020_Vuelta_a_Espa%C3%B1a

[Ineos Grenadiers][ineos] teammates [Richie Porte][porte], [Geraint
Thomas][thomas], and [Richard Carapaz][carapaz] were also in the running.
Porte had won the [Critérium du Dauphiné][cdd]---considered a warm-up race for
the Tour used to test a rider's form---and Thomas had placed third in the
Critérium and was the 2018 Tour winner. Carapaz had won the [Tour de
Suisse][tds] the other Tour warm-up race.

[ineos]: https://en.wikipedia.org/wiki/Ineos_Grenadiers
[porte]: https://en.wikipedia.org/wiki/Richie_Porte
[thomas]: https://en.wikipedia.org/wiki/Geraint_Thomas
[carapaz]: https://en.wikipedia.org/wiki/Richard_Carapaz
[cdd]: https://en.wikipedia.org/wiki/2021_Crit%C3%A9rium_du_Dauphin%C3%A9
[tds]: https://en.wikipedia.org/wiki/2021_Tour_de_Suisse

The race for yellow turned out to be far less exciting than last year,
indicated by the large time gap that formed early in the race:

[![A line plot showing how far behind the leader each top-finishing rider was
after each stage of the 2020 Tour de France.][gc_plot]][gc_plot]

[gc_plot]: {{ file_dir }}/2021_tour_de_france_top_5.svg

Pogačar only faltered on stage 7 as the race entered the Alps. He dropped to
almost four minutes behind [Mathieu van der Poel][mvdp] and three and half
minutes behind [Wout van Aert][wva],[^cyclocross] but
stormed back on stage 8 to take the lead, which he maintained for the rest of
the race.

[mvdp]: https://en.wikipedia.org/wiki/Mathieu_van_der_Poel
[wva]: https://en.wikipedia.org/wiki/Wout_van_Aert
[^cyclocross]:
    Van der Poel and van Aert are an exciting pair to watch! They got their
    start dominating [cyclo-cross][cross], where their only real competition
    was each other. Van der Poel has won four of the last seven Cyclo-cross World
    Championships, and van Aert has won the other three. Both have continued their
    domination---and rivalry---on the road in the last few years.

[cross]: https://en.wikipedia.org/wiki/Cyclo-cross

[Ben O'Connor][oconnor] attempted to contest Pogačar's lead in stage 9 with a
solo break away win but fell two minutes short and putting him in second
place. He wasn't able to hold his form and eventually placed forth after
losing time in the Pyrenees.

[oconnor]: https://en.wikipedia.org/wiki/Ben_O%27Connor_(cyclist)

### The Green Jersey

Although the race for yellow was unexciting, the race for the [green
jersey][green]---awarded based on points earned for intermediate sprints and
stage wins---was incredibly exciting. [Mark Cavendish][cav], considered by
some to be the greatest sprinter ever, entered the race having won 30 stages
of the Tour, just [four behind][most_stage_wins] all-time great [Eddy
Merckx][merckx]. But Cavendish had not won a Tour sprint since 2016 or any stage
since 2018 and was considered well past his prime. However in early 2021 he
showed a return to his winning form with dominate sprints in the [Tour of
Turkey][tot], which raised the possibility of him beating Merckx's record.

[green]: https://en.wikipedia.org/wiki/Points_classification_in_the_Tour_de_France
[cav]: https://en.wikipedia.org/wiki/Mark_Cavendish
[most_stage_wins]: https://en.wikipedia.org/wiki/Tour_de_France_records_and_statistics#Stage_wins_per_rider
[merckx]: https://en.wikipedia.org/wiki/Eddy_Merckx
[tot]: https://en.wikipedia.org/wiki/2021_Presidential_Tour_of_Turkey



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
