---
layout: post
title: "Coder, Review Thyself 2"
description: >

image: /files/patterns/lycodon_modestus.jpg
image_alt: >
categories: python_patterns
---

{% include lead_image.html %}

One of the best ways to improve as a developer is through code reviews. In a
code review another developer checks your code and gives you feedback. I'm not
going to go into details about how to do a code review, for that I recommend
[Michael Lynch's][ml_twitter] [_How To Do Code Reviews Like a
Human_][like_a_human]. Instead, I'm going to walk you through a _self review_
of my (really) old code.

[ml_twitter]: https://twitter.com/deliberatecoder
[like_a_human]: https://mtlynch.io/human-code-reviews-1/

## The Old Code

In 2011, I [wrote a dice roller in Python][2011_code]. It read a [dice
notation string][dice_notation] and generated the right random numbers to
simulate rolling the dice. In 2013, I went back and [completely rewrote the
code][2013_code] to use an [LL parser][ll_parser] (because I wanted to learn
how). This made it a lot more complciated, but also able to handle much more
complicated dice notation, like `5(d10-1)+15-3L-H`.[^1]

[2011_code]: https://github.com/agude/Dice/blob/48b37b24dee336ede767e31ec888894ba139a27b/dice.py
[dice_notation]: https://en.wikipedia.org/wiki/Dice_notation
[2013_code]: https://github.com/agude/Dice/blob/bd22217c74bf1b1605759d8bb0da4db30671e6f8/dice.py
[ll_parser]: https://en.wikipedia.org/wiki/LL_parser

In the next few sections I will review my old code, and then show you the [new
and improved version][2018_code].

[2018_code]: https://github.com/agude/Dice/blob/cf96a6629b9f4e58813bf45b25a567f630c8f711/dice/dice.py

## Argument Handling

As a command line program, one of the most important parts of the code is the
argument handling. It configures how the program runs and reads in the dice
notation. The original version looks like this:

{% highlight python %}
from optparse import OptionParser

usage = "usage: %prog [OPTIONS] -d 'xDy'"
version = "%prog Version 2.0.0\n\nCopyright (C) 2013 Alexander Gude - alex.public.account+Dice@gmail.com"
parser = OptionParser(usage=usage, version=version)
parser.add_option("-d", "--dice", action="store", type="string", dest="dice", help="the dice to be rolled, such as '4d6'")
parser.add_option("-s", "--sum", action="store_true", dest="sum", default=False, help="sum final result")
parser.add_option("-v", "--verbose", action="store_true", dest="verbose", default=False, help="print status messages to stdout")

(options, args) = parser.parse_args()
{% endhighlight python %}

It has three [flags][flags], one to specify the dice notation, one to turn on
summing the results, and one to make the program more verbose. Review
comments:

- The `optparse` module is deprecated, it should be replaced.
- You can't tell from this snippet, but the verbose flag is a [no-op][noop].
It should be implemented.
- Having to call `dice -d 3d6` is annoying; we always want to specify the dice
notation so it should be a positionaly argument, not a flag.

[flags]: https://en.wikipedia.org/wiki/Command-line_interface#Command-line_option
[noop]: https://en.wikipedia.org/wiki/NOP_(code) 

The new version is below:

{% highlight python %}
import argparse

parser = argparse.ArgumentParser(
  prog="Dice",
  description="A very complicated way of rolling dice.",
)
parser.add_argument("-v", "--version", action="version", version="%(prog)s 4.1.0")
parser.add_argument("dice_notation", type=str, help="the dice notation for the dice to roll, such as '4d6'")
parser.add_argument("-s", "--sum", help="sum the results of the roll", action="store_true", default=False)
parser.add_argument(
  "--log",
  help="set the logging level, defaults to WARNING",
  dest="log_level",
  default=logging.WARNING,
  choices=[
    'DEBUG',
    'INFO',
    'WARNING',
    'ERROR',
    'CRITICAL',
  ],
)
{% endhighlight python %}

It has upgraded to the `argparse` module. The `verbose` flag has been replaced
with a `log` flag that uses Python's `logging` module. Finally, the dice
notation string is passed in as a positional argument so the program is called
`dice 3d6` instead of requiring a flag.

## Dice Rolling

Another important part of the code is the one that "rolls the
dice", as it were.

{% highlight python %}
def roll(self, doSum=None):
  """ Roll the dice and print the result. """
  # If self.doSum, we must do the sum
  if self.doSum == True:
    doSum == True

  #Generate numbers
  values = []
  for i in range(0, self.number):
    dieVal = randint(1, self.size) + self.localMod
    dieVal = max(dieVal, 0)  # Dice must roll at least 0 after mods
    values.append(dieVal)

  #Remove Highest and Lowest dice
  values.sort()
  starti = self.lowestMod
  endi = len(values) - self.highestMod
  values = values[starti:endi]

  #Return values
  if doSum:
    print(sum(values) + self.globalMod)
  else:
    print(values)
{% endhighlight python %}

This code is pretty simple, and most of the issues are style related. Review
comments:

- Variable names should use `snake_case` not `lowerCamelCase`, according to
  [PEP 8][pep8].
- Public functions should have [docstrings][pep257]. 
- There are two similar variables, `doSum` and `self.doSum`, what is the
  diference? The comment is not helpful.
- Test booleans with `if bool:` not `if bool == True`.
- The variable `i` in the loop is unused, prefer `_`. 
- Good use of the "[max instead of if pattern][max_post]".
- Should values always be sorted, even if not dropping dice?
- Consider `return` instead of `print`. It is easy to print a returned value,
  but it's hard to write tests for print statements.

[max_post]: {% post_url 2018-06-14-python_patterns_max_not_if %}

[pep8]: https://www.python.org/dev/peps/pep-0008/
[pep257]: https://www.python.org/dev/peps/pep-0257/

{% highlight python %}
def roll(self, do_sum=False):
  """ Roll the dice and print the result. """
  logging.info("Rolling dice")
  # Generate rolls
  values = []
  for _ in range(0, self.number):
    die_val = randint(1, self.size) + self.local_mod
    die_val = max(die_val, 0)  # Dice must roll at least 0 after mods

    values.append(die_val)

    # Remove highest and lowest dice
    if self.lowest_mod >= 1 or self.highest_mod >= 1:
      start_i = self.lowest_mod
      end_i = len(values) - self.highest_mod
      sorted_values = sorted(values)

      values = sorted_values[start_i:end_i]

    #Return values
    if self.do_sum or do_sum:
      output = sum(values) + self.global_mod
    else:
      output = values

    return output
{% endhighlight python %}

The code now follows standard Python style. The main change is that it no
longer runs the dropping code unless requested, and returns a value instead of
printing. I also added a lot of logging to this function, but I removed them
in the example for clarity.

## Some more

{% highlight python %}
{% endhighlight python %}

{% highlight python %}
{% endhighlight python %}
