---
layout: post
title: "How I Code With LLMs:<br>Reverse Test Driven Development"
description: >
  OpenAI's ChatGPT 3.5 transformed my writing process when it came out. After
  years of experience using it, I've further refined my method of using LLMs.
  This post explains how.
image: /files/coding-llm/water_color_of_a_robot_writing_code.png
hide_lead_image: False
image_alt: >
  A colorful watercolor illustration on a white background of a robot sitting
  at a desk typing. A flat computer screen shows a darkbackground with
  colorful lines representing code.
categories:
  - generative-ai
  - large-language-models
  - machine-learning
---

{% capture file_dir %}/files/coding-llm{% endcapture %}

[first_draft]: {% link files/chatgpt/2025-02-02-how_i_write_with_llms_take_2--first.md %}
[llm_draft]: {% link files/chatgpt/2025-02-02-how_i_write_with_llms_take_2--llm.md %}

I've been writing code professionally for 20 years. I started with Java, moved
on to Python, then C++, Scala, and back to Python, with a smattering of shell
scripting, PHP, and Rust in between. I've written code with a pen and paper,
Vim, a full IDE. Now, I'm exploring writing code with [large language
models (LLMs)][llms].

[llms]: https://en.wikipedia.org/wiki/Large_language_model

At work, I use [Codename Goose][goose], which can directly interact with my
local machine and files, switch between multiple LLM APIs, and connect to our
infrastructure with [Model Context Protocol (MCP)][mcp] servers. At home I'm
more limited, but user GPT-4o and Gemini 2.5 Pro to generate code (that I have
to copy back and forth from my browser to my terminal).

[goose]: https://block.github.io/goose/
[mcp]: https://en.wikipedia.org/wiki/Model_Context_Protocol

## English Is Imprecise

I started by use prose, and maybe a few quick code examples, to tell the model
what I want it to write. I quickly realized this wasn't enough to specify how
the code should behave. As soon as got away from the rigorously defined
functionality, the LLM's assumptions and mine would differ. How should the
code handle empty inputs? Nulls? Illegal values? Should it throw errors or
just warn the user?

I realized [Unit tests][tests] are much more precise definitions of behavior.

[tests]: https://en.wikipedia.org/wiki/Unit_testing

## Website

This website is built using Jekyll, which is written in Ruby. But I don't know
Ruby. At all. So for a decade I was writing all the logic---finding pages for
the sidebar, automating links to articles, etc.---in the templating language
Liquid. It's slow, error prone, impossible to test. My site took minutes to
build.

Over the past few weeks I've used Gemini 2.5 to re-write all the Liquid into
Ruby plugins, write tests, and update my build to system. My site now builds
in under 5 seconds and we caught a bunch and fixed a bunch of bugs.

## TDD

How [test-driven development][tdd] generally works is you think about what you
want your code to do, then write a test to cover that function, then write the
simplest code to get it to pass. How inverse test driving development works is
you get an LLM to write the code, then have it write the tests for the code,
then you verify the tests, and 

[tdd]: https://en.wikipedia.org/wiki/Test-driven_development

