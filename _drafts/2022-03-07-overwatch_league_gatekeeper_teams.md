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

Watching the [Overwatch league][owl] is probably my nerdiest hobby (well after
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
no teams better or worse than them. This is not a big problem because to be a
gatekeeper you must gatekeep someone, and you can't do that at the top or
bottom of the standings.

### High Volatility Near the Top and Bottom

Teams near the top or the bottom of the standings have only a smaller number
of matches used to compute one component of their score. This tends to
increase the volatility of their scores relative to midtable teams that have a
lot of matches counted on either side.

This is a bigger problem because it means that teams near the top and bottom
are more likely to have a high gatekeeper score just because they won or lost
a single match, whereas teams in the middle need to win or lose a bunch of
matches to change their score.

I could adjust the score by the number of games, or compute an estimate on the
variance, but for now I will just call out this issue as we run into it.

## The Data

I use two sources of data for this comparison. The first is [a record of the
outcome of every map played][map_stats] from the Overwatch League's Stat Lab.
I transform this data to get match-level[^match] win-loss records for each team by
opponent.

[^match]: A match consists of multiple maps that are played sequentially. The
          first team to win a specific number of maps wins the match. The
          number of map wins needed is often 3, but occasionally 4 or more for
          tournaments. Some seasons all maps were played out even if one team
          had already clinched the match.

[map_stats]: https://assets.blz-contentstack.com/v3/assets/blt321317473c90505c/blt4c7ee43fcc7a63c2/61537dcd1bb8c23cf8bbde70/match_map_stats.zip

The second data source is the standings of all teams by season as determined
at the end of the regular season. I scrape this from [Liquipedia][liquipedia].
I use the regular season standings instead of the final standings because
final standings are based on a handful of playoff games while the season
standings incorporate many more matches and so provide a more accurate
estimate of a team's performance.

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
worse uniform. They went 7-33 in the inaugural season and were saved from the
bottom of the rankings by the _team with the_ [_worst losing streak_][streak]
_in professional sports history:_ the [0-40 Shanghai Dragons][2018_dragons].
The Mayhem went 3-0 against the Dragons for a 100% win rate against worse
teams, and 4-33 against better teams giving them an impressively bad 11% win
rate. Combining those rates yields a gatekeeper score of 89!

[streak]: https://www.espn.com/esports/story/_/id/25535277/espn-esports-awards-2018-why-shanghai-dragons-0-40-record-espn-biggest-disappointment-year
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
three supports. During this meta teams were forced to rigorously track their
opponents ability usage and perfectly time their own in order to win fights.
Teams like Vancouver, San Francisco, and New York mastered this style and
dominated the league while many others failed to achieve the high-level of
coordination required and sunk down in the rankings.

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

Once again a bottom-ranked team has the highest score and for the same reason:
[volatility][volatility]. The [2019 Washington Justice][2019_justice] went 4-0
against Boston and Florida and 4-20 against better teams.

[2019_justice]: https://en.wikipedia.org/wiki/2019_Washington_Justice_season

More interesting are the [2019 Hangzhou Spark][2019_spark], who placed fourth.
They lost every game against the top three teams, going 0-7, including 2 lost
playoff games against the eventual champions the San Francisco Shock. But they
made up for it with a 75% win rate against worse teams. 

[2019_spark]: https://en.wikipedia.org/wiki/2019_Hangzhou_Spark_season

What feels right about the highly-ranked Spark being the gatekeepers is it
follows the storyline of the 2019 season: that the Vancouver Titans and the
San Francisco Shock were a tier above everyone else in the GOATS meta, that
only a few other top teams were able to execute the GOATS composition with
enough coordination (among them New York), and that everyone else floundered
trying to play a meta they did not have the skill to.

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

The [2020 Atlanta Reign][2020_reign] were the first time I remember a team
specifically being referred to as a gatekeeper. They had flashy, lopsided
games against teams below them in the standings, but constantly failed to
advance by beating teams ahead of them. You can see it in their stats: The
Reign have an 85% win rate against lower ranked teams---the third highest in
the league behind the eventual champions the Shock and Washington who only had
team below them---but just an 18% win rate against higher ranked teams. 

[2020_reign]: https://en.wikipedia.org/wiki/2020_Atlanta_Reign_season

However, I think the [2020 Dallas Fuel][2020_fuel] are the true gatekeepers of
the league. They had almost as high a win rate against worse teams at 83%, but
a much lower win rate against better teams at 7%---the lowest in the league
that year!

[2020_fuel]: https://en.wikipedia.org/wiki/2020_Dallas_Fuel_season

<!-- TODO: Look at "win quality"? Did Atlanta win more blowouts against lower
teams? Or maybe that's another post? -->

#### Asia

| Team                   |   Gatekeeper Score |
|:-----------------------|-------------------:|
| Shanghai Dragons       |                --- |
| Guangzhou Charge       |                 40 |
| New York Excelsior     |                 38 |
| **Hangzhou Spark**     |             **50** |
| Seoul Dynasty          |                 32 |
| Chengdu Hunters        |                 23 |
| London Spitfire        |                --- |

The Asian region in 2020 had two truisms: the Shanghai Dragons beat everyone,
and the London[^london] Spitfire lost to everyone. The [2020 Hangzhou
Spark][2020_spark] look like a good candidate for the gatekeepers of the
region, beating lower ranked teams 67% of the time, but only managing 17%
against better teams.

[2020_spark]: https://en.wikipedia.org/wiki/2020_Hangzhou_Spark_season

[^london]: I know London is not in Asia, and neither is New York, but during
           the pandemic some teams decided to move to Korea for safety.

## 2021 Season

The 2021 season was again split into two regions due to COVID, but there was a
lot more cross-play between the regions as each of the four tournaments and
the playoffs included teams from both regions. Still, I only look at the
record against teams within the region as that is how regular season standings
were determined.

<!-- TODO: Points also determine standing in 2020 and 20201 -->

### North America

| Team                       |   Gatekeeper Score |
|:---------------------------|-------------------:|
| Dallas Fuel                |                --- |
| **Los Angeles Gladiators** |             **70** |
| Atlanta Reign              |                 32 |
| San Francisco Shock        |                 43 |
| Houston Outlaws            |                 47 |
| Washington Justice         |                 39 |
| **Toronto Defiant**        |             **62** |
| Paris Eternal              |                 46 |
| Boston Uprising            |                 31 |
| Florida Mayhem             |                 69 |
| **London Spitfire**        |            **100** |
| Vancouver Titans           |                --- |


The [2021 London Spitfire][2021_spitfire] were a disappointing team. The
majority of the team had been called up from the Spitfire's academy team the
[British Hurricane][hurricane] who had gone 12-0 and won the 2020
Overwatch Contenders season (Overwatch's minor league). But they floundered in
Overwatch league, barely scrapping together a 1-15 season. They got their only
win in the infamous [Bread Bowl][breadstick_bowl] against the also 1-15
[Vancouver Titans][2021_titans]. That gave the Spitfire a 1-0 record against
lower ranked teams and a 0-15 record against higher ranked teams, resulting in
a perfect 100 point gatekeeper score.

[2021_spitfire]: https://en.wikipedia.org/wiki/2021_London_Spitfire_season
[hurricane]: https://en.wikipedia.org/wiki/British_Hurricane
[breadstick_bowl]: https://overwatchleague.com/en-us/match/37333
[2021_titans]: https://en.wikipedia.org/wiki/2021_Vancouver_Titans_season

Of course a one-win team isn't a gatekeeper, despite what the score says.
Likewise it's hard to call the [2021 Los Angeles Gladiators][2021_gladiators]
gatekeeper because their 0% win rate against higher ranked teams (just the
[Dallas Fuel][2021_fuel]) represents only two games.

[2021_gladiators]: https://en.wikipedia.org/wiki/2021_Los_Angeles_Gladiators_season
[2021_fuel]: https://en.wikipedia.org/wiki/2021_Dallas_Fuel_season

For that reason, I think the [2021 Toronto Defiant][2021_defiant] are the
gatekeepers of the North American Region. <!-- TODO: What's their record? -->

### Asia

| Team                   |   Gatekeeper Score |
|:-----------------------|-------------------:|
| Shanghai Dragons       |                --- |
| Chengdu Hunters        |                 53 |
| **Seoul Dynasty**      |             **62** |
| Philadelphia Fusion    |                 40 |
| Hangzhou Spark         |                 42 |
| New York Excelsior     |                 27 |
| **Guangzhou Charge**   |             **79** |
| Los Angeles Valiant    |                --- |

