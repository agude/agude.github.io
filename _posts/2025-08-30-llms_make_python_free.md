---
layout: post
title: LLMs Make Python Scripts Free
description: >
    I used to spend hours writing and saving little Python scripts. Now, with
    LLMs, I can get the same code in under a minute. Python scripts, and small
    programs in general, are effectively free.
image: /files/llm-free-python/a_robot_sells_pythons_of_many_colors.png
hide_lead_image: False
image_alt: >
    A watercolor cartoon illustration of a cheerful robot giving away free
    pythons. On the left, a smiling light-blue robot with antennae stands
    behind a wooden counter with a cash register that displays "$0." A sign
    next to the register reads, "HAPPY PYTHONS - FREE!" The robot has one arm
    outstretched towards the right, where a small market stall with a striped
    awning stands. The stall has two shelves filled with small, colorful, and
    smiling cartoon pythons in various patterns and colors, including green,
    yellow, orange, and blue. The background is entirely white.
categories:
  - generative-ai
  - large-language-models
  - machine-learning
  - python
---

{% capture file_dir %}/files/coding-llm{% endcapture %}

I first learned Python in 2005. My mentor at the time, Nao Sazuki, was
training me to do cosmology research and decided it would be a better use of
my time to learn Python instead of IDL. He also told me something that changed
how I thought about computers:

> A computer's job is to do work for you.

I hadn't realized that before. Until I learned to program, computers could
only do a small set of things for me---mainly the things other people had
already decided they should do. But when I learned to code, I suddenly had the
ability to make them do what I wanted.

Within a year I'd learned Python, picked up Vim, and switched my computers to
Ubuntu. I started writing little scripts to make my life easier, like backing
up my email, syncing files between my laptop and desktop, or converting
Wikipedia pages into an archival format.

Back then, each script took me hours to write. I had to find the right
libraries, learn their APIs, or sometimes write code from scratch. Because
they took so much work I saved every one, sometimes even sharing them with the
opensource community, just in case I ever needed them again. But all of that
changed in the last two years when I [learned to use an LLM for
coding][using_llms].

[using_llms]: {% post_url 2025-05-31-how_i_write_code_with_llms %}

Now a Python script takes 30 seconds. Maybe a minute if I want to read it over
and give some feedback. Gemini 2.5 Pro _almost always_ writes a 100-line
script correctly on the first try, just from a short description of what I
want. It's so fast and easy that I've stopped saving them---if I need another
one, I can just prompt for it again in half a minute.

{% capture gibson %}{% author_link "William Gibson" %}{% endcapture %}

**Python scripts are now free!**[^also] But I don't think everyone has
realized this yet. Once again, {{ gibson }} was right:

> The future is already here -- it's just not very evenly distributed.

[^also]: And not just Python, but any 300-line piece of code! I used Gemini to
    completely re-write the backend of this blog in pure Ruby, cutting build
    times from minutes to seconds, adding hundreds of tests to define and
    enforce behavior, and I don't even know Ruby!
