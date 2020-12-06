---
layout: post
title: "Python Patterns: Enum"
description: >
  Things often come in sets of specific items, like states, Pokémon, or
  playing cards. Python has an elegant way of representing them using enum.
image: /files/patterns/locupletissimi_rerum_naturalium_thesauri_v1_lxxxiii_snake.png
show_lead_image: True
image_alt: >
  A drawing of a red and white snake taken from Plate LXXXIII from
  Locupletissimi rerum naturalium thesauri volume 1.
categories:
  - python
  - software-development
---

Things often come in sets, for example, States, Pokémon, Playing cards, etc.

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

```python
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
    return self.__value < other.__value

  def __eq__(self, other):
    return self.__value == other.__value
```

This class works with the standard comparison operators (thanks to [the
`@total_ordering` decorator, which I discuss in another
post][total_ordering]), but to do so we had to write a bit of an annoying
`__rank_to_value()` function; otherwise Aces and Kings would be tough to
compare to 2s and 3s!

[total_ordering]: {% post_url 2019-04-15-python_patterns_total_ordering %}

With that done, we can now declare cards easily enough:

```python
ace_of_spades    = PlayingCard("Spade", "A")
king_of_hearts   = PlayingCard("Heart", "K")
eight_of_spades  = PlayingCard("Spades", 8)
eight_of_clubs   = PlayingCard("Club", "8")
my_favorite_card = PlayingCard("Stars", 85)
```

Did you catch all the errors? We could write some error checking in the class,
but it would again be a bit tedious. Instead, let's implement this using enums.
Enums will let us represent the suits and ranks, check that they are valid,
and order based on value, without writing a lot of extra code.

## Playing Cards with Enums

An enum has exactly the properties we want:

- We can test membership, so only real suits and ranks are allowed.
- We can order them, so we know that King > Jack > Ten.

First, we define the suits:

```python
from enum import Enum, auto

class CardSuit(Enum):
    """ Playing card suits. """
    CLUBS = auto()
    DIAMONDS = auto()
    HEARTS = auto()
    SPADES = auto()
```

The function `auto()` sets the values and insures that they are unique. The
members are not orderable (so `CardSuit.CLUBS > CardSuit.DIAMONDS` will raise
an error), but do have equality (so `CardSuit.CLUBS != CardSuit.DIAMONDS`
works). We can also test membership easily, allowing us to ensure only valid
suits are accepted.

An example of some of the properties:

```python
hearts = CardSuit.HEARTS
clubs = CardSuit.CLUBS
stars = "stars"

# We can test equality
hearts != stars  # True

# And we can test membership
isinstance(stars, CardSuit)  # False
```

Second, we define a `CardValue`, this time using `IntEnum` because we want the
values to be comparable.

```python
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
```

The `IntEnum`s are orderable so `CardRank.TEN < CardRank.KING`. The decorator
`@unique` adds a check that makes sure we haven't double assigned any values.

Now the card class is easy to implement:

```python
@total_ordering
Class PlayingCard:
  def __init__(self, suit, rank):
    # Check that the suit is valid
    if not isinstance(suit, CardSuit):
      raise ValueError("{} is an invalid CardSuit.".format(suit))
    self.suit = suit

    # Check that the rank is valid
    if not isinstance(rank, CardRank):
      raise ValueError("{} is an invalid CardRank.".format(rank))
    self.rank = rank

  def __lt__(self, other):
    return self.rank < other.rank

  def __eq__(self, other):
    return self.rank == other.rank
```

It is now much easier to catch errors in our card definitions:

```python
ace_of_spades    = PlayingCard(CardSuit.SPADES, CardRank.ACE)
king_of_hearts   = PlayingCard(CardSuit.HEARTS, CardRank.KING)
my_favorite_card = PlayingCard("Stars", 85)  # Obviously wrong
```

Not only are they obvious by eye (`"Stars"` is clearly not a `CardSuit`), but
the runtime will even raise an error!
