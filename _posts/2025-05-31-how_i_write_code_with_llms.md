---
layout: post
title: How I Code With LLMs
description: >
  Over the past few years, I've experimented with coding alongside large language
  models. This post shares how I integrate them into my workflow.
image: /files/coding-llm/water_color_of_a_robot_writing_code.png
hide_lead_image: False
image_alt: >
  A colorful watercolor illustration on a white background of a robot sitting
  at a desk typing. A flat computer screen shows a dark background with
  colorful lines representing code.
categories:
  - generative-ai
  - large-language-models
  - machine-learning
---

{% capture file_dir %}/files/coding-llm{% endcapture %}

I've been writing code professionally for 20 years. I started with Java, moved
on to Python, then C++, Scala, and back to Python, with a smattering of shell
scripting, PHP, and Rust in between. I've written code with a pen and paper,
Vim, and a full IDE. Now, I'm exploring writing code with [large language
models (LLMs)][llms].

[llms]: https://en.wikipedia.org/wiki/Large_language_model

At work, I use [Codename Goose][goose], which can directly interact with my
local machine and files, switch between multiple LLM APIs, and connect to our
infrastructure with [Model Context Protocol (MCP)][mcp] servers. At home, I'm
more limited, but use GPT-4o and Gemini 2.5 Pro to generate code (that I have
to copy back and forth between my browser and terminal).

[goose]: https://block.github.io/goose/
[mcp]: https://en.wikipedia.org/wiki/Model_Context_Protocol

After intentionally trying to shoehorn LLMs into my workflow to see where and
how they work, this is what I've learned.

## System Prompt

The system prompt, which the model "reads" before it gets started, is how you
customize the way the model "thinks" and responds to you. I find a few things
are useful to include:

1. **A general overview of the task:** This gives the LLM context about where
   you're headed, even as it works line by line and file by file. "We're
   refactoring a Jekyll website...", "We're building a set of machine learning
   signals in Java 17...", etc.
2. **A layout of the project:** Locations of key files, what goes where, etc.
   Things like "a.py is where the main code lives, b.py provides helper
   functions..."
3. **A style guide:** Telling the LLM how you prefer to use the programming
   language. "Never use ternary operators", "Always use `{}` with if
   statements", "Prefer functional solutions", etc.

A trick I use is, at the end of a session, I give the LLM the current system
prompt and ask it to update it---adding anything new it learned and fixing
anything that's now out of date. Then I use that modified prompt when I spin
up a new LLM to work on the project.

## Unit Tests

English isn't a very precise way to define what you want code to do, but
that's usually where I start, maybe with a few example code snippets. After
that, I ask the model to write [unit tests][tests] for the code we just wrote.
This is where I make sure we're on the same page.

[tests]: https://en.wikipedia.org/wiki/Unit_testing

I read through the unit tests and look for anything that doesn't match what I
was expecting. Sometimes it's easy to just change the test to match the
behavior I want. Other times, I try to understand why the LLM made the choice
it did, then discuss the decision with it to come to an agreement. I often
catch disagreements over when to throw errors, how to handle invalid inputs,
or other rare edge cases in this process.

Once the behavior is codified in the tests, I ask the model to fix the
original code so the tests pass. In this way, it's sort of an inverse of
[test-driven development][tdd]---I have the computer write the code and then
the tests. I find that having some code to start with helps the LLM write
broader, more useful tests.

[tdd]: https://en.wikipedia.org/wiki/Test-driven_development

In some cases, I'll even throw away the code, restart the LLM, and give it
just the tests as the spec for what it should write. This is particularly
useful when the model gets stuck and either won't make a large enough change
to the code, or loops back and forth between essentially the same few
versions.

## Iterate And Advise

When I'm working with an LLM, I see my job more as a manager or mentor than an
engineer. My role is to define what we're doing, then critique the result to
get it into shape. It's a lot like working with a junior engineer or
intern---except one that can make a revision in 10 seconds instead of 4 hours.
This lets me iterate a lot to get the code working exactly how I want.

The things I focus on are mostly high-level, like data structures and
algorithms. The LLM often doesn't need a lot of direction---just saying
"Couldn't we replace the double for loop with a single loop and a hash table?"
is usually enough to get it on the right path. Only at the end, once the
structure is solid, do I focus on nitpicky issues or edit the text directly.

## The Future

I'm still learning how to use LLMs for coding. The technology and tooling is
evolving so fast that I'm sure what I'm doing today will look antiquated in
six months. Still, I hope it gives others some ideas about how they can
use this technology to speed up their development.
