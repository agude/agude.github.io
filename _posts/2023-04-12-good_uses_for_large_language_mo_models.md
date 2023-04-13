---
layout: post
title: When Are Large Language Models Useful?
description: >
  Large language models (LLMs) are incredibly valuable tools, but they're not
  for everything. Here's a simple rule to know when to use them and when to
  avoid them.
image: /files/chatgpt/00259-1343806484-A_drawing_of_a_cute_robot_color_writing_with_a_pen_sitting_at_a_desk.jpg
hide_lead_image: False
image_alt: >
    A colorful illustration of a two robots sitting at a desk with with
    empty paper and books infront of them. One is holding a pencil. Generated 
    with stable diffusion. Prompt: A drawing of a cute robot, color, writing 
    with a pen, sitting at a desk
categories: 
  - machine-learning
---

{% capture file_dir %}/files/chatgpt{% endcapture %}

Large language models (LLMs) like [ChatGPT][chatgpt], [Bing Chat][bing], and
[Bard][lambda] have gained tremendous popularity in recent months. It feels
like a pivotal moment in the technology's growth as it becomes increasingly
integrated into people's workflows. But despite the excitement, some people
are already dismissing the technology after they asked it questions and
received nonsensical responses. I think they are mistaken. LLMs are incredibly
valuable tools, _if_ you know when to use them.

[chatgpt]: https://en.wikipedia.org/wiki/ChatGPT
[bing]: https://en.wikipedia.org/wiki/GPT-4#Microsoft_Bing
[lambda]: https://en.wikipedia.org/wiki/LaMDA

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
an integral where the solution can be checked by taking its derivative.

Large language models are particularly useful for exactly these types of
tasks: **where generating a solution is hard, but verifying it is easy**.
Editing a paragraph is a prime example of this kind of task since writing
multiple versions is time-consuming, whereas verifying the quality of a single
paragraph can be done quickly.

Another good use case is writing code, especially if you have tests in place
to verify the code's correctness.

## What Are They Bad For?

LLMs are **bad for problems where verification is hard** compared to the
generation of an answer.

Some people are using LLMs as a replacement for search engines. This is a
perfect example of a **bad use** of the technology because verifying the
accuracy of the information provided by the model takes time and effort. In
fact, it often involves additional searches to confirm the validity of the
answer, which defeats the purpose of using an LLM in the first place.
