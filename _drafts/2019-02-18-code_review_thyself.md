---
layout: post
title: "Coder, Review Thyself"
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

Here is a method from the `Dice()` class that generates the random results:

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

The class (`self`) variables are defined elsewhere, so a quick summary is:

- `number`: The number of dice to roll.
- `size`: The number of sides per die.
- `highestMod`/`lowestMod`: Whether to drop a certain number of highest or
  lowest rolled dice
- `globalMod`/`localMod`: Modifiers to add to the dice.
- `doSum`: Sum the result instead of reporting individually.


## Code Review

The code is divided into four parts, so I'll break it into four pieces to
review:

{% highlight python %}
def roll(self, doSum=None):
  """ Roll the dice and print the result. """
  # If self.doSum, we must do the sum
  if self.doSum == True:
    doSum == True
{% endhighlight python %}

  - The variables should use `snake_case` not `lowerCamelCase`, according to [PEP 8][pep8].
  - Public functions should have [docstrings][pep257]. 
  - There are two similar variables, `doSum` and `self.doSum`, what is the diference? The comment is not helpful.
  - Test booleans with `if bool:` not `if bool == True`.

[pep257]: https://www.python.org/dev/peps/pep-0257/
[pep8]: https://www.python.org/dev/peps/pep-0008/

{% highlight python %}
  #Generate numbers
  values = []
  for i in range(0, self.number):
    dieVal = randint(1, self.size) + self.localMod
    dieVal = max(dieVal, 0)  # Dice must roll at least 0 after mods
    values.append(dieVal)
{% endhighlight python %}

- The variable `i` in the loop is unused, prefer `_`. 
- Good use of the "[`max` instead of `if` pattern][max_post]".
- Consider not reusing `dieVal`, although it is clearer to use two lines!

[max_post]: {% post_url 2018-06-14-python_patterns_max_not_if %}

{% highlight python %}
  #Remove Highest and Lowest dice
  values.sort()
  starti = self.lowestMod
  endi = len(values) - self.highestMod
  values = values[starti:endi]
{% endhighlight python %}

- Should values always be sorted, even if not dropping dice?

This chunk of code is pretty good!

{% highlight python %}
  #Return values
  if doSum:
    print(sum(values) + self.globalMod)
  else:
    print(values)
{% endhighlight python %}

- Instead of overwriting `doSum` above, just test the `or` here.
- Consider `return` instead of `print`. It is easy to print a returned value,
but it's hard to write tests for print statements.


## The New Code

And here is the [updated version of the code][2018_code]:

[2018_code]: https://github.com/agude/Dice/blob/cf96a6629b9f4e58813bf45b25a567f630c8f711/dice/dice.py

{% highlight python %}
def roll(self, do_sum=False):
  """ Roll the dice and print the result. """
  logging.info("Rolling dice")
  # Generate rolls
  values = []
  for _ in range(0, self.number):
    # Fate Dice use F, and have sides (-1, 0, 1)
    if self.size == "F":
      rand_val = randint(-1, 1)
      die_val = rand_val + self.local_mod
    else:
      rand_val = randint(1, self.size)
      die_val = rand_val + self.local_mod

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

I have removed almost all of the logging code to make it a little less
cluttered.

---

[^1]: Which translates to: Roll five dice with ten sides. From each die subtract one from the result. Drop the three lowest and the highest die. Sum the remaining dice and add fifteen.
