---
layout: post
title: "Python Patterns: Enum"
description: >
  Things the real world often come in sets of specific items, like countries,
  states, or playing cards. You can assign each item an integer, but Python
  has a more elegant way.
image: /files/patterns/locupletissimi_rerum_naturalium_thesauri_v1_lxxxiii_snake.png
image_alt: >
  A drawing of a red and white snake taken from Plate LXXXIII from
  Locupletissimi rerum naturalium thesauri volume 1.
categories: python_patterns
---

{% include lead_image.html %}

Things often come in sets:

- States
- Pokemon
- Playing cards

Each set has items that belong to them (like California, Charizard, Jack of
Clubs) and checking if an item is a valid member is a common task. Some
collections (playing cards, for example) are also orderable; twos come before
fives which come before Kings.

There are many ways to represent members from these sets in Python:

- Unique string: `"CA"`, `"WA"`, `"MN"`
- Classes: `class Pokemon: ... `
- Tuples (or [namedtuples][namedtuples]): `("Clubs", "J")`, `("Hearts", 5)` 

[namedtuples]: {% post_url 2018-12-18-python_patterns_namedtuple %}

But is `"PR"` a valid state? Is `Pokemon("Digimon")` a member of Pokemon? Is
`("Lotus", "Black")` a playing card? We could keep a separate `set()` of all
valid members to check, but then we have to maintain it.

Thankfully, Python provides a way to create these sets and their members at
the same time: [**enumerations**][enums], or enums.

[enums]: https://docs.python.org/3/library/enum.html

## Playing Cards

Without using enums we might implement a [standard playing card][card_52] as
follows:

[card_52]: https://en.wikipedia.org/wiki/Standard_52-card_deck

{% highlight python %}
@total_ordering
class PlayingCard:
  def __init__(self, suit, rank):
    self.suit = suit
    self.rank = rank
    self.__rank_to_value()

  def __rank_to_value(self):
    """ Convert face cards to integer values. """
    if rank == "A":
      self.__value = 14
    elif rank == "K":
      self.__value = 13
    ... # etc.
    # Numbered cards are easy
    else:
      self.__value = self.rank

  def __lt__(self, other):
    return self.rank < other.rank

  def __eq__(self, other):
    return self.rank == other.rank
{% endhighlight python %}

This class works with the standard comparison operators, but to do so we had
to write a bit of an annoying `__rank_to_value()` function; otherwise Aces and
Kings would be tough to compare to 2s and 3s!

With that done, we can now declare cards easily enough:

{% highlight python %}
ace_of_spades    = PlayingCard("Spade", "A")
king_of_hearts   = PlayingCard("Heart", "K")
eight_of_spades  = PlayingCard("Spades", 8)
eight_of_clubs   = PlayingCard("Club", "8")
my_favorite_card = PlayingCard("Stars", 85)
{% endhighlight python %}

Did you catch all the errors? We could write some error checking in the class,
but it would again be a bit tedious. Enums will let us represent the suites
and ranks, check that they are valid, and order based on value, without
writing a lot of extra code.

## Playing Cards with Enums

An enum has exactly the properties we want:

- We can test membership, so only real suits and ranks are allowed.
- We can order them, so we know that King > Jack > Ten.

First, we define the suits:

{% highlight python %}
from enum import Enum, auto

class CardSuit(Enum):
    """ Playing card suits. """
    CLUBS = auto()
    DIAMONDS = auto()
    HEARTS = auto()
    SPADES = auto()
{% endhighlight python %}

The function `auto()` sets the values and insures that they are unique. The
members are not orderable (so `CardSuit.CLUBS > CardSuit.DIAMONDS` will raise
an error), but do have equality (so `CardSuit.CLUBS != CardSuit.DIAMONDS`
works). We can also test membership easily, allowing us to ensure only valid
suits are accepted.

An example of some of the properties:

{% highlight python %}
hearts = CardSuit.HEARTS
clubs = CardSuit.CLUBS
stars = "stars"

# We can test equality
hearts != stars  # True

# And we can test membership
isinstance(stars, CardSuit)  # False
{% endhighlight python %}

Second, we define a `CardValue`, this time using `IntEnum` because we want the
values to be comparable.

{% highlight python %}
from enum import IntEnum, unique

@unique
class CardRank(IntEnum):
    """ Playing card values. They are order able as excepted:
    2 < 3 < ... < king < ace.
    """
    TWO = 2
    THREE = 3
    ... # etc.
    TEN = 10
    JACK = 11
    QUEEN = 12
    KING = 13
    ACE = 14
{% endhighlight python %}

The `IntEnum`s are orderable so `CardRank.TEN < CardRank.KING`. The decorator
`@unique` adds a check that makes sure we haven't double assigned any values.

Now the card class is easy to implement:

{% highlight python %}
@total_ordering
Class PlayingCard:
  def __init__(self, suit, rank):
    # Check that the suit is valid
    if not isinstance(suit, CardSuit):
      Raise("{} is an invalid CardSuit.".format(suit))
    self.suit = suit

    # Check that the rank is valid
    if not isinstance(rank, CardRank):
      Raise("{} is an invalid CardRank.".format(rank))
    self.rank = rank

  def __lt__(self, other):
    return self.rank < other.rank

  def __eq__(self, other):
    return self.rank == other.rank
{% endhighlight python %}

It is now much easier to catch errors in our card definitions (in fact, the
runtime will catch them for you):

{% highlight python %}
ace_of_spades    = PlayingCard(CardSuit.SPADES, CardRank.ACE)
king_of_hearts   = PlayingCard(CardSuit.HEARTS, CardRank.KING)
my_favorite_card = PlayingCard("Stars", 85)  # Obviously wrong
{% endhighlight python %}
