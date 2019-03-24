---
layout: post
title: "Python Patterns: @total_ordering"
description: >
  Things often come in sets of specific items, like states, Pokémon, or
  playing cards. Python has an elegant way of representing them using enum.
image: /files/patterns/locupletissimi_rerum_naturalium_thesauri_v1_lxxxiii_snake.png
image_alt: >
  A drawing of a red and white snake taken from Plate LXXXIII from
  Locupletissimi rerum naturalium thesauri volume 1.
categories: python_patterns
---

{% include lead_image.html %}


## Employee

Let's make a class to hold books, so we can keep track of our library. A basic
class might look like:

{% highlight python %}
class Book:
  def __init__(self, title, author, release_year):
    self.title = title
    self.author = author
    self.release_year = release_year

{% endhighlight python %}

We want the `Book` class to comparable, because that will allow us to order
the books on the shelf. We will order first by author name and then by title.
We can do that like this:

{% highlight python %}
class Book:
  def __init__(self, title, author, release_year):
    self.title = title
    self.author = author
    self.release_year = release_year

  # Define ==
  def __eq__(self, other):
    ours = (self.author, self.title)
    theirs = (other.author, other.title)
    return ours == theirs

  # Define !=
  def __ne__(self, other):
    ours = (self.author, self.title)
    theirs = (other.author, other.title)
    return ours != theirs

  # Define <
  def __lt__(self, other):
    ours = (self.author, self.title)
    theirs = (other.author, other.title)
    return ours < theirs

  # Define <=
  def __le__(self, other):
    ours = (self.author, self.title)
    theirs = (other.author, other.title)
    return ours <= theirs

  # Define >
  def __gt__(self, other):
    ours = (self.author, self.title)
    theirs = (other.author, other.title)
    return ours > theirs

  # Define >=
  def __ge__(self, other):
    ours = (self.author, self.title)
    theirs = (other.author, other.title)
    return ours >= theirs
{% endhighlight python %}

That is a lot of writing! Worse, it's highly redundant, because we know that
if `self > other` is true, than `self < other` and `self == other` are false.
We could write our own logic taking advantage of this, but Python already has
it built in: [the `@total_ordering` decorator][total] from `functools`

[total]: https://docs.python.org/3/library/functools.html#functools.total_ordering

## With `@total_ordering`

The `@total_ordering` decorator[^1] we only have to define `__eq__` and just
one of the other methods, it fills in the rest using the logic described
above. It's used like so

{% highlight python %}
class Book:
  def __init__(self, title, author, release_year):
    self.title = title
    self.author = author
    self.release_year = release_year

  # Define ==
  def __eq__(self, other):
    ours = (self.author, self.title)
    theirs = (other.author, other.title)
    return ours == theirs

  # Define <
  def __lt__(self, other):
    ours = (self.author, self.title)
    theirs = (other.author, other.title)
    return ours < theirs

{% endhighlight python %}

And that's it! Now all of the comparison opperators work.

---
[^1]: A decorator is a function that takes a Python object as an argument and returns a (often) modified copy of the object.
