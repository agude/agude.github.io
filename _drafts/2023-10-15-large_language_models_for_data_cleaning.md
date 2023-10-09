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

### Prompting

The first step is to write a prompt explaining the task, the expected return
value, and a few examples of input and correct outputs. Here is a shortened
version, the full one is [here][prompt], starting with the instructions:

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
>     ALFA_ROMERO             = "alfa romera"
>     AMC                     = "american motors"
>     ...
> ```
> 
> Take note that anything unknown should be tagged with `Make.None`. And do
> not make up new Enum values.
</div>
</div>

Then the output format:

<div class="chatgpt-edit-block"> 
<div class="chatgpt-prompt-only" markdown="1"> 
> I will provide you with a string. You are to return a Python dictionary with
> the following keys, in this same order:
> 
> ```python
> {
>   explanation: "An explanation of why you think the enum value is a good match, or why there is no match possible.",
>   input_string: "The input string",
>   enum: "The correct enum from above",
>   no_match: "`True` or `False`. True if there is no matching enum or no way to make a match, otherwise False.", 
> }
> ```
</div>
</div>

And finally some examples of input and output:

<div class="chatgpt-edit-block"> 
<div class="chatgpt-prompt-only" markdown="1"> 
> For example, for the input `VOLX`:
>
> ```python
> {
>   explanation: """VOLX is pronouced similarly to 'Volks' and therefore this is
>     probably an abbreviation of 'Volkswagen'. There is an enum value for
>     Volkswagon, `Make.VOLKSWAGEN`, already so we use that.""",
>   input_string: "VOLX",
>   enum: make.VOLKSWAGEN,
>   no_match: False,
> }
> ```
</div>
</div>

### Answers

For simplicity I sent the model batches of 100-200 strings sorted
alphabetically. If I had API access, I would have sent one string each time
with a set of custom examples pulled from a currated set (a form of
[retrieval-augmented generation][rag]).

[rag]: https://en.wikipedia.org/w/index.php?title=Prompt_engineering&oldid=1179231833#Retrieval-augmented_generation

I think the batches helped the model figure out very short entries since it
would see multiple similar strings next to eachother. For example, it failed
when I gave it `WNBG` (Winnebago) by itself, but succeeded when I gave it the
list:

```
WINN
WINNE   
WINNEBAG
WINNEBAGO
WINNI
WNBG 
WNBGO
```

### Performance
