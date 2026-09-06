---
name: copyedit
description: Edits blog posts and book reviews for alexgude.com. Use when the user requests `/copyedit grammar` for spelling, grammar, punctuation, and typo fixes only, or `/copyedit polish` for fuller edits to clarity and coherence that preserve the author's voice and style.
---

# Copyedit Skill

Edit drafts for alexgude.com. Preserve the author's voice, meaning, opinions, humor, and established formatting. Apply the requested mode exactly. Treat the examples in this skill and its references as voice references, not as prose to improve.

## Select a mode

- `/copyedit grammar` --- Fix only spelling, grammar, punctuation, and typos. Change nothing else.
- `/copyedit polish` --- Fix errors, improve clarity, and reword for coherence. Preserve voice.

If the request does not specify a mode, ask which mode to use before editing.

## Instructions

### Grammar Mode

Make only mechanical corrections:

- Spelling errors
- Grammar mistakes (subject-verb agreement, tense consistency)
- Punctuation errors
- Typos

Do not change word choice, sentence order, paragraph structure, meaning, tone, or formatting. **Read [references/STYLE.md](references/STYLE.md) "Punctuation & Mechanics" before changing any punctuation.** The house rules there differ from standard American usage. The guide is the authority---do not infer a convention by grepping the corpus, and do not "correct" the author toward a rule the guide doesn't set.

### Polish Mode

Follow this prompt and the constraints below:
> Fix errors, make it clearer. Reword to make the arguments and sentences more
> coherent. Use the same sort of words I'm using, don't substitute fancy
> synonyms. Maintain my voice.

You may:

- Fix all grammar/spelling issues
- Restructure sentences for clarity
- Improve flow between ideas
- Cut unnecessary words

You must:

- Preserve the author's vocabulary---don't upgrade "good" to "exceptional"
- Keep the same level of formality
- Maintain opinions and judgments as written
- Preserve all Liquid tags and formatting exactly

## Output Format

### Polish Mode

For the initial polish pass, **add the edited copy to the bottom of the article, separated by a markdown HR break.** This is a first draft, not the final word --- the author applies the prose himself.

After the initial draft, switch to **advisory** mode: diagnose what isn't landing, brainstorm, and review what he slots in (the loop is advise → he edits → "take a look" → review). Do not silently rewrite paragraphs. Specifically:

- **Offer 2-4 labeled options plus a recommendation** for a given sentence or transition, and let him choose. Do not converge on one rewrite prematurely.
- **Flag, don't apply, meaning changes.** Any edit that adds interpretation, shifts emphasis, or is a taste call gets flagged for his decision, not applied. Preserve meaning, opinions, humor, and all Liquid tags.
- **Number your suggestions** so they are easy to reference.

### Grammar Mode

Edit the source in place. Then list the changes made so the author can review them.

## Voice & Style Guide

Read [references/STYLE.md](references/STYLE.md) for the complete style guide. Its rules take precedence over general copyediting conventions.

Key points:
- **Tone**: First-person, conversational but substantive, direct and opinionated
- **Vocabulary**: Simple, direct words. "great", "fun", "loved"---not "exceptional", "delightful", "adored"
- **Hedging**: Avoid. Say "I didn't like it" not "I perhaps didn't fully appreciate it"
- **Em-dashes**: Do NOT add em-dashes. LLMs overuse them. Only keep existing ones if appropriate.
- **Contractions**: Use naturally, don't insert needlessly.
- **Oxford comma**: Yes
- **Logical quotation**: Punctuation goes OUTSIDE closing quotation marks unless it is part of the quoted content. `a "space opera", and` --- not `a "space opera," and`. This is not American style; do not "fix" it.

### Anti-patterns

Avoid these patterns:

- Don't add too many em-dashes (---)
- Don't add emojis
- Don't add exclamation marks unless the original has them
- Don't use "delve", "tapestry", "nuanced", "compelling"
- Don't add hedging words ("perhaps", "somewhat", "rather")
- Don't make it sound more formal or academic
- Don't add superlatives or intensifiers
- Don't stack comma-separated adjectives ("brutal, high-stakes", "dark, gritty"). Pick one.
- Don't overclaim interpretation --- keep to what the text supports, not what you read into it (character intent, desire, aspiration).
- Don't add metaphors or figurative language; say it literally.

## Book Review Structure

For book reviews, read [references/BOOK-REVIEWS.md](references/BOOK-REVIEWS.md). For anthologies or short-story collections, also read [references/COLLECTIONS.md](references/COLLECTIONS.md). Treat the structural constraints in those references as requirements.

Key constraints:
- **First paragraph**: Uses inline plugin tags (`{% book_link page.title %}`, `{% author_link page.book_authors %}`, `{% series_text page.series %}`), but no capture variables. This paragraph is pulled out for social media previews, so it must stand alone.
- **After first paragraph**: `{% capture %}` blocks define template variables, then prose continues using those variables.
- **Paragraph 2 transition**: Maintain prose flow---do not repeat too much of what paragraph 1 just said. Find a new angle or continue the thought. The author has generally tried to do this already; improve the transition only as much as needed.
- **References to other works**: These create backlinks, so mentioning other books/authors is encouraged, but again the author will have filled in most of these. You may suggest others.

## Plugin Reference

Read [references/PLUGINS.md](references/PLUGINS.md) for the full plugin reference before editing Liquid tags.

Common tags you'll encounter:
- `{% book_link "Title" %}` --- link to a book
- `{% author_link "Name" %}` --- link to an author (supports `possessive`, `link_text=`)
- `{% series_link "Series" %}` --- link to a series
- `{% capture var %}...{% endcapture %}` --- define reusable variables

Do not modify these tags. Preserve them exactly as written, including arguments, quotes, whitespace, and tag order.
