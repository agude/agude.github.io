---
layout: post
title: "Python Patterns: `max` instead of `if`"
description: >
  I often find myself looping over a set of objects to find the one with the
  greatest score. Normally this means an if statement, but there are more
  elegant ways to do it!
image: /files/phd-should-i-go/alexis_carrel_at_the_1913_columbia_university_commencement.jpg
image_alt: >
  A black and white photo from the 1913 Columbia University Commencement
  featuring a group of men in doctoral gowns wearing mortarboards. Nobel Prize
  winner Alexis Carrel is amongst them.
---

{% capture file_dir %}/files/phd-should-i-go/{% endcapture %}

{% include lead_image.html %}

When writing Python, I often have to look through a set of objects, determine a
score for each one of them, and save both the best score and object associated
with it. For example, if I was writing some code for [Scrabble][scrabble], I
might look at all the words I can spell with my letters and save the one that
is worth the most points.

The simplest way to do this is to loop over all the objects and remember the
best one seen so far, like this:

[scrabble]: https://en.wikipedia.org/wiki/Scrabble

{% highlight python %}
# Set up variables to hold the best score so far,
# and the word that generated it.
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
the `max()` function! Using it helps us simplify the code nicely:

{% highlight python %}
# Set up variables to hold the best score so far,
# and the word that generated it.
best_seen = (0, None)

# Try all possible words, saving the best one seen
for word in possible_words(my_letters):
  score = score_word(word)

  newest_seen = (score, word)
  best_seen = max(best_seen, newest_seen)
{% endhighlight python %}

Comparison and assignment are now handled all at once, making it less likely
that we will mix up one of the assignments.

There is one potential pitfall here: `max()` picks the tuple with the largest
first element (the score in our case). But, if the first elements are the
same, `max()` continues through the remaining elements until the tie is
broken. So if two words have the same score, `max()` will then compare the
words, which is does alphabetically.

If this is not what we want, we can have `max()` only compare the first value
by using the `key` parameter like this:

{% highlight python %}
# Set up variables to hold the best score so far,
# and the word that generated it.
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
that using the `key` argument as we did above. This time we use `score_word()`
as comparison function:

{% highlight python %}
words = possible_words(my_letters)
best_word = max(words, key=score_word)
{% endhighlight python %}

Which gives us a very compact (and relatively fool proof) pattern.
