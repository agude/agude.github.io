---
layout: post
title: "Python Patterns: Map and Filter"
description: >
  For loops are great, but I am a big fan of replacing them with simple
  functions. Python provides a couple of building blocks.
image: /files/patterns/naturalists_misc_vol_1_painted_snake.jpg
show_lead_image: True
image_alt: >
  A drawing of an orange and black snake from The Naturalist's Miscellany
  Volume 1.
categories:
  - python
  - software-development
---

Computers are great at performing a simple action over and over again. A common
way to make them do such a task is to store data in a list and iterate over it
with a for loop, calling a function for each item.

But Python has some great functions to replace for loops, which I will cover
below after a quick example.

## Playing Cards

Given a list of playing cards as tuples, like so:

```python
cards = [
  ("Spades", 14),
  ("Diamonds", 13),
  ("Hearts", 2),
  ("Spades", 8),
  ("Clubs", 11),
  ...  # etc.
]
```

We want to convert them to `PlayingCard` objects as [defined in my previous
post on `enums`][enums]. To do this, we need a function to convert a tuple into the
class:

[enums]: {% post_url 2019-01-22-python_patterns_enum %}#playing-cards-with-enums

```python
def tuple_to_card(card_tuple):
  suit, rank = card_tuple

  card = PlayingCard(
    CardSuit(suit),
    CardRank(rank),
  )

  return card
```

This makes it easy to parse the list with a quick loop:

```python
new_cards = []
for card_tuple in cards:
  new_card = tuple_to_card(card_tuple)
  new_cards.append(new_card)
```

And we can even filter the cards so that we only keep hearts:

```python
just_hearts = []
for card_tuple in cards:
  new_card = tuple_to_card(card_tuple)
  if new_card.suit is CardSuit.HEARTS:
    just_hearts.append(new_card)
```

These code snippets are fine: short and clean, with not a lot that can go wrong. But I
love to replace custom code with Python built-ins whenever possible, because
they are fast, well tested, and concise. Python provides two functions that
can simplify even these already simple code fragments: `map()` and `filter()`.

## Map

The [`map()` function][map] replaces a for loop that calls a function on each
item of a list, just as we did in the above when making `PlayingCard` objects.
Here is how we could rewrite the above code using map:

[map]: https://docs.python.org/3.7/library/functions.html#map

```python
new_cards = map(tuple_to_card, cards)
```

Simple!

If the function is not too complicated, it can be useful to define it inline
with a [`lambda` function][lambda]:

[lambda]: https://docs.python.org/3/reference/expressions.html#lambda

```python
get_card_rank = lambda card_tuple: card_tuple[1]
ranks = map(get_card_rank, cards)
```

But what if instead of tuples we had two lists: one of suits and one of ranks?
We could use the [`zip` function][zip] to combine the two lists like a zipper:

[zip]: https://docs.python.org/3.7/library/functions.html#zip

```python
new_cards = []
for card_tuple in zip(card_suits, card_ranks):
  new_card = tuple_to_card(card_tuple)
  new_cards.append(new_card)
```

But map already allows us to do pairwise operations:

```python
new_cards = map(tuple_to_card, card_suits, card_ranks)
```

Of course, we could write our own map using [list comprehension][comp]:

[comp]: https://docs.python.org/3/tutorial/datastructures.html#list-comprehensions

```python
new_cards = [tuple_to_card(card_tuple) for card_tuple in cards]
```

Which, perhaps, is a little more Pythonic.

## Filter

But how would we filter the list so that we only keep hearts, as in our second
example? We could wrap the `map` call in a for loop:

```python
just_hearts = []
for card in map(tuple_to_card, cards):
  if card.suit is CardSuit.HEARTS:
    just_hearts.append(card)
```

But the [`filter()` function][filter] does that for us! It takes a function
and an iterable and returns only the elements of the iterable that evaluate to
`True` when the function is called on them. This allows us to rewrite the
above as:

[filter]: https://docs.python.org/3.7/library/functions.html#filter

```python
is_a_heart = lambda card: card.suit is CardSuit.HEARTS

just_hearts = filter(
  is_a_heart,
  map(tuple_to_card, cards)
)
```

Of course, again, we could write this as a comprehension:

```python
just_hearts = [
  tuple_to_card(card_tuple) for card_tuple in cards
  if tuple_to_card(card_tuple).suit is CardSuit.HEARTS
]
```

However, this is not as readable as the `map` and `filter` example, which is very
short, very readable, and even a bit... [functional][functional].[^1]

[functional]: https://en.wikipedia.org/wiki/Functional_programming

---
[^1]: But what about `reduce()`, the third function of the classic "filter-map-reduce" triplet? Python does have a reduce function, but it was moved to `functools.reduce()` because ["a loop is more readable most of the time"][reduce].

[reduce]: https://www.python.org/dev/peps/pep-3100/#built-in-namespace
