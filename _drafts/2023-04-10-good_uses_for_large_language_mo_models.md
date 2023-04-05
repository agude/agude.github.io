---
layout: post
title: When Are Large Language Models Useful?
description: >
  OpenAI's ChatGPT is viewed as entertaining but not useful because it makes
  up facts. But I find it incredibly valuable for writing. Here is how I use
  it.
image: /files/chatgpt/00137-2463433472-watercolor_illustration_adorable_robot_desk_lamp_sitting_at_a_typewriter_chair_desk_clear_straight_lines.jpg
hide_lead_image: False
image_alt: >
    'A colorful watercolor illustration of a robot sitting at a desk with a
    typewriter infront of the robot. Generated with stable diffusion. Prompt:
    watercolor illustration, adorable robot, desk lamp, sitting at a
    typewriter, chair, desk, clear, straight lines'
categories: 
  - machine-learning
---

{% capture file_dir %}/files/chatgpt{% endcapture %}

Large language models (LLMs) like [ChatGPT][chatgpt] from [OpenAI][oai], Bing
Chat from Microsoft, and Bard from Google.

[chatgpt]: https://en.wikipedia.org/wiki/ChatGPT
[oai]: https://en.wikipedia.org/wiki/OpenAI

I gave an example in my last post of a good application for LLMs: [editing
prose][last_post]. But what specifically makes this problem ideal for solving
with a model? Succinctly, it is a problem **where solving it is hard, but
verifying the solution is easy**. I will go into more detail in the rest of
this post.

[last_post]: {% post_url 2023-02-13-how_i_write_with_chatgpt %}

## What Are They Good For?

In math, there are a types of problems where finding a solution is difficult
or impossible, but confirming a solution is easy. A common strategy to solve
these problems is to guess the solution's form and then verify it, such as for
an integral where the solution can be verified by taking its derivative.

Large language models are particularly useful for exactly these types of
tasks: **where generating a solution is hard, but verifying it is easy**.
Editing a paragraph is a prime example of this kind of task since writing
multiple versions is time-consuming, whereas verifying the quality of a single
paragraph can be done quickly.

## What Are They Bad For?

LLMs are **bad for problems where verification is hard** compared to the
generation of an answer.

Some people are using LLMs as a replacement for search engines. This is a
perfect example of a **bad use** of the technology because verifying the
accuracy of the information provided by the model takes time and effort. In
fact, it often involves additional searches to confirm the validity of the
answer, which defeats the purpose of using an LLM in the first place.
