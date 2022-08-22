---
layout: post
title: "Plotting the 2022 Tour de France"
description: >
  The 2022 Tour de France saw a new winner, Jonas Vingegaard! See how he won
  in this post!
image: /files/tour-de-france/tour_de_france_1932_italian_team.jpg
hide_lead_image: True
image_alt: >
  A black and white photo of the Italian team in the 1932 Tour de France.
categories:
  - cycling
  - data-visualization
---

{% capture file_dir %}/files/tour-de-france/{% endcapture %}

The 109th edition of the [Tour de France][tour] just wrapped up. It was the
first edition in several years that felt almost normal---the 2020 edition had
been delayed by [COVID][covid] and 2021 edition moved to avoid the
[Olympics][olympics].

[Like last year][last_post], let's explore who the race unfolded with data.

[tour]: https://en.wikipedia.org/wiki/2022_Tour_de_France
[olympics]: https://en.wikipedia.org/wiki/2020_Summer_Olympics
[covid]: https://en.wikipedia.org/wiki/COVID-19_pandemic
[last_post]: {% post_url 2021-08-18-2021_tour_de_france_plot %}

The code that generated the plots can be found [here][plot_code]
([rendered on Github][rendered]). The data [is here][data].

{% capture notebook_uri %}{{ "Tour de France 2021 Plot.ipynb" | uri_escape }}{% endcapture %}
[plot_code]: {{ file_dir }}/{{ notebook_uri }}
[rendered]: https://github.com/agude/agude.github.io/blob/master{{ file_dir }}/{{ notebook_uri }}
[data]: {{ file_dir }}/2021-tdf-dataframe.json

## The Race for Yellow

The [yellow jersey][yellow], which is awarded to the rider with the lowest
combined time across the 21 stages of the race, was won by [Tadej
Pogačar][pogacar] the past two years, so he was the favorite going into this
tour.

[yellow]: https://en.wikipedia.org/wiki/General_classification_in_the_Tour_de_France
[pogacar]: https://en.wikipedia.org/wiki/Tadej_Poga%C4%8Dar

Other favorites this year were:

- **[Primož Roglič][roglic]**, who came in second in 2020.
- **[Jonas Vingegaard][vingegaard]**, who came in second last year.
- **[Geraint Thomas][thomas]**, who won won in 2018 and finished second in 2019.
- **[Aleksandr Vlasov][vlasov]**, who won the Tour de Romandie earlier in the year.
- **[Daniel Martínez][martinez]**, who won the Tour of the Basque Country
  earlier in the year.

[roglic]: https://en.wikipedia.org/wiki/Primo%C5%BE_Rogli%C4%8D
[thomas]: https://en.wikipedia.org/wiki/Geraint_Thomas
[vingegaard]: https://en.wikipedia.org/wiki/Jonas_Vingegaard
[vlasov]: https://en.wikipedia.org/wiki/Aleksandr_Vlasov_(cyclist)
[martinez]: https://en.wikipedia.org/wiki/Daniel_Mart%C3%ADnez_(cyclist)

Pogačar started strong, taking the yellow Jersey on stage 6 after beating out
Vingegaard in the final sprint. He held it through the first few Alp stages
before getting isolated on stage 11. Roglič and Vingegaard, both riding for
team [Jumbo-Visma][jumbo], force Pogačar to chase them, pulling him away from
his supporting teammates. The duo then threw attack after attack at the yellow
jersey, forcing him to constantly accelerate. By the time they got to the
final climb on the [Col du Galibier][col], Pogačar was so tired that
Vingegaard was able to drop him and gain nearly three minutes, taking the
yellow jersey.

[jumbo]: https://en.wikipedia.org/wiki/Daniel_Mart%C3%ADnez_(cyclist)
[col]: https://en.wikipedia.org/wiki/Col_du_Galibier

[![A line plot showing how far behind the leader each top-finishing rider was
after each stage of the 2022 Tour de France.][gc_plot]][gc_plot]

[gc_plot]: {{ file_dir }}/2022_tour_de_france_top_5.svg

Pogačar and Thomas stayed neck-and-neck until stage 16 when Vingegaard and
Pogačar attacked in the Pyrenees and dropped the other contenders.

## The Rest of the Race

176 riders started the race and just 136 finished, the lowest number to finish
since 2000. Here is how each rider fared:

[![A line plot showing how far behind the leader every rider was for each
stage.][full_plot]][full_plot]

[full_plot]: {{ file_dir }}/2022_tour_de_france.svg

The green jersey, awarded for winning the most sprint points, was taken by
[Wout van Aert][van aert] with a modern-era record setting 480 points. He
paced himself well, finishing solidly in the middle of the pack. Last year the
green jersey winner [Mark Cavendish][cavendish] finished near the bottom in
2021 because he was a much weaker climber than van Aert.

[van aert]: https://en.wikipedia.org/wiki/Wout_van_Aert
[cavendish]: https://en.wikipedia.org/wiki/Mark_Cavendish

Another sprinter, [Caleb Ewan][ewan], got the [lanterne rougue][lanterne], a
prize awarded to the last place rider. Normally a strong contender, he crashed
hard on stage 13 and struggled to stay with the other riders, but still
managed to cross the finish line in Paris.

[ewan]: https://en.wikipedia.org/wiki/Caleb_Ewan
[lanterne]: https://en.wikipedia.org/wiki/Lanterne_rouge

Pre-race hopeful Primož Roglič crashed and dislocated his should on stage 5.
He held on for 10 days---thankfully for Vingegaard who used Roglič to weaken
Pogačar on stage 11---but dropped out during stage 15.
