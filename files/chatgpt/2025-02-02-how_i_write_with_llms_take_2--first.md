---
layout: page-not-on-sidebar
title: How I Write with Large Language Models (My Draft)
description: >
  OpenAI's ChatGPT is viewed as entertaining but not useful because it makes
  up facts. But I find it incredibly valuable for writing. Here is how I use
  it.
image: /files/chatgpt/202502001-robot.jpg
hide_lead_image: True
permalink: /blog/how-i-write-with-llms-revised/first-draft/
redirect_from: /files/chatgpt/2025-02-02-how_i_write_with_llms_take_2--first/
image_alt: >
  A colorful watercolor illustration on a white background of a robot sitting
  at a desk writing with a pen. He has a desklamp and a cup with pens in it.
---

{% capture file_dir %}/files/chatgpt{% endcapture %}

**Back to the original:**

{% capture url %}{% post_url 2025-02-02-how_i_write_with_llms_revised %}{% endcapture %}
<div class="card-grid">
  {% article_card_lookup url=url %}
</div>

ChatGPT 3.5 came out just over 2 years ago and kicked off a storm of Large
Language Model (LLM) development. Dozens of companies released the own models
and the state of the art advanced by the hour.

At the time, [I wrote about how I used ChatGPT to write][previous_post]. My
method was primitive. With years of experience and model advancements, I have
refined how I use LLMs for editing text. Here is my new method.

[previous_post]: {% post_url 2023-02-13-how_i_write_with_chatgpt %}

## Drafting

I write the first draft entirely by hand. I find this helps preserve my voice
and keep the writing from being pulled too much by the LLM. It also achieves
the main goal of why I write: to help clarify my thinking. But whereas I used
to write, edit, write, edit, write, edit, etc. until I was close to 100% happy
with my work, I now stop earlier and add in an LLM editing pass, because the
thing I like the least about my early drafts---generally how my paragraphs
flow from one to the next---is something LLMs are quite good at fixing. They
are also great at fixing spelling and grammatical errors that less
sophisticated programs miss.

## The Prompt

The prompt you use with the LLM is important, as it defines how the model will
edit your writing. The promp is what keeps the machine from completely filling
my writing with ["delve", "showcasing", and "underscores"][ars]. I use slight
variations of this prompt currently:

> Help me edit this blog post I'm writing. Fix errors, make it clearer. Reword
> to make the arguments and sentences more coherent. Use the same sort of
> words I'm using, don't substitute fancy synonyms. Maintain my voice. My work
> is below. Keep the formatting and wrap your output in \`\`\`.

[ars]: https://arstechnica.com/ai/2024/07/the-telltale-words-that-could-identify-generative-ai-text/

## Editing

Once I have the LLM's version, I put it side-by-side with mine to compare. In
some cases, the edited version is great and I'll take a paragraph wholesale.
In others, I'll take some ideas about how to structure a paragraph or a
transition but rewrite it. Other times the LLM tries to fix what isn't broken
and I ignore it.

After that I go through and do another human editing pass, just to make sure
my voice comes through in each sentence. Sometimes I'll go through another
full pass with the LLM, but more often I'll have it focus on specific
sentences or paragraphs that I still don't like. Once I'm happy, I commit my
changes and publish.


