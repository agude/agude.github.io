---
layout: post
title: "Python Patterns: max instead of if"
description: >
  I often have to loop over a set of objects to find the one with the greatest
  score. You can use an if statement and a placeholder, but there are more
  elegant ways!
image: /files/patterns/max_not_if.jpg
image_alt: >
  A watercolor drawing of a Spectacled Caiman fighting with a False Coral
  Snake by Maria Sibylla Merian.
---

{% include lead_image.html %}

When writing Python, I often have to look through a set of objects, determine
a score for each one of them, and save both the best score and object
associated with it. For example, looking for the highest scoring word that I
can make in [Scrabble][scrabble] with the letters I currently have.

The one way to do this is to loop over all the objects and use a placeholder
to remember the best one seen so far, like this:

[scrabble]: https://en.wikipedia.org/wiki/Scrabble

{% highlight python %}
# Set up placeholder variables
best_score = 0
best_word = None

# Try all possible words, saving the best one seen
for word in possible_words(my_letters):
  score = score_word(word)

  if score > best_score:
    best_score = score
    best_word = word
{% endhighlight python %}

This code is not that complicated, but we can still improve its readability
with a quick tweak.

## Simplifying with `max()`

What does `if score > best_score` remind you of? The way we might implement
the `max()` function! Using `max()` helps us simplify the code nicely:

{% highlight python %}
# Set up placeholder variables
best_seen = (0, None)

# Try all possible words, saving the best one seen
for word in possible_words(my_letters):
  score = score_word(word)

  newest_seen = (score, word)
  best_seen = max(best_seen, newest_seen)
{% endhighlight python %}

Storing all the data together in a single tuple means that assignment and
comparison are now handled all at once. This makes it less likely that we will
mix up one of the assignments, and makes it clearer what we're doing.

There is one potential pitfall here: `max()` picks the tuple with the largest
first element (the score in our case), which is what we want. But, if the
first elements are the same in both tuples, `max()` continues through the
remaining elements until the tie is broken. So if two words have the same
score, `max()` will then compare the words next, which is does alphabetically.

To have `max()` only compare the first element, we can use the `key`
parameter. The `key` parameter takes a function that is called on each object
and returns another object to use in the comparison. We can use it to select
just the first entry like so:

{% highlight python %}
# Set up placeholder variables
best_seen = (0, None)

# Try all possible words, saving the best one seen
for word in possible_words(my_letters):
  score = score_word(word)

  newest_seen = (score, word)
  best_seen = max(best_seen, newest_seen, key=lambda x: x[0])
{% endhighlight python %}

## Even Simpler

In the above examples we wanted to save both the score and the word, but what
if we only cared about the word that generated the highest score, not the
score itself? Then there is an even simpler way!

By default `max()` uses the standard comparison operator, but we can change
that using the `key` argument as we did above. We can use `score_word()` as
comparison function:

{% highlight python %}
words = possible_words(my_letters)
best_word = max(words, key=score_word)
{% endhighlight python %}

Which gives us a very compact (and relatively fool proof) pattern, with all
the looping and placeholders pushed into the implementation of `max()`.
