---
layout: post
title: How I Write with ChatGPT
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
  - generative-ai
  - machine-learning
---

{% capture file_dir %}/files/chatgpt{% endcapture %}

[ChatGPT][chatgpt], the new chatbot from [OpenAI][oai], has received
widespread attention for its versatility in conversation, information
retrieval, and even song writing. However, it's tendency to generate false but
believable information has led many to see it as _entertaining_ but not
_useful_.[^edit_1]<sup> (Click to see my edit prompts.)</sup>

[chatgpt]: https://en.wikipedia.org/wiki/ChatGPT
[oai]: https://en.wikipedia.org/wiki/OpenAI

But ChatGPT is an **incredibly useful tool** for my writing due to its ability
to rapidly iterate through alternative phrasings for ideas, sentences, and
paragraphs. In this cases, the model's habit of generating false information
is not a concern because I wrote the original input so I know what it should
say, and I can easily edit out any inaccuracies introduced by the
model.[^edit_2]<sup>, </sup>[^edit_3]

Let me illustrate how I use ChatGPT to write and copyedit my work.[^edit_4]

## My Writing Process

I start by writing a rough draft which may consists of a few bullet points or
a detailed set of paragraphs. Next, I give it to ChatGPT for refinement.

{% comment %}These div, etc. match chatgpt_edit.html {% endcomment %}
<div class="chatgpt-edit-block">
<div class="chatgpt-prompt">
<strong>Prompt</strong>
<div class="chatgpt-prompt-only" markdown="1">
> Give me three versions of this paragraph: 
>
> I start by writing a rough draft. This draft could be a just a few bullet
> points or completely fleshed out paragraphs. I then feed it into ChatGPT:
</div>
</div>

<div class="chatgpt-output">
<strong>Output</strong>
<div class="chatgpt-output-only" markdown="1">
> 1. I begin my writing process with a rough draft, which may range from a
>    simple list of bullet points to fully developed paragraphs. Next, I input
>    it into ChatGPT.
> 2. My writing method starts with a rough draft - it could be a brief outline
>    or a detailed set of paragraphs. Afterwards, I pass it to ChatGPT.
> 3. To start, I create a preliminary draft - it may consist of a handful of
>    bullet points or fully written paragraphs. Afterwards, I utilize ChatGPT
>    to refine it further.
</div>
</div>
</div>

I don't usually take the entire output from ChatGPT, rather I use it to
inspire my own editing:[^edit_5]

> I start by writing a rough draft which may consists of a few bullet points
> or a detailed set of paragraphs. Next, I give it to ChatGPT for refinement.

I iterate using this process, refining my text by sending the sections I'm
unhappy with to ChatGPT for improvement until I'm satisfied.[^edit_6]

{% comment %}
These are incredibly sensitive to new lines. Any new line breaks the parsing
within the footnote, so they have to be shoved onto one line.
{% endcomment %}
[^edit_1]: {% include chatgpt_edit.html prompt="ChatGPT is the new large language model from OpenAI. It has garnered a lot of attention for its wide range of abilities from conversation to writing songs to information retrieval. It has also drawn criticism for its habit of making up plausible but completely wrong facts, leading many to conclude that while it is entertaining it is not useful." output="1. OpenAI's ChatGPT is a highly advanced language model that has received widespread attention for its diverse abilities, including conversation, songwriting, and information retrieval. However, its tendency to generate false information that appears credible has led to criticism and the conclusion that, although entertaining, it may not be practical.<br><br>2. ChatGPT, the new AI model from OpenAI, has captured considerable attention for its wide range of skills, such as conversation, songwriting, and information retrieval. Despite this, its propensity for producing believable but false facts has sparked criticism, and many view it as entertaining but not practical.<br><br>3. OpenAI's ChatGPT, a new and sophisticated language model, has drawn a lot of attention for its versatility in conversation, songwriting, and information retrieval. Despite this, it has also faced criticism for generating seemingly credible but completely false information, leading many to see it as entertaining but lacking practicality." %}

[^edit_2]: {% include chatgpt_edit.html prompt="I find ChatGPT to be incredibly useful as part of my writing process, because ChatGPT makes it fast and easy to generate different possible ways to write down an idea, sentence, or paragraph. In these cases the fact that the model makes things up is irrelevant because I wrote the original source material so I can filter out any inaccuracies the model introduces. " output="1. I consider ChatGPT to be a valuable tool in my writing process due to its ability to quickly and effortlessly generate various ways of phrasing an idea, sentence, or paragraph. In these cases, the fact that the model generates false information is not a concern as I am the originator of the source material and can easily identify and remove any inaccuracies introduced by the model.<br><br>2. For me, ChatGPT is an extremely useful aspect of my writing as it facilitates the rapid creation of alternative phrasings for ideas, sentences, or paragraphs. The model's tendency to generate false information is inconsequential in these scenarios as I am the source of the original material and can easily filter out any inaccuracies introduced by the model.<br><br>3. ChatGPT is an indispensable part of my writing process as it enables me to quickly generate various ways to express an idea, sentence, or paragraph. Its tendency to produce false information is not a problem as I am the writer of the original source material, and I can easily eliminate any inaccuracies introduced by the model." %}

[^edit_3]: {% include chatgpt_edit.html prompt="I have used 'tendency' too much already. Rewrite this five times, each time only replacing the word 'tendency' with another few words to maintain the meaning:<br><br>In these cases, the model's tendency to generate false information is not a problem because I wrote the original input so I know what it should say, and I can easily edit out any inaccuracies introduced by the model." output="1. In these cases, the model's habit of producing false information does not pose an issue because I created the original input and can easily remove any inaccuracies it may introduce.<br><br>2. In these scenarios, the model's inclination to generate false information is of no concern as I am the writer of the original material and can effectively edit out any inaccuracies introduced by the model.<br><br>3. The model's propensity for generating false information is not a concern in these instances as I am aware of the intended content of the original input and can efficiently remove any inaccuracies it may introduce.<br><br>4. The model's tendency to produce false information is not a hindrance in these situations as I am familiar with the original input and can effortlessly edit out any inaccuracies it generates.<br><br>5. The model's habit of creating false information is not problematic because I wrote the original input and can easily eliminate any inaccuracies the model introduces." %}

[^edit_4]: {% include chatgpt_edit.html prompt="Five versions of:<br><br>Let me show you how I use it to write and edit my work." output="1. Allow me to demonstrate how I utilize it in writing and revising my pieces.<br><br>2. Let me illustrate how I employ it in the creation and modification of my writing.<br><br>3. I will show you how I use ChatGPT for writing and editing my writing projects.<br><br>4. Let me reveal how I integrate it into my writing and editing process.<br><br>5. I will demonstrate to you the way I utilize it for writing and revising my work." %}

[^edit_5]: {% include chatgpt_edit.html prompt="Three versions of:<br><br>I generally don't take the full paragraph, but I use ChatGPT's versions to get ideas for my own:" output="1. I don't usually use the entire output from ChatGPT, but I do use it as inspiration for my own writing.<br><br>2. Typically, I don't adopt ChatGPT's output in its entirety, instead I draw ideas from it for my writing.<br><br>3. My approach is not to fully adopt the ChatGPT output, but rather use it to spark ideas for my own writing." %}

[^edit_6]: {% include chatgpt_edit.html prompt="Give me three versions of this:<br><br> I iterate on this process, taking parts of my text I'm not happy with and sending them to ChatGPT, until I like how the work flows." output="1. Revising my text with ChatGPT's help, I improve it piece by piece until I'm satisfied with the flow.<br><br>2. With the aid of ChatGPT, I repeat the process of refining my text by sending unsatisfactory portions for improvement until I achieve the desired flow.<br><br>3. I use ChatGPT to continuously refine my text, sending sections I'm unhappy with for improvement until I'm content with the overall flow." %}
