---
layout: post
title: "Python Patterns: Named Tuples"
description: >
  Sometimes I need to store an ordered dataset, but reference specific members
  from it. Named tuples in Python provide a clean way to do this!
image: /files/patterns/lycodon_modestus.jpg
image_alt: >
  A drawing of a Lycodon Modestus snake from the Iconographic Zoologica
  collection.
categories:
  - python
  - software-development
---

In Python, [sequences][seq] are a great way to hold a set of ordered data. As
long as the data is simple, a list or tuple is perfect because they are
included in every install of Python. But data is not always simple; you can
put any object you want in a sequence, making it easy to lose track of what is
where.

[seq]: https://docs.python.org/3.7/library/stdtypes.html#sequence-types-list-tuple-range

For example, one might create cards in a virtual address book like this:

```python
card = (
  "Alex",
  "Gude",
  "me@alexgude.com",
  None,
  "17 St., Smaller Town, CA",
)
```

Simple, but a little confusing. What does `None` signify? Writing code to work
with these objects is error prone:

```python
def check_email(card):
  """Check if a card has an email
  address that is valid."""
  email = card[2]  # 2?!
  is_valid = email is not None and '@' in email

  return is_valid
```

Is `2` the correct index to use? Maybe it was `3`? Catching mistakes in the
code is tough for anyone reading it.

## Alternatives

A dictionary is a natural solution to this problem, because we can use strings
as keys, for example `card["email"]` instead of `card[2]`. But we might need
to maintain compatibility with something that expects a sequence, as was the
case when [passing artists around in my `matplotlib` blitting post][blitting].

[blitting]: {% post_url 2018-04-07-matplotlib_blitting_supernova %}#blitting

Instead, we could build a class that acts like a list or tuple::

```python
class Card:
  def __init__(self, first_name, last_name, ...):
    self.__internal = [first_name, last_name, ...]
    self.first_name = self.__internal[0]
    self.last_name = self.__internal[1]
    ...  # etc.

  def __len__(self):
    return self.__internal.__len__()

  def __getitem__(self, key):
    return self.__internal.__getitem__(key)

  def __next__(self):
    return self.__internal.__next__()

  # and many other methods
```

Not difficult to write, but tedious due to all of the boilerplate code.
Thankfully, someone has already done so.

## Named Tuples

The [named tuple][namedtuple] functions exactly like a tuple, with one
addition: you can access each component of the tuple by name. Our card example
would now look like this:

[namedtuple]: https://docs.python.org/3/library/collections.html#collections.namedtuple

```python
from collections import namedtuple

Card = namedtuple(
    "Card",
    [
        "first_name",
        "last_name",
        "email",
        "phone",  # Our empty field revealed!
        "address",
    ]

)

alex_card = Card(
    "Alex", "Gude", "me@alexgude.com",
    None, "17 St., Smaller Town, CA",
)
```

This is much cleaner than our original card tuple. We now know the missing
value is the phone number! We can access the values with dot operators as
well: `card.email`. And the named tuple stills works exactly as you would
expect for a standard tuple:

```python
# For loops work
for item in alex_card:
    print(item)

# We can access with . or []
alex_card[2] == alex_card.email

# And we can unpack
first, last, email, phone, address = alex_tuple
```

Code that operates on this named tuple is much easier to read as well, because
it does not rely on [magic numbers][magic_number]:

[magic_number]: https://en.wikipedia.org/wiki/Magic_number_(programming)

```python
def new_check_email(card):
  """Check if a card has an email
  address that is valid."""
  email = card.email
  is_valid = email is not None and '@' in email

  return is_valid
```

Named tuples are not as well known as dictionaries or classes, but they solve
a common problem and make your code more readable!
