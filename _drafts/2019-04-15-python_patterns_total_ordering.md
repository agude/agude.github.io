---
layout: post
title: "Python Patterns: @total_ordering"
description: >
  Your classes can make use of the rich Python comparison operators just like
  the default classes. Here I'll show you how to do it even easier.
image: /files/patterns/biologia_centrali_americana_coronella_annulata.jpg
image_alt: >
  A drawing of a red, black, and yellow milk snake.
categories: python_patterns
---

{% include lead_image.html %}

Python classes come with a set of rich comparison operators. I can compare
strings lexically like so:

{% highlight python %}
"alex" > "alan"
"dog" < "cat"
{% endhighlight python %}

And I can sort numbers including integers and floats:

{% highlight python %}
sorted((4, 3, 2.2, 5)) == (2.2, 3, 4, 5)
{% endhighlight python %}

All of these are made possible by special ["dunder" methods][dunder] defined
by each class. Implementing comparison and sorting for your own classes is as
easy as defining six methods, one each for `==`, `!=`, `>`, `=>`, `<`, and
`<=`. Thankfully, Python has a helper method that makes it simplier:
[`@total_ordering`][total].

[dunder]: TODO
[total]: https://docs.python.org/3/library/functools.html#functools.total_ordering

## Your Library

Let's make a class to hold books, so we can keep track of our library. A basic
`Book` class might look like:

{% highlight python %}
class Book:
  def __init__(self, title, author):
    self.title = title
    self.author = author
{% endhighlight python %}

We want the `Book` class to be comparable, because that will allow us to order
the books on the shelf (using `sorted()` for instance). Books will be sorted
first by author and then by title. To implement that, we write the six
"dunder" methods like this:

{% highlight python %}
class Book:
  def __init__(self, title, author):
    self.title = title
    self.author = author

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

That is a lot of highly-redundant code!

Math tells us that if `self > other` is true, than `self < other` and `self ==
other` are false. We could write our own logic taking advantage of this fact,
but that is exactly what [the `@total_ordering` decorator][total] from
`functools` does already.

## With `@total_ordering`

Using the `@total_ordering` decorator[^1] we only have to define `__eq__` and
one of the other comparison methods. The rest of the methods are filled in for
us. It's used like so:

{% highlight python %}
from functools import total_ordering


@total_ordering
class Book:
  def __init__(self, title, author):
    self.title = title
    self.author = author

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

Now we have a much more compact class, but with the same functionality as
before! We can sort our books easily:

{% highlight python %}
my_books = [
  Book("Absalom, Absalom!", "William Faulkner"),
  Book("The Sun Also Rises", "Ernest Hemmingway"),
  Book("For Whom The Bell Tolls", "Ernest Hemmingway"),
  Book("The Sound and the Fury", "William Faulkner"),
]

for book in sorted(my_books):
  print(book.author, ",", book.title)

# >> Ernest Hemmingway, For Whom The Bell Tolls
# >> Ernest Hemmingway, The Sun Also Rises
# >> William Faulkner, Absalom, Absalom!
# >> William Faulkner, The Sound and the Fury
{% endhighlight python %}

---
[^1]: A decorator is a function that takes a Python object as an argument and returns a (often) modified copy of the object.