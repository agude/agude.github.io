---
layout: post
title: "Dragon Farkle: Simulating the End Game"
description: >
  How many soldiers do you need to successful defeat the dragon in Dragon
  Farkle, and how likely to succeed is your attack? I find out by simulating a
  game of Dragon Farkle!
image: /files/dragon_farkle/st_george_and_the_dragon.jpg
image_alt: >
  Juliusz Kossak's watercolor painting titled "Saint George Killing the
  Dragon". It shows a man in armor, riding a horse, spearing a dragon on the
  ground with a lance.
redirect_from: /2016/05/30/dragon_farkle/
---

{% capture file_dir %}/files/dragon_farkle{% endcapture %}

{% include lead_image.html %} 
Some of my friends came over last week to play board games and while we ate
dinner we played [Dragon Farkle][dragonfarkle] because it was a simple enough
game to not distract us from the meal. The game involves rolling six normal
six-side dice and a special six-sided die with the following sides: `{0, 0, 0,
0, 1, 2}`. On their turn a player rolls the dice to try to recruit soldiers
for their army by scoring points. They score points by rolling various
combinations on the dice (ignoring the special die, which mainly modifies how
many points are awarded) such as three-of-a-kind, straights, and even solitary
1s and 5s. Dice that are part of a scoring combination are removed and the
remaining dice are rerolled to attempt to score more points. If all the dice
are removed, the player gets six more dice and continues. If no scoring
combinations are present in a roll, the roll is a "farkle" and the turn
generally ends.

[dragonfarkle]: https://www.zmangames.com/en/products/dragon-farkle/

When a player has enough soldiers (5000 is the minimum specified by the rules)
they may forgo recruiting more to instead attack the dragon. When a player
attacks the dragon they roll exactly as they do when trying to recruit, but
instead of gaining soldiers when they roll scoring combination they lose
soldiers. The special die no longer modifies the number of points awarded but
instead damages the dragon. The player's turn can end in one of three ways:

1. The player **wins** the game if dragon takes a total of three damage.
2. The player's turn ends if they roll a farkle *and* roll a 0 on the special
   die. If they roll damage and a farkle they can continue rolling.
3. The player's turn ends if they run out of soldiers.

## How Many Soldiers?

The main tension in the game is between spending turns recruiting, and thereby
improving your chances of killing the dragon, and attacking the dragon so that
you can defeat it before your opponents do. Do you attack now, or wait until
you have more soldiers and have a better shot? So of course, the question came
up while playing: "On average, how many soldiers do I need to win?" Although
you can answer this question with pen and paper, I---being an experimental
physicist at heart---decided to simulate the game in order to answer the
question. The notebook that performs the simulation can be found
[here][notebook] ([rendered on Github][rendered]). The plotting notebook is
[here][plotnotebook] ([rendered on Github][plotrendered]).

{% capture notebook_uri %}{{ "Dragon Farkle Simulation.ipynb" | uri_escape }}{% endcapture %} 
{% capture notebook_plotting_uri %}{{ "Plot Results.ipynb" | uri_escape }}{% endcapture %} 

[notebook]: {{ file_dir }}/{{ notebook_uri }}
[rendered]: https://github.com/agude/agude.github.io/blob/master{{ file_dir }}/{{ notebook_uri }}
[plotnotebook]: {{ file_dir }}/{{ notebook_plotting_uri }}
[plotrendered]: https://github.com/agude/agude.github.io/blob/master{{ file_dir }}/{{ notebook_plotting_uri }}

Let's look at how many soldiers you need, on average, to win the game.
To do so, we'll simulate attacking the dragon and keep track of how many
soldiers are lost before the dragon is defeated. If the player runs out of
soldiers or rolls a farkle we will discard the run. The results are:

[![The average number of soldiers lost during a win.][avg_lost]][avg_lost]

[avg_lost]: {{ file_dir }}/dragon_farkle_soldier_expectation_value.svg

The various peaks are due to the fact that there are always an integer number
of rolls made in a turn and there is a limited set of scores that be earned
with each roll. The mean is 1007 soldiers lost before the dragon is defeated,
which is **far** less than the 5000 soldiers that the rules require you to
have before declaring an attack! This suggests that you will almost never run
out of soldiers when attacking the dragon!

Let's look at exactly how often each of the three end conditions for you turn
are reached. Here we'll fix the number of soldiers you have, simulate a bunch
of turns, and record the outcome for each. The results are:

[![The various outcomes of attacking the dragon as a function of the number of
soldiers.][outcomes]][outcomes]

[outcomes]: {{ file_dir }}/dragon_farkle_combined_probability.svg

If you go into the turn with 5000 soldiers, you will win about 40% of the time
and you will lose by rolling a farkle about 60% of the time. You will lose by
running out of soldiers less than 1% of the time, and that fraction decreases
exponentially in the number of soldiers!

This is a clear failure of game design; once the minimum number of soldiers is
reached getting more has no effect on the outcome. This removes any possible
strategy where the player might trade time---and hence chances for their
opponents to win---for a higher likely of succeeding with their own attacks.
Instead, the only correct strategy is to attack as soon as you can, and keep
doing it as often as you can until you win.
