---
layout: post
title: "Python Patterns: Map and Filter"
description: >
  For loops are great, but I am a big fan of replacing them with simple
  functions. Python provides a couple of building blocks.
image: /files/patterns/locupletissimi_rerum_naturalium_thesauri_v1_lxxxiii_snake.png
image_alt: >
  A drawing of a red and white snake taken from Plate LXXXIII from
  Locupletissimi rerum naturalium thesauri volume 1.
categories: python_patterns
---

{% include lead_image.html %}

One of the things that is great about coding is it lets you do a simple task
over and over again.

Python lets you process a large amount of information quickly.
Often this data is stored in a list and we process it with a for loop. For
example, we might want to pull the text out of an HTML document which is
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

## map

The [`map()` function][map] replaces a for loop that calls a function on each
item of a list, just as I did in the above HTML parsing example. Here is how
you would write it (in one line!) with map:

[map]: https://docs.python.org/3.7/library/functions.html#map

```python
text_lines = map(extract_text, html_lines)
```

Simple!

Often it is useful to define a function inline using a [`lambda`][lambda]:

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

Sometimes we need to call this on a list of numbers with one of the inputs
fixed. In that case [partial applying][partial] the function works well:

[partial]: https://en.wikipedia.org/wiki/Partial_application

```python
from functools import partial

add_two = partial(add, y=2)
nums_plus_two = map(add_two, nums)
```

Other times you have two lists, where we need to call the function pairwise on
the elements. You could write a for loop like this:

```python
sums = []
for x, y in zip(first_nums, second_nums):
  sums.append(add(x, y))
```

But you can do that with map as well, as it takes any number of iterables:

```python
sums = map(add, first_nums, second_nums)
```

## filter

Sometimes you need to keep only the elements in a list that match some
criteria. If I wanted to only keep cards that were hearts, for example, I
might write:

```python
just_hearts = []
for card in hand:
  if card.suit == "heart":
    just_hearts.append(card)
```

The [`filter()` function][filter] turns this into:

```python
is_heart = lambda card: card.suit == "heart"
just_hearts = filter(is_heart, hand)
```

[filter]: https://docs.python.org/3.7/library/functions.html#filter
[reduce]: 
