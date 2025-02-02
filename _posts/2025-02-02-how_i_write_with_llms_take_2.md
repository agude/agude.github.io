---
layout: post
title: How I Write with Large Language Models
description: >
  OpenAI's ChatGPT is viewed as entertaining but not useful because it makes
  up facts. But I find it incredibly valuable for writing. Here is how I use
  it.
image: /files/chatgpt/202502001-robot.jpg
hide_lead_image: False
image_alt: >
  A colorful watercolor illustration on a white background of a robot sitting
  at a desk writing with a pen. He has a desklamp and a cup with pens in it.
categories:
  - generative-ai
  - machine-learning
---

{% capture file_dir %}/files/chatgpt{% endcapture %}

ChatGPT 3.5 came out just over 2 years ago and kicked off a Large Language
Model (LLM) renaissance. Dozens of companies released the own models and the
state of the art advanced by the hour.

At the time, [I wrote about how I used ChatGPT to write][previous_post]. My
method was primitive. With years of experience and model advancements, I have
refined how I use LLMs for editing text. Here is my new method.

[previous_post]: {% post_url 2023-02-13-how_i_write_with_chatgpt %}

## Drafting

I still write the first draft entirely by hand. I find this helps preserve my
voice and keep the writing from being pulled too much by the LLM. It also
achieves the main goal of why I write: to help clarify my thinking. But
whereas I used to write, edit, write, edit, write, edit, etc. until I was
close to 100% happy with my text, I now stop this cycle earlier and add in an
LLM editing pass.

I find that the thing I like least about my early drafts---the flow between
ideas is clunky---is one of the things LLMs are best at fixing, since they
excel at making writing closer to the average, smoothing out rough edges.

## The Prompt

The prompt is important. It is what keeps the LLM from completely filling my
prose with ["delve", "showcasing", and "underscores"][ars]. The prompt I
currently use is this:

> Help me edit this blog post I'm writing. Fix errors, make it clearer. Reword
> to make the arguments and sentences more coherent. Use the same sort of
> words I'm using, don't substitute fancy synonyms. Maintain my voice. My work
> is below. Keep the formatting and wrap your output in \`\`\`.

[ars]: https://arstechnica.com/ai/2024/07/the-telltale-words-that-could-identify-generative-ai-text/

## Editing

I then put both versions---mine and the machine's---side-by-side and compare.
In some cases, the edited version is great and I'll take a paragraph wholesale.
In others, I'll take some ideas about how to structure a paragraph or a
transition but rewrite it. Other times the LLM tries to fix what isn't broken
and I ignore it.

The oddest failure mode though is that sometimes that LLM doesn't do enough. I
know when my writing is really really bad, and sometimes those parts won't get
touched.
