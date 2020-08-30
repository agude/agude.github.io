---
layout: post
title: "Python Patterns: Map and Filter"
description: >
  For loops are great, but I am a big fan of replacing them with simple
  functions. Python provides a couple of building blocks.
image: /files/patterns/naturalists_misc_vol_1_painted_snake.jpg
image_alt: >
  A drawing of an orange and black snake from The Naturalist's Miscellany
  Volume 1.
categories: python_patterns
---

{% include lead_image.html %}

One of the things that is great about coding is it lets you do a simple task
over and over again. A common way to do so is to store the data in a list and
process it item-by-item in a for loop.

For example, we might want to pull the text out of an HTML document which is
stored line-by-line as stings:

```python
text_lines = []
for line in html_lines:
    parsed_line = extract_text(line)
    text_lines.append(parsed_line)
```

This code is fine: short, clean, not a lot that can go wrong.
But I love to replace custom code with Python built-ins whenever possible,
because the built-ins are fast, well tested, and concise.

Python provides some great ways to replace for loops with built-ins, I'll
cover them below.

## Map

The [`map()` function][map] replaces a for loop that calls a function on each
item of a list, just as I did in the above HTML parsing example. Here is how I
would write the HTML example (in one line!) with map:

[map]: https://docs.python.org/3.7/library/functions.html#map

```python
text_lines = map(extract_text, html_lines)
```

Simple!

It is often useful to define the processing function inline using a
[`lambda`][lambda]:

[lambda]: https://docs.python.org/3/reference/expressions.html#lambda

```python
take_two_chars = lambda x: x[:2]
parsed = map(take_two_chars, text_lines)
```

Sometimes the function we need to call takes multiple arguments. Consider the
following (trivial) example function:

```python
def add(x, y):
  return x+y
```

If we need to fix one of the arguments, we can [partially apply][partial] the
function before calling:

[partial]: https://en.wikipedia.org/wiki/Partial_application

```python
from functools import partial

add_two = partial(add, y=2)
nums_plus_two = map(add_two, nums)
```

If we have have two lists and need to call the function pairwise on the
elements. We could write a for loop like this:

```python
sums = []
for x, y in zip(first_nums, second_nums):
  sums.append(add(x, y))
```

But we can do that with map as well, as it takes any number of iterables:

```python
sums = map(add, first_nums, second_nums)
```

## Filter

The [`filter()` function][filter] covers a special case of `map()`: when the
function returns True or False and we only keep the elements of the original
list that return True.

For example, if we wanted to only keep cards from our hand that were hearts,
we might write:

```python
just_hearts = []

for card in hand:
  if card.suit == "heart":  # Keep if True
    just_hearts.append(card)
```

A more clever way to denote the card's suit than using strings would be to use
`enum`s. [I covered how to do that in a previous article][enums].

[enums]: {% post_url 2019-01-22-python_patterns_enum %}#playing-cards-with-enums

The [`filter()` function][filter] turns this into:

[filter]: https://docs.python.org/3.7/library/functions.html#filter

```python
is_a_heart = lambda card: card.suit == "heart"
just_hearts = filter(is_a_heart, hand)
```

