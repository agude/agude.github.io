---
layout: post
title: "Plotting the 2021 Tour de France"
description: >
  The 2021 Tour de France turned out much differently from last year's
  edition! See exactly how it unfolded in this post.
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
unaffected by the [ongoing COVID pandemic][covid] which had forced the
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
    Pogačar is the second youngest winner of the Tour at 21. [Henri
    Cornet][cornet] is the youngest winner at just 10 days shy of 20 when he
    won the 1904 edition.

[cornet]: https://en.wikipedia.org/wiki/Henri_Cornet

[Primož Roglič][roglic] was a favorite again after [taking second place in
last year's Tour][last_post]. Since then he had defended his title in one of
the two other grand tours, the [Vuelta a España][vuelta], winning for a second
year in a row.

[roglic]: https://en.wikipedia.org/wiki/Primo%C5%BE_Rogli%C4%8D
[vuelta]: https://en.wikipedia.org/wiki/2020_Vuelta_a_Espa%C3%B1a

[Ineos Grenadiers][ineos] teammates [Richie Porte][porte], [Geraint
Thomas][thomas], and [Richard Carapaz][carapaz] were also in the running.
Porte had won the [Critérium du Dauphiné][cdd]---considered a warm-up race for
the Tour used to test a rider's form---and Thomas had placed third in the
Critérium and was the 2018 Tour winner. Carapaz had just won the [Tour de
Suisse][tds], the other Tour warm-up race, and had won the [Giro
d'Italia][giro] in 2019.

[ineos]: https://en.wikipedia.org/wiki/Ineos_Grenadiers
[porte]: https://en.wikipedia.org/wiki/Richie_Porte
[thomas]: https://en.wikipedia.org/wiki/Geraint_Thomas
[carapaz]: https://en.wikipedia.org/wiki/Richard_Carapaz
[cdd]: https://en.wikipedia.org/wiki/2021_Crit%C3%A9rium_du_Dauphin%C3%A9
[tds]: https://en.wikipedia.org/wiki/2021_Tour_de_Suisse
[giro]: https://en.wikipedia.org/wiki/Giro_d%27Italia

Unfortunately, the race for yellow turned out to be far less exciting than
last year, indicated by the large time gap between Pogačar and the rest of the
field that formed early in the race:

[![A line plot showing how far behind the leader each top-finishing rider was
after each stage of the 2021 Tour de France.][gc_plot]][gc_plot]

[gc_plot]: {{ file_dir }}/2021_tour_de_france_top_5.svg

Pogačar only faltered on stage 7 as the race entered the Alps. He dropped to
four minutes behind current race leader [Mathieu van der Poel][mvdp] and three
and half minutes behind second place [Wout van Aert][wva].[^cyclocross] But
Pogačar stormed back on stage 8 to take the lead, which he maintained for the
rest of the race.

[mvdp]: https://en.wikipedia.org/wiki/Mathieu_van_der_Poel
[wva]: https://en.wikipedia.org/wiki/Wout_van_Aert
[^cyclocross]:
    Van der Poel and van Aert are an exciting pair to watch! They got their
    start dominating [cyclo-cross][cross], where their only real competition
    was each other. Van der Poel has won four of the last seven Cyclo-cross World
    Championships, and van Aert has won the other three. Both have continued their
    domination---and rivalry---on the road in the last few years.

[cross]: https://en.wikipedia.org/wiki/Cyclo-cross

[Ben O'Connor][oconnor] attempted to contest Pogačar's lead on stage 9 with a
solo break away win but fell two minutes short. O'Connor's effort put him in
second place, but he wasn't able to hold his form and eventually placed forth
after losing time in the Pyrenees. By the end of stage 10, Pogačar had an
unassailable lead of almost 6 minutes.

[oconnor]: https://en.wikipedia.org/wiki/Ben_O%27Connor_(cyclist)

### The Green Jersey

Although the race for yellow uneventful, the race for the [green
jersey][green] was incredibly exciting. The green jersey is awarded to the
rider with the most points, which are earned by winning intermediate sprints
and stages.

[Mark Cavendish][cav]---considered by some to be the greatest sprinter
ever[^nostalgia]---entered the race having won 30 stages of the Tour, just
[four behind][most_stage_wins] all-time great [Eddy Merckx][merckx]. But
Cavendish had not won a Tour sprint since 2016 or any stage of any race since
2018\. His performance had fallen so far that he had considered retiring before
the 2021 season. But in early 2021, he showed a return to his winning
form with four dominate sprint wins in the [Tour of Turkey][tot], which
raised the possibility of him beating Merckx's record.

[^nostalgia]:
    Mark Cavendish, or just "Cav" to the fans, is a rider to whom I feel a strong
    connection. He was the sprinter to beat when I first started watching
    cycling and was one of the few riders I was able to recognize and watch
    for in the race. I learned the tactics and tricks of sprinting from
    watching Cav and his leadout train.

    The end of his dominance came at roughly the same time that my interest in
    cycling started to wane. Most of the riders I had come into the sport with
    were leaving the peloton, the teams had all be renamed and many had broken
    up, and my life was becoming busier making following the sport hard.

    But with Cav returning to his old dominance of the sprint this year, I
    felt like I was back in 2013 watching cycling for the first time. It gave
    me a sense of nostalgia and excitement for the sport I hadn't felt for a
    while. I hope the feeling lasts.


[green]: https://en.wikipedia.org/wiki/Points_classification_in_the_Tour_de_France
[cav]: https://en.wikipedia.org/wiki/Mark_Cavendish
[most_stage_wins]: https://en.wikipedia.org/wiki/Tour_de_France_records_and_statistics#Stage_wins_per_rider
[merckx]: https://en.wikipedia.org/wiki/Eddy_Merckx
[tot]: https://en.wikipedia.org/wiki/2021_Presidential_Tour_of_Turkey

Here is how the sprint race turned out, with sprint stages shaded in grey:

[![A line plot showing how far behind the points leader the top five sprint
sprinters were.][sprint_plot]][sprint_plot]

[sprint_plot]: {{ file_dir }}/2021_tour_de_france_top_5_sprint.svg

Cavendish took the lead in the points competition with a win on stage 4. He
extended his lead on stage 6 with another win which brought him up to 32
all-time, just 2 behind Merckx. Cavendish had to survive the Alps in stages 7
and 8 if he wanted another shot at sprint wins. He managed to avoid the time
cuts with the help of his team and went on to win twice more on stages 10 and
13, where second place [Michael Matthews][matthews] falls to his lowest point
before clawing his way back over the next few stages.

[matthews]: https://en.wikipedia.org/wiki/Michael_Matthews_(cyclist)

Cavendish's win on stage 13 tied Merckx's record of 34 tour wins and set him
up to beat the record during the [final sprint of the tour on the
Champs-Élysées][ce_sprint]. Unfortunately it was not to be, Cavendish came in
third on the final sprint behind Wout van Aert and [Jasper
Philipsen][philipsen]. Cavendish may have another chance to beat the record in
2022, but as he is at the tail-end of his career it is not certain he will
make the race.

[ce_sprint]: https://en.wikipedia.org/wiki/Champs-%C3%89lys%C3%A9es_stage_in_the_Tour_de_France
[philipsen]: https://en.wikipedia.org/wiki/Jasper_Philipsen

## The Rest of the Race

184 riders started the race and 141 finished. Here is how each rider fared:

[![A line plot showing how far behind the leader every rider was for each
stage.][full_plot]][full_plot]

[full_plot]: {{ file_dir }}/2021_tour_de_france.svg

Cavendish paced himself in the mountains, finishing with the slowest rider to
save his energy. Cavendish's teammate, [Tim Declercq][declercq], time is
almost identical to Cavendish's for the first 12 stages, as he stayed with
the sprinter to ensure that Cavendish made it in under the time cut. Declercq
was involved in a major crash in stage 13, where he lost almost 15 minutes.
But he held on as other, slower riders dropped out, allowing him take the
[lanterne rougue][lanterne] awarded to the last place rider. 

[declercq]: https://en.wikipedia.org/wiki/Tim_Declercq
[lanterne]: https://en.wikipedia.org/wiki/Lanterne_rouge

Finally, how did the other riders who held the yellow jersey during the race,
[Julian Alaphilippe][alaphilippe] and Mathieu van der Poel, do? Van der Poel
dropped out when they hit the mountains to prepare for the Olympics. Despite
his strength, he is not the type of rider who could have won this tour, being
to heavy to climb quickly. Alaphilippe, although not a climber specialist, can
compete in the mountains as [we saw in the 2019 Tour][2019_tour], but he too
started to lose time in the Alps. He held on and finished in Paris, but far
down the leaderboard.

[alaphilippe]: https://en.wikipedia.org/wiki/Julian_Alaphilippe
[2019_tour]: {% post_url 2019-08-05-2019_tour_de_france_plot %}#the-race-for-yellow

Although this year's competition for the yellow jersey lacked the excitement
of last year's Tour, Mark Cavendish's amazing return to form provided some
rare sprinting tension. Hopefully Cavendish will return next year to attempt
to break Merckx's record!
