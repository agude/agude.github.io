---
layout: post
title: LLMs Make Python Scripts Free
description: >
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
training me to do cosmology research and he decided that it was a better use
of my time to learn Python than IDL. He also told me something that changed my
view of computers:

> A computer's job is to do work for you.

I hadn't realized that before, because before I learned to program, computers
could only do a small number of things for me, mainly things that other people
had already decided they should do. But when I learned to code, I was suddenly
able to make them work the way I wanted them to.

Within a year I'd learned Python, picked up Vim, and started running Ubuntu on
my computers. I started writing small little scripts to make my life easier,
like backing up my email, synchronizing my laptop and desktop files, or
converting Wikipedia pages to an archival format.

It used to take me hours to write scripts, as I found the libraries I needed,
learned how to use their APIs, or even wrote them from scratch. But all that
change in the last two years when I [learned to us an LLM for
coding][using_llms].

[using_llms]: {% post_url 2025-05-31-how_i_write_code_with_llms %}

Now a Python script takes 30 seconds. Maybe a minute if I have to read through
it and offer some feedback. Gemini 2.5 Pro _almost always_ writes a 100 line
Python script correctly the first time, just from a brief description of what
I want. It is so fast and easy I've stopped saving them---if I want another
one, I can prompt it in 30 seconds.

{% capture gibson %}{% author_link "William Gibson" %}{% endcapture %}

**Python scripts are now free!**[^also] But I'm not sure everyone has figured this
out yet. Once again, {{ gibson }} was right:

> The future is already here -- it's just not evenly distributed.

[^also]: And not just Python, but any 300-line piece of code! I used Gemini to
    completely re-write the backend of this blog in pure Ruby, taking build
    time down from minutes to seconds, adding in hundreds of tests to define
    and ensure behavior, and I don't know Ruby!
