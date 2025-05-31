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
Vim, a full IDE. Now, I'm exploring writing code with [large language
models (LLMs)][llms].

[llms]: https://en.wikipedia.org/wiki/Large_language_model

At work, I use [Codename Goose][goose], which can directly interact with my
local machine and files, switch between multiple LLM APIs, and connect to our
infrastructure with [Model Context Protocol (MCP)][mcp] servers. At home, I'm
more limited, but user GPT-4o and Gemini 2.5 Pro to generate code (that I have
to copy back and forth from my browser to my terminal).

[goose]: https://block.github.io/goose/
[mcp]: https://en.wikipedia.org/wiki/Model_Context_Protocol

After intentionally trying to shoe-horn LLMs into my workflow to see where and
how they work, this is what I've learned.

## System Prompt

The system prompt, which the model "reads" before it gets started, is how you
customize the way that the models "thinks" and responds to you. I find a few
things are useful to include:

1. **A general overview of the task:** This gives the LLM context about where
   you are headed, even as it works line by line and file by file. "We're
   refactoring a Jekyll website...", "We're building a set of machine learning
   signals in Java 17...", etc.
2. **A layout of the project:** Locations of key files, what goes where, etc.
   Things like "a.py is where the main code lives, b.py provides helper
   functions..."
3. **A style guide:** Telling the LLM how you prefer to use the programing
   language. "Never use terniary operators", "Always use `{}` with if
  statements", "Prefer functional solutions", etc.

A trick I use is at the end of a session I give the LLM the current system
prompt and ask it to update it by by adding any new things it learned and
fixing any information that is now out of date. Then I use that modified
prompt when I spin up a new LLM to work on the project.

## Unit Tests

English isn't a very precise way to define what you want code to do, but
that's what I start with on most projects, with maybe a few example code
snippet. After that, I ask the model to write [unit tests][tests] for the code
we just wrote. This is where I make sure we're on the same page.

[tests]: https://en.wikipedia.org/wiki/Unit_testing

I read through the unit tests and look for anything that doesn't match what I
was expecting. In some cases it's simple to just change the test to the
behavior I want, but in others I try to understand why the LLM made the choice
it did and then discuss the decision with the model to come to an agreement.

Once the behavior is codfieid in the tests, I ask the model to fix the
original code so the tests pass. In this way, it is sort of inverse
[test-driven development][tdd]---I have the computer write the code and then
the tests. I find having some code to work from makes the LLM write broader
tests. In some extreme examples I'll throw away the code, restart the LLM,
and give it just the tests to define what it should write.

[tdd]: https://en.wikipedia.org/wiki/Test-driven_development

## Iterate And Advise

When I'm working with an LLM, I view my job more as a manager or mentor than
engineer. My job is to define what we're doing, then critique the result to
get it into shape. It's a lot like working with a junior engineer or intern,
except one that can make a revision in 10 seconds instead of 4 hours.

The things I focus on are mostly high-level, like data structures and
algorithms. Often the LLM doesn't need a lot of guidance, simply saying
"Couldn't we replace the double for loop with a single loop and a hash table?"
will get it to on the right path. Only at the end, when our code is structured
correctly, will I focus on nit-picky issues or even edit the text directly.
