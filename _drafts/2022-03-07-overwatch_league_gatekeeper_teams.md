---
layout: post
title: "Gatekeeper Teams of the Overwatch League"
description: >
image: /files/tour-de-france/tour_de_france_1932_swiss_team.jpg
hide_lead_image: True
image_alt: >
categories:
  - fun-and-games
---

{% capture file_dir %}/files/tour-de-france/{% endcapture %}

Watching the [Overwatch league][owl] is probably my nerdiest hobby (after
doing data analysis on the weekend and writing these posts of course). 

[owl]: https://en.wikipedia.org/wiki/Overwatch_League

Overwatch fans love debating which team each year is the "gatekeeper". The
gatekeeper is the team that beats lower ranked teams, often in a lopsided
fashion, but can't themselves move out of the [midtable][mid]. In this way
they gatekeep the standings: top teams can beat them, bottom teams can't, and
so they define the dividing line between the two groups. 

[mid]: https://en.wiktionary.org/wiki/midtable

Determining which team is the gatekeeper of each season seems like a good
question to answer with data. We can look for a team that is good at beating
low-level competitors, but fails against the top teams.

## Gatekeeper Score

To find the gatekeepers of each season, we need to define some metric to
measure them by. I will use what I call the **gatekeeper score**.

The gatekeeper score is the win percentage against teams that finished
lower in the regular season standings minus the win percentage against teams
that finished higher in the standings. A perfect gatekeeper team, one that
beats all lower ranked teams but loses to all the teams above them, would have
a gatekeeper score of 100 (100% win rate against lower teams minus 0% win rate
against high teams).

There are a few problems with this score:

### Undefined Scores

The best and worst team each season have an undefined score because there are
no teams better or worse than them. This is a small problem because to be a
gatekeeper you must gatekeep someone, and you can't do that at the top or
bottom of the standings.

### High Volatility Near the Top and Bottom

Teams near the top or the bottom of the standings have only a smaller number
of matches used to compute one part of their score. This tends to increase the
volatility of their scores relative to midtable teams that have a lot of
matches counted on either side of their score.

This is a bigger problem because it means that teams near the top and bottom
are more likely to have a high gatekeeper score just because they won or lost
a single match, whereas teams in the middle need to win or lose a bunch of
matches to change their score.

I could adjust the score by the number of games, or put an estimate on the
variance, but for now I will just call out this issue as we run into it.

## The Data

I use two sources of data for this comparison. The first is [a record of the
outcome of every map played][map_stats] from the Overwatch League's Stat Lab.
I transform this data to get match-level win-loss records for each team by
opponent.

[map_stats]: https://assets.blz-contentstack.com/v3/assets/blt321317473c90505c/blt4c7ee43fcc7a63c2/61537dcd1bb8c23cf8bbde70/match_map_stats.zip

The second data source is the standings of all teams by season as determined
at the end of the regular season. I scrape this from [Liquipedia][liquipedia].
The reason I use the regular season standings instead of the final standings
are final standings are based on a handful of playoff games while the season
standings incorporate many more matches and so should be a more accurate
estimate of a teams performance level.

[liquipedia]: https://liquipedia.net/overwatch/Overwatch_League 

To compute the gatekeeper score I use both regular season and tournament
games, primarily because the dataset does not separate them and I don't want
to go label them by hand.

<!-- TODO: Link to notebooks and data -->

## The Gatekeepers

Here are the gatekeeper scores for each season and region. The tables are
ordered according to the regular season ranking. I have highlighted teams I
think could rightfully be called "gatekeepers".

### 2018 Season

| Team                   |    Gatekeeper Score |
|------------------------|--------------------:|
| New York Excelsior     |                 --- |
| Los Angeles Valiant    |                  28 |
| Boston Uprising        |                   8 |
| Los Angeles Gladiators |                  56 |
| London Spitfire        |                  23 |
| Philadelphia Fusion    |                  33 |
| Houston Outlaws        |                  28 |
| **Seoul Dynasty**      |              **61** |
| San Francisco Shock    |                  54 |
| Dallas Fuel            |                  51 |
| **Florida Mayhem**     |              **89** |
| Shanghai Dragons       |                 --- |

[2018_dragons]: https://en.wikipedia.org/wiki/2018_Shanghai_Dragons_season

The [2018 Florida Mayhem][2018_florida] were a bad team with a possibly even
worse uniform. They went 7-33 in the inaugural season and were only saved from
the bottom of the rankings only by the _worst team in professional sports
history:_ the [0-40 Shanghai Dragons][2018_dragons]. The Mayhem went 3-0
against the Dragons giving them a 100% win rate against worse teams, and 4-33
against better teams giving them an impressive 11% win rate, which combine to
give them a gatekeeper score of 89!

[2018_florida]: https://en.wikipedia.org/wiki/2018_Florida_Mayhem_season
[2018_dragons]: https://en.wikipedia.org/wiki/2018_Shanghai_Dragons_season

But are they the gatekeeper? They run into the [volatility problem I described
above][volatility]: 3 wins against the Dragons got them 100 points and 4 wins
against better teams lost them only 11.

[volatility]: #high-volatility-near-the-top-and-bottom 

I think the [2018 Seoul Dynasty][2018_seoul] are a better candidate for the
gatekeeper team. They went 22-18, solidly middle-of-the-pack, and they have a
93% win rate against lower ranked teams with only a 32% win rate against
higher rated teams. They are also the first team with a positive win rate and
map differential as you work your way up from the bottom.

[2018_seoul]: https://en.wikipedia.org/wiki/2018_Seoul_Dynasty_season

### 2019 Season

The 2019 season added 8 teams to the league and was dominated by the
highly-technical [GOATS meta][goats] in which teams played three tanks and
three supports and were forced to rigorously track ability usage.

[goats]: https://thegamehaus.com/overwatch/a-comprehensive-history-of-overwatch-metas-part-15-goats/2020/02/06/

| Team                   |   Gatekeeper Score |
|:-----------------------|-------------------:|
| Vancouver Titans       |                --- |
| San Francisco Shock    |                 24 |
| New York Excelsior     |                 56 |
| **Hangzhou Spark**     |             **75** |
| Los Angeles Gladiators |                 44 |
| Atlanta Reign          |                 12 |
| London Spitfire        |                 39 |
| Seoul Dynasty          |                 47 |
| Guangzhou Charge       |                 46 |
| Philadelphia Fusion    |                 28 |
| Shanghai Dragons       |                 13 |
| Chengdu Hunters        |                 38 |
| Los Angeles Valiant    |                 26 |
| Paris Eternal          |                 25 |
| Dallas Fuel            |                 55 |
| Houston Outlaws        |                 26 |
| Toronto Defiant        |                  7 |
| **Washington Justice** |             **83** |
| Boston Uprising        |                 24 |
| Florida Mayhem         |                --- |

Once again a bottom-ranked team has the highest score and for the [same
reason][volatility]. The [2019 Washington Justice][2019_justice] went 4-0
against Boston and Florida and 4-20 against better teams.

[2019_justice]: https://en.wikipedia.org/wiki/2019_Washington_Justice_season

More interesting are the [2019 Hangzhou Spark][2019_spark], who placed fourth.
They lost every game against the top three teams, going 0-7, including 2 lost
playoff games against the eventual champions the Shock. They made up for it
with a 75% win rate against worse teams. 

[2019_spark]: https://en.wikipedia.org/wiki/2019_Hangzhou_Spark_season

What feels right about the Spark being the gatekeepers is it follows the
storyline of the 2019 season: that the Titans and the Shock were a tier above
everyone else in GOATS with only New York Excelsior being able to compete.


### 2020 Season

The 2020 Overwatch League season was split into two regions with very few
games played between them due to the [2020 COVID pandemic][pandemic]. For that
reason I have split the comparison in two and look at the North America and
Asia regions separately.

[pandemic]: https://en.wikipedia.org/wiki/COVID-19_pandemic

#### North America

| Team                   |   Gatekeeper Score |
|:-----------------------|-------------------:|
| Philadelphia Fusion    |                --- |
| San Francisco Shock    |                 14 |
| Paris Eternal          |                 31 |
| Florida Mayhem         |                 41 |
| Los Angeles Valiant    |                 15 |
| Los Angeles Gladiators |                 50 |
| **Atlanta Reign**      |             **67** |
| **Dallas Fuel**        |             **77** |
| Toronto Defiant        |                 62 |
| Houston Outlaws        |                  6 |
| Vancouver Titans       |                 39 |
| Washington Justice     |                 69 |
| Boston Uprising        |                --- |

#### Asia

| Team                   |   Gatekeeper Score |
|:-----------------------|-------------------:|
| Shanghai Dragons       |                --- |
| Guangzhou Charge       |                 40 |
| New York Excelsior     |                 38 |
| Hangzhou Spark         |                 50 |
| Seoul Dynasty          |                 32 |
| Chengdu Hunters        |                 23 |
| London Spitfire        |                --- |


## 2021 Season

### North America

| Team                   |   Gatekeeper Score |
|:-----------------------|-------------------:|
| Dallas Fuel            |                --- |
| Los Angeles Gladiators |                 70 |
| Atlanta Reign          |                 32 |
| San Francisco Shock    |                 43 |
| Houston Outlaws        |                 47 |
| Washington Justice     |                 39 |
| Toronto Defiant        |                 62 |
| Paris Eternal          |                 46 |
| Boston Uprising        |                 31 |
| Florida Mayhem         |                 69 |
| London Spitfire        |                100 |
| Vancouver Titans       |                --- |

[breadstick_bowl]: https://overwatchleague.com/en-us/match/37333

### Asia

| Team                   |   Gatekeeper Score |
|:-----------------------|-------------------:|
| Shanghai Dragons       |                --- |
| Chengdu Hunters        |                 53 |
| Seoul Dynasty          |                 62 |
| Philadelphia Fusion    |                 40 |
| Hangzhou Spark         |                 42 |
| New York Excelsior     |                 27 |
| Guangzhou Charge       |                 79 |
| Los Angeles Valiant    |                --- |

