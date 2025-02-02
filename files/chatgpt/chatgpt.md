---
layout: page-not-on-sidebar
title: How I Write with Large Language Models (LLM Draft)
description: >
  OpenAI's ChatGPT is often seen as merely entertaining because it sometimes makes
  up facts. But I find it incredibly valuable for writing. Here's how I use it.
image: /files/chatgpt/202502001-robot.jpg
hide_lead_image: False
image_alt: >
  A colorful watercolor illustration on a white background of a robot sitting
  at a desk writing with a pen. He has a desklamp and a cup with pens in it.
---

{% capture file_dir %}/files/chatgpt{% endcapture %}

**Back to the original:**

{% capture url %}{% post_url 2025-02-02-how_i_write_with_llms_take_2 %}{% endcapture %}
<div class="card-grid">
  {% include auto_article_card.html url=url %}
</div>

ChatGPT 3.5 came out just over two years ago and sparked a surge in Large
Language Model (LLM) development. Dozens of companies released their own
models, and the state of the art advanced by the hour.

At the time, [I wrote about how I used ChatGPT to write][previous_post]. My
method was primitive. With years of experience and improvements in the models,
I have refined how I use LLMs to edit text. Here is my updated method.

[previous_post]: {% post_url 2023-02-13-how_i_write_with_chatgpt %}

## Drafting

I write the first draft entirely by hand. This helps me preserve my voice and
prevents the writing from being overly influenced by the LLM. It also supports
my main goal: clarifying my thinking. Whereas I used to write, edit, write,
edit, and so on until I was nearly 100% happy with my work, I now stop earlier
and let the LLM handle an editing pass. This is because the aspect I like
least about my early drafts---how my paragraphs transition from one to the
next---is something LLMs excel at fixing. They also catch spelling and
grammatical errors that simpler programs might miss.

## The Prompt

The prompt you use with the LLM is crucial because it shapes how the model
edits your writing. The prompt keeps the machine from replacing my writing
with overused phrases like ["delve", "showcasing", and "underscores"][ars]. I
currently use a slight variation of this prompt:

> Help me edit this blog post I'm writing. Fix errors, make it clearer. Reword
> to make the arguments and sentences more coherent. Use the same sort of
> words I'm using, don't substitute fancy synonyms. Maintain my voice. My work
> is below. Keep the formatting and wrap your output in \`\`\`.

[ars]: https://arstechnica.com/ai/2024/07/the-telltale-words-that-could-identify-generative-ai-text/

## Editing

Once I have the LLM's version, I put it side-by-side with my draft to compare.
Sometimes the edited version is spot-on, and I'll adopt an entire paragraph as
is. Other times, I'll borrow ideas for restructuring a paragraph or crafting a
transition, but I rewrite it in my own words. There are also cases when the
LLM tries to fix something that's already fine, and I simply ignore it.

After that, I go through another human editing pass to ensure my voice remains
in every sentence. Occasionally, I will have the LLM focus on specific
sentences or paragraphs that still need work. Once I'm satisfied, I commit my
changes and publish.
