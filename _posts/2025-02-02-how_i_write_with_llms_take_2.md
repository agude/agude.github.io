---
layout: post
title: How I Write with Large Language Models
description: >
  OpenAI's ChatGPT 3.5 transformed my writing process when it came out. After
  years of experience using it, I've further refined my method of using LLMs.
  This post explains how.
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

_This is the final version of the post, refined through the editing process I
describe below. You can see my starting point by [reading my first
draft][first_draft] and comparing it with the [LLM-edited draft][llm_draft]._

[first_draft]: {% link files/chatgpt/2025-02-02-how_i_write_with_llms_take_2--first.md %}
[llm_draft]: {% link files/chatgpt/2025-02-02-how_i_write_with_llms_take_2--llm.md %}

ChatGPT 3.5 came out just over two years ago and sparked an explosion in Large
Language Model (LLM) development. Dozens of companies released their own
models, and the state of the art advanced by the hour.

At the time, [I wrote about how I used ChatGPT to write][previous_post]. My
method was primitive. With years of experience and improvements in the models,
I have refined how I use LLMs to edit text. Here is my new method.

[previous_post]: {% post_url 2023-02-13-how_i_write_with_chatgpt %}

## Drafting

I write the first draft entirely by hand. This helps me preserve my voice and
prevents the writing from being overly influenced by the LLM. It also supports
my main goal of writing: to clarify my thinking.

I used to write, edit, write, edit, and so on until I was nearly 100% happy
with my work, but now I stop earlier and let the LLM handle an editing pass.
Using the LLM early saves me multiple rounds of edits because they've become
so good at fixing spelling and grammatical errors and slightly tweaking my
writing without overpowering it.

## The Prompt

The prompt you use with the LLM is important, because it strongly shapes how
the model edits your writing. The prompt keeps the machine from filling my
writing with phrases like ["delve", "showcasing", and "underscores"][ars]. I
currently use a slight variations of this prompt:

> Help me edit this blog post I'm writing. Fix errors, make it clearer. Reword
> to make the arguments and sentences more coherent. Use the same sort of
> words I'm using, don't substitute fancy synonyms. Maintain my voice. My work
> is below. Keep the formatting and wrap your output in \`\`\`.

[ars]: https://arstechnica.com/ai/2024/07/the-telltale-words-that-could-identify-generative-ai-text/

## Editing

Once I have the LLM's version, I put it side-by-side with my draft to compare.
Sometimes the edited version is perfect, and I'll take an entire paragraph as
is. Other times, I'll borrow ideas about how to structuring a paragraph or a
transition, but I rewrite it in my own words. The model sometimes tries to fix
sections that are fine, and I simply ignore it.

After that, I go through another human editing pass to ensure my voice comes
through in every sentence. Sometimes, I will have the LLM focus on specific
sentences or paragraphs that still need work and iterate. Once I'm happy, I
commit my changes and publish.
