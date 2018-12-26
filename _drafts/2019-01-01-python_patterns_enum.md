---
layout: post
title: "Python Patterns: Enum"
description: >
image: /files/patterns/lycodon_modestus.jpg
image_alt: >
  A drawing of a Lycodon Modestus snake from the Iconographic Zoologica
  collection.
categories: python_patterns
---

{% include lead_image.html %}

## Playing Cards

We might implement a [playing card][card_52] as follows:

[card_52]: https://en.wikipedia.org/wiki/Standard_52-card_deck

{% highlight python %}
@total_ordering
Class PlayingCard:
  def __init__(self, suit, rank):
    self.suit = suit
    self.rank = rank
    self.__rank_to_value()

  def __rank_to_value(self):
    # Convert face cards to int values
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

We had to write a bit of an annoying `__rank_to_value()` function to make it
easy to compare Aces to Kings, but over all it is not so bad. We can now
declare cards easily enough:

{% highlight python %}
ace_of_spades        = PlayingCard("Spade", "A")
king_of_hearts       = PlayingCard("Heart", "K")
dead_eight_of_spades = PlayingCard("Spades", 8)
dead_eight_of_clubs  = PlayingCard("Club", "8")
my_favorite_card     = PlayingCard("Stars", 85)
{% endhighlight python %}

Did you catch all the errors? We could write some error checking in the class
to check values, but it would again be a bit tedious. Python includes a better
way.

## The Enum


## Revisiting Cards

An enum has exactly the properties we want:

- We can test membership, so only real suits and values are allowed
- We can order them, so we know that King > Jack > Ten.

First, we define the suits:

{% highlight python %}
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
works). This will let us makesure only valid suits are accepted.

We can also test other values against the Enum to see if they are members:

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

Because we're using an `IntEnum`, we can order the values: `CardRank.TEN <
CardRank.KING`. The decorator `@unique` checks that we haven't double assigned
any values.

Now the card class is easy to implement:

{% highlight python %}
@total_ordering
Class PlayingCard:
  def __init__(self, suit, rank):
    if not isinstance(suit, CardSuit):
      Raise("{} is an invalid CardSuit.".format(suit))
    self.suit = suit

    if not isinstance(rank, CardRank):
      Raise("{} is an invalid CardRank.".format(rank))
    self.rank = rank

  def __lt__(self, other):
    return self.rank < other.rank

  def __eq__(self, other):
    return self.rank == other.rank
{% endhighlight python %}

It is not much easier to catch errors in our card definitions (in fact, the
runtime will catch them for you):

{% highlight python %}
ace_of_spades    = PlayingCard(CardSuit.SPADES, CardRank.ACE)
king_of_hearts   = PlayingCard(CardSuit.HEARTS, CardRank.KING)
my_favorite_card = PlayingCard("Stars", 85)  # Obviously wrong
{% endhighlight python %}
