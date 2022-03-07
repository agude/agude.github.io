---
layout: post
title: "Gatekeeper Teams of the Overwatch League"
description: >
image: /files/overwatch_league/gate_of_damascus_jerusalem_april_14_1939_by_louis_haghe_and_david_roberts.jpg
hide_lead_image: False
image_alt: >
categories:
  - fun-and-games
---

{% capture file_dir %}/files/overwatch_league/{% endcapture %}

Watching the [Overwatch league][owl] is probably my nerdiest hobby (well after
doing data analysis on the weekend so I can write these posts of course). 

[owl]: https://en.wikipedia.org/wiki/Overwatch_League

Overwatch fans love debating which team each year is the "gatekeeper". The
gatekeeper is the team that beats lower ranked teams, often in a lopsided
fashion, but can't themselves move out of the [midtable][mid]. In this way
they gatekeep the standings: top teams can beat them, bottom teams can't, and
so they define the dividing line between the two groups. 

[mid]: https://en.wiktionary.org/wiki/midtable

Determining which team is the gatekeeper of each season seems like a good
question to answer with data. I can look for a team that is good at beating
low-level competitors, but fails against the top teams.

## Gatekeeper Score

To find the gatekeepers of each season, I need to define some metric to
measure them by. I will use what I call the **gatekeeper score**.

The gatekeeper score is the win percentage against teams that finished
lower in the regular season standings minus the win percentage against teams
that finished higher in the standings. A perfect gatekeeper team, one that
beats all lower ranked teams but loses to all the teams above them, would have
a gatekeeper score of 100 (100% win rate against lower teams minus 0% win rate
against high teams).

This score captures most of what I want, but there are a few problems:

### Undefined Scores

The best and worst team each season have an undefined score because there are
no teams better or worse than them. This is not a big problem because to be a
gatekeeper you must gatekeep someone, and you can't do that at the top or
bottom of the standings.

### High Volatility Near the Top and Bottom

Teams near the top or the bottom of the standings have a small number of
matches used to compute one component of their score. This tends to increase
the volatility of their scores relative to midtable teams that have a lot of
matches counted on either side.

This is a bigger problem because it means that teams near the top and bottom
are more likely to have a high gatekeeper score just because they won or lost
a single match, whereas teams in the middle need to win or lose many matches
to change their score.

I could adjust the score by the number of games, or compute an estimate of the
variance, but for now I will just call out this issue as I run into it.

## The Data

I used two sources of data for this comparison. The first is [a record of the
outcome of every map played][map_stats] from the Overwatch League's Stat Lab.
I transform this data to get match-level[^match] win-loss records for each
team by opponent. You can find that data [here][match_level_data] and the
notebook to parse it is [here][gatekeeper_notebook] ([rendered on
Github][gatekeeper_rendered]).

[match_level_data]: {{ file_dir }}/match_level_data.json

{% capture notebook_gatekeeper_uri %}{{ "OWL Gatekeeper Teams.ipynb" | uri_escape }}{% endcapture %} 
[gatekeeper_notebook]: {{ file_dir }}/{{ notebook_gatekeeper_uri }}
[gatekeeper_rendered]: https://github.com/agude/agude.github.io/blob/master{{ file_dir }}/{{ notebook_gatekeeper_uri }}

[^match]: A match consists of multiple maps that are played sequentially. The
          first team to win a specific number of maps wins the match. The
          number of map wins needed is often 3, but occasionally 4 or more for
          tournaments. Some seasons all maps were played out even if one team
          had already clinched the match.

[map_stats]: https://overwatchleague.com/en-us/statslab

The second data source is the regular season standings of all the teams. I
scrape this data from [Liquipedia][liquipedia]. I used the regular season
standings because the final standings are based on a handful of playoff games
while the season standings incorporate many more matches and so provide a more
accurate estimate of a team's performance. The parsed standings data is
[here][standings_data]. The code to generate the data frame is
[here][parser_notebook] ([rendered on Github][parser_rendered]).

[liquipedia]: https://liquipedia.net/overwatch/Overwatch_League 
[standings_data]: {{ file_dir }}/owl_standings.json

{% capture notebook_parser_uri %}{{ "OWL Gatekeeper Teams.ipynb" | uri_escape }}{% endcapture %} 
[parser_notebook]: {{ file_dir }}/{{ notebook_parser_uri }}
[parser_rendered]: https://github.com/agude/agude.github.io/blob/master{{ file_dir }}/{{ notebook_parser_uri }}

To compute the gatekeeper score I used both regular season and tournament
games, primarily because the dataset does not separate them and I don't want
to go label them by hand.

The final, combined data frame, can be found [here][combined_data]. The
notebook to read it is [here][gatekeeper_notebook] ([rendered on
Github][gatekeeper_rendered]).

[combined_data]: {{ file_dir }}/combined_standings_data.json

## The Gatekeepers

Here are the gatekeeper scores for each season and region. The tables are
ordered according to the regular season ranking. I have highlighted teams I
think could rightfully be called gatekeepers.

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
bottom of the rankings by the **team with the** [**worst losing
streak**][streak] **in professional sports history:** the [0-40 Shanghai
Dragons][2018_dragons].

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

The 2019 season added eight teams to the league and was dominated by the
highly-technical [GOATS meta][goats] in which teams played three tanks and
three supports. During this meta, teams were forced to rigorously track their
opponents ability usage and perfectly time their own in order to win fights.
The Vancouver Titans, the San Francisco Shock, and to a lesser extent the New
York Excelsior mastered this style of play and dominated the league while many
other teams failed to achieve the high-level of coordination required and sunk
down in the rankings.

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
playoff games against the eventual champions the San Francisco Shock. But the
Spark made up for it with a 75% win rate against worse teams. 

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
reason I have split the comparison in two and look at the North American and
Asian regions separately.

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
advance by beating teams ahead of them. You can see it in their stats: the
Reign have an 85% win rate against lower ranked teams---the third highest in
the league behind the eventual champions the Shock and Washington who only had
team below them---but just an 18% win rate against higher ranked teams. 

[2020_reign]: https://en.wikipedia.org/wiki/2020_Atlanta_Reign_season

However, I think the [2020 Dallas Fuel][2020_fuel] are the true gatekeepers of
the league. They had almost as high a win rate against worse teams at 83%, but
a much lower win rate against better teams at 7%---the lowest in the league
that year!

[2020_fuel]: https://en.wikipedia.org/wiki/2020_Dallas_Fuel_season

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

There were two facts in the 2020 Asian region: the Shanghai Dragons were the
best team in the region by a mile, and the London[^london] Spitfire were the
worst by a wide margin.

Amongst the remaining teams, the [2020 Hangzhou Spark][2020_spark] look like a
good candidate for the gatekeepers. They beat lower ranked teams
67% of the time, but only managing 17% against better teams, and they finished
exactly in the middle of the pack in the standings.

[2020_spark]: https://en.wikipedia.org/wiki/2020_Hangzhou_Spark_season

[^london]: I know London is not in Asia, and neither is New York, but during
           the pandemic these teams decided to move to Korea for safety.

## 2021 Season

The 2021 season was again split into two regions due to COVID, but there was a
lot more cross-play between the regions as each of the four tournaments and
the playoffs included teams from both regions. Still, I only look at the
record against teams within the region as that is how regular season standings
were determined.

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
majority of the players had been called up from the Spitfire's academy team
the [British Hurricane][hurricane] who had gone 12-0 and won the 2020
Overwatch Contenders season (Overwatch's minor league). But they floundered in
the Overwatch league, barely scrapping together a 1-15 season. They got their
only win in the infamous [Bread Bowl][breadstick_bowl] against the 1-15
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
gatekeepers of the North American region. They had a typical middle of the
pack season: finishing 7 out of 12 in the West, a 9-7 match record, and a
perfectly balance map record with 32 wins and 32 losses. To round it out, they
had an 82% win rate against worse teams and just a 20% win rate against better
teams.

[2021_defiant]: https://en.wikipedia.org/wiki/2021_Toronto_Defiant_season

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

The [2021 Guangzhou Charge][2021_charge] have the highest gatekeeper score,
but it is, once again, [due to only having a single team below
them][volatility]: the winless [2021 Los Angles Valiant][2021_valiant]. So
I do not think they're a good choice for gatekeepers.

[2021_charge]: https://en.wikipedia.org/wiki/2021_Guangzhou_Charge_season
[2021_valiant]: https://en.wikipedia.org/wiki/2021_Los_Angeles_Valiant_season

Instead, I would choose the [2021 Seoul Dynasty][2021_dynasty], who had a
similarly bad win rate against better teams (22% for Dynasty, 21% for
Charge), but who earn their 85% win rate against lower ranked teams honestly
by beating teams that have actually won games, like the 10 and 10 [2021
Philadelphia Fusion][2021_fusion].

[2021_dynasty]: https://en.wikipedia.org/wiki/2021_Seoul_Dynasty_season
[2021_fusion]: https://en.wikipedia.org/wiki/2021_Philadelphia_Fusion_season
