---
layout: post
title: Using Large Language Models to clean data
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
redirect_from: blog/good-uses-for-large-language-mo-models/
categories: 
  - generative-ai
  - machine-learning
---

{% capture file_dir %}/files/chatgpt{% endcapture %}

I maintain the [SWITRS-to-sqlite][s2s] Python library that parses and cleans
up California Highway Patrol traffic collision database. One of the fields the
officers have to fill out at the scene of the crash is the brand[^make] of the
car. This field is a free text field, but there is a very limited number of
common brands, so it should be converted to a categorical variable.

[^make]: Referred to in America as the "make" of the car.

[s2s]: {% post_url 2016-11-01-switrs_to_sqlite %}

This is easy when the officer writes `FORD` or `HONDA`, which they mostly do.
But since they can write anything they occasionally make it a little harder on
us by abbreviating or mistyping, for example `VOLX` and `DODDGE`. And
sometimes they make it impossible by writing `--` or `______`.

The solution is to go through, one by one, and create a mapping like:

```python
@unique
class Make(Enum):
    CHEVROLET  = "chevrolet"
    HINO       = "hino"
    INFINITI   = "infiniti"
    GMC        = "gmc"
    MITSUBISHI = "mitsubishi"
    # Special Token for unknown
    NONE       = None

MAKE_MAP = {
  "CHEVRLT":  Make.CHEVROLET,
  "HINO/":    Make.HINO,
  "INFINITY": Make.INFINITI,
  "MITSUB":   Make.MITSUBISHI,
  "TAHOE":    Make.GMC,
  "UKNOWN":   Make.NONE,
}
```

But making this mapping is tedious---I should know, [I did it for over 900 entries][git].

[git]:  https://github.com/agude/SWITRS-to-SQLite/blob/85ac7e7850680bd47f3fef5a44ab180d8ee9dd8b/switrs_to_sqlite/make_map.py

Fortunately, looking at mangled text and making sense of it is something Large
language models (LLMs) are pretty good at!

## Automating

What we want is to solve a few-shot, multi-label classification problem. The
classification part _could_ be done without a large language model, but to
make it few-shot almost certainly would require some sort of language model.

The first step is to write a prompt explaining the task, the expected return
value, and a few examples of input and correct outputs. Here is a shortened
version, the full one is [here][prompt]:

[prompt]: /blog/llm-data/prompt/

<div class="chatgpt-edit-block"> 
<div class="chatgpt-prompt-only" markdown="1"> 
> I am working with a dataset of traffic collisions from California. One of
> the fields is the "make" of the vehicle, for example, "Honda", "Ford",
> "Peterbilt", etc.
> 
> But this field a free-text field filled out by the CHP officer on the scene
> of the collision. As such there are misspellings, abbreviations, and other
> mistakes that have to be fixed.
>
> I have created a set of makes as follows (including `NONE` as a placeholder
> for unknown values). Here is the list in a Python `Enum`:
> 
> ```python
> @unique
> class Make(Enum):
>     ACADIAN                 = "acadian"
>     ACURA                   = "acura"
>     ...
>     YAMAHA                  = "yamaha"
> ```
>
> I will provide you with a list of strings. You are to return a Python dictionary mapping the strings to the enum values above. And example set of strings:
> 
> ```
> MINNI
> CHVROLET
> AMERICAN LA FRANCE
> GILG
> WHITEGMC
> FRTH
> HONDA MC
> WINNE
> ```
> 
> And the correct mapping:
> 
> ```python
> MAKE_MAP = {
>   "MINNI": Make.MINI.value,
>   "CHVROLET": Make.CHEVROLET.value,
>   "AMERICAN LA FRANCE": Make.AMERICAN_LAFRANCE.value,
>   "GILG": Make.GILLIG.value,
>   "WHITEGMC": Make.GMC.value,
>   "FRTH": Make.FREIGHTLINER.value,
>   "HONDA MC": Make.HONDA.value,
>   "WINNE": Make.WINNEBAGO.value,
> }
> ```
</div>
</div>

Then gave the model the 900.
