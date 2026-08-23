# Collection and Anthology Reviews

Structure rules specific to story-by-story reviews. Everything in
[BOOK-REVIEWS.md](BOOK-REVIEWS.md) still applies; this covers what differs.

## Distribute Themes Into Story Sections

The failure mode is a monstrous lead-in. The working pattern is a short
three-beat lead, then each theme assigned to the individual story section where
it has evidence.

Corollary: **a collection-level insight cannot be declared inside a story
section.** You cannot say "if X is Y in miniature" before X has been introduced.
Cross-story claims belong in the lead; the sections then just *are* the story.

## Section Length Tracks the Rating

A 2- or 3-star story gets two or three sentences; a 5 earns real paragraphs.
Stuffing references into a low-rated section inflates it past what the rating
warrants. When there is nothing to say, saying so briefly is the correct output.

To justify a low rating without sounding dismissive, say what is *missing*
rather than what is wrong ("Neither the idea nor the prose held my interest") —
it puts the verdict on the reader rather than the book.

## End on a Line, Not a Conclusion

Neither *State of the Art* nor *Valuable Humans* has a formal conclusion, and
*Burning Chrome* ends on the Gibson quote ("The street finds its own uses for
things") rather than a summary paragraph. A formal conclusion after
story-by-story sections mostly restates the lead.

When the closing line performs the thesis, that is stronger than restating it.
The trade-off to weigh: the standard "Up next is …" backlink is worth
something, so decide deliberately whether to give it up.

If the review ends on a rhetorical device — a right-aligned □ / QED tombstone
was used for the Ted Chiang collection — that commits the last sentence to
reading as a verdict. **Do not follow a hedge with the device.** A "still, when
he lands it…" softener plus a tombstone reads as a failure of nerve. Put the
author's due in the body sections, where it is evidence, and let the ending be
the verdict.

Two mechanics for that device:

- Use **U+25A1 □**, not U+220E ∎. The dedicated end-of-proof character has
  patchy font coverage and falls back to a tofu box that looks almost like the
  intended glyph but wrong.
- **Right-align it.** Flush left it reads as a stray character or an encoding
  artifact, because right is where math texts put it.

## "They All Feel the Same" Owes a Mechanism

"Feel the same" is a claim about sensation, unfalsifiable as stated, and the
single most common thing said about short story collections. If the paragraph
after it does not name a cause, a reader files it as a lazy take and stops
trusting the review.

Pick **one** primary diagnosis and make the other complaints its symptoms. A
structural claim ("these are proofs; they end with QED") is causal, while affect
words ("sterile") and consequence words ("no edge") are downstream of it. That
produces a review that explains rather than accumulates complaints.

The move that makes the setup work: **concede the strongest counterargument
before the blow lands.** "Every story is different, very different, but they all
*feel* the same" earns its turn precisely because the doubling sounds like it is
about to praise the range.

## Defend a Criterion by Showing It Is Not Ad Hoc

When a review marks a book down for being didactic, a reader can reasonably
suspect the standard was invented for that book. The defense is to show the same
criterion producing the same verdict from **opposite** directions: *Fahrenheit
451* (3) failed because its structure was too loose to reinforce its theme; a
Chiang collection fails because the structure is airtight and there is nothing
in it. Same standard, symmetric failures.

Related: **weigh the collection against its own parts.** A collection can score
below the average of its stories, and a reader doing the arithmetic will notice
— so say why in one sentence.

## Reading Fatigue Is Evidence, Not a Confound

Ratings in reading order for the Chiang collection were 4, 4, 3, 4 | 2, 3, 3, 3
— first half 3.75, second half 2.75, with the distributions touching only at 3.
That is a step function, not a wobble.

The instinct is to treat it as contamination ("my ratings are unreliable because
I got tired"). Invert it: **if the complaint is that the method is repetitive,
fatigue is the predicted outcome.** "I got bored" and "the method repeats" are
one fact seen from two sides. Saying "by the fifth story I could see the shape
from the first page" is stronger than pretending each story got a fresh reading
— admitting the fatigue is what licenses the thesis.

Check the confound explicitly, though: many collections are ordered
**chronologically by first publication**, so a decay curve has two possible
causes — reader fatigue, or the writer actually calcifying. The cleanest test is
the most-decorated story sitting late in the order: ask honestly whether it is a
4 if it opens the collection.

## Per-Story Markup

See [PLUGINS.md](PLUGINS.md) for `short_story_title` and `rating_stars`. Two
conventions specific to collections:

- **Per-story bylines** for co-written pieces use the raw div emitted by
  `_layouts/book.html`, placed immediately after the `###` heading with **no
  blank line** before `rating_stars`:

  ```liquid
  ### {% short_story_title "Ghosts" %}

  <div class="written-by">by {{ author_resnick }} and {{ author_malzberg }}</div>
  {% rating_stars 2 %}
  ```

  Text is `by ` plus linked `author_link` captures joined with a bare `and`;
  authors are pre-captured near the top of the file. `.written-by` has no CSS —
  it is semantic only. Solo stories get no byline. For a single-author
  collection with a few collaborations, name the primary author in each byline
  rather than writing a bare "by Shirley", or the byline reads as sole
  authorship.

- **Collection-vs-title-story collision:** `{% book_link "Burning Chrome" %}`
  and `{% short_story_link "Burning Chrome" %}` need distinct capture names
  (`burning_chrome_collection` vs `burning_chrome_story`), or the collection
  stays `this_book`.
