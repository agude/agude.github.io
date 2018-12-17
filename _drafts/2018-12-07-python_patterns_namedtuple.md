---
layout: post
title: "Python Patterns: namedtuple"
description: >
  I often have to loop over a set of objects to find the one with the greatest
  score. You can use an if statement and a placeholder, but there are more
  elegant ways!
image: /files/patterns/lycodon_modestus.jpg
image_alt: >
  A watercolor drawing of a Spectacled Caiman fighting with a False Coral
  Snake by Maria Sibylla Merian.
categories: python_patterns
---

\\ include lead_image.html %}

If you are working with ordered data in Python, odds are you are going to use
a [sequence][seq]. Lists and tuples are simple: they provide a method to
iterate over their data in order, they're built-in to Python and so available
everywhere, and many third-party libraries require you to use an object with
the same sort of signature. They work great when your data is simple.

[seq]: https://docs.python.org/3.7/library/stdtypes.html#sequence-types-list-tuple-range

Python, though, does not require you to keep things simple. You can put any
sort of object in a list or tuple, which makes it easy to lose track of what
is where. One might create cards in a virtual address book like this:

\\ highlight python %}
card = (
  "Alex",
  "Gude",
  "alex@alexgude.com",
  None,
  "17 St., Smaller Town, CA",
)
\\ endhighlight python %}

Simple, but a little confusing. What's that `None`? Writing code to work with
these objects is error prone:

\\ highlight python %}
def check_email(card):
  """Check if a card has an email
  address that is valid."""
  email = card[2]  # 2?!
  is_valid = '@' in email

  return is_valid
\\ endhighlight python %}

Is 2 right? Maybe it was 3? Catching mistakes in the code is tough for anyone
reading it.

## Alternatives

A dictionary is a natural solution to this problem, because we can use strings
as keys like `card["email"]` instead of `card[2]`. But we might need to
maintain compatibility with something that expects a sequence, as was the case
when [passing artists around in my `matplotlib` blitting post][blitting].

[blitting]: {% post_url 2018-04-07-matplotlib_blitting_supernova %}#blitting

Instead, we could build a class that acts like a list or tuple::

\\ highlight python %}
class Card:
  def __init__(self, first_name, last_name, ...):
    self.__internal = [first_name, last_name, ...]
    self.first_name = self.__internal[0]
    self.last_name = self.__internal[1]
    ...

  def __len__(self):
    return self.__internal.__len__

  def __getitem__(self):
    return self.__internal.__getitem__

  def __next__(self):
    return self.__internal.__getitem__
\\ endhighlight python %}

A little annoying to write. Thankfully, someone has already done so.

## `namedtuple`

The [named tuple][namedtuple] functions exactly like a tuple, with one addition: you can
access the data by name. Our card example would now look like this:

[namedtuple]: https://docs.python.org/3/library/collections.html#collections.namedtuple

\\ highlight python %}
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
    "Alex", "Gude", "alex@alexgude.com",
    None, "17 St., Smaller Town, CA",
)
\\ endhighlight python %}

This is a much cleaner than our original card tuple. We now know the missing
value is the phone number! We can access the values with dot operators as
well: `card.email`. And the named tuple stills works exactly as you would
expect for a standard tuple:

\\ highlight python %}
# For loops work
for item in alex_card:
    print(item)

# We can access with . or []
alex_card[2] == alex_card.email

# And we can unpack
first, last, email, phone, address = alex_tuple
\\ endhighlight python %}

Code that operates on this named tuple is much easier to read; the following
snippet is clearly extracting the email value:

\\ highlight python %}
def new_check_email(card):
  """Check if a card has an email
  address that is valid."""
  is_valid = '@' in card.email

  return is_valid
\\ endhighlight python %}

Of course, or old function will still work with it's magic number 2 and all,
because the named tuples are backwards compatible!
