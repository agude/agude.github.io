---
layout: post
title: Using Large Language Models to clean data
description: >
  Manually fixing messy data is tedious and slow. But thankfully, LLMs are
  pretty good are piecing together mangled text. Read on to find out how!
image: /files/llm-data/00045-1994538970-a_simple_color_pencil_drawing_a_robot,_inspecting_a_car,_holding_a_clipboard,_white_background.png
hide_lead_image: False
image_alt: >
  A pencil drawing of a robot inspecting a car. Prompt: A simple color pencil
  drawing a robot, inspecting a car, holding a clipboard, white background.
redirect_from: blog/good-uses-for-large-language-mo-models/
categories: 
  - generative-ai
  - machine-learning
  - california-traffic-data
---

{% capture file_dir %}/files/chatgpt{% endcapture %}

I maintain the [SWITRS-to-sqlite][s2s] Python library that parses and cleans
up California Highway Patrol's traffic collision database. One of the fields
the responding officer has to fill out at the scene of the crash is the
make[^make] of the vehicle. This field is a free text field, but there is a
relatively small number of common brands, so it should be mapped to a
categorical column.

[^make]: 
    The "make" of a vehicle is the brand of the manfacturer, like 'Honda',
    'Ford', 'Tesla', etc.

[s2s]: {% post_url 2016-11-01-switrs_to_sqlite %}

This is straightforward when the officer writes `FORD` or `HONDA`, which they
mostly do. But since the officer can write anything, they occasionally make it
a little harder on us by abbreviating or mistyping, for example `VOLX` and
`DODDGE`. And sometimes they make it impossible by writing `--` or `______`.

The solution is to go through, one by one, and create a [mapping][enum_post]
like:

[enum_post]: {% post_url 2019-01-22-python_patterns_enum %}

```python
# Enumeration of common vehicle makes
@unique
class Make(Enum):
  CHEVROLET  = "chevrolet"
  GMC        = "gmc"
  HINO       = "hino"
  INFINITI   = "infiniti"
  MITSUBISHI = "mitsubishi"
  # Special Token for unknown make
  NONE       = None

# Dictionary mapping raw values to Make enum
make_map = {
  "CHEVRLT":  Make.CHEVROLET,
  "HINO/":    Make.HINO,
  "INFINITY": Make.INFINITI,
  "MITSUB":   Make.MITSUBISHI,
  "TAHOE":    Make.GMC,
  "UKNOWN":   Make.NONE,
}
```

As someone who did this mapping by hand for [over 900 entries][git], it is
quite tedious. Fortunately, making sense of mangled text is something [Large
Language Models (LLMs) are pretty good at][good_llm]!

[git]:  https://github.com/agude/SWITRS-to-SQLite/blob/85ac7e7850680bd47f3fef5a44ab180d8ee9dd8b/switrs_to_sqlite/make_map.py
[good_llm]: {% post_url 2023-04-12-good_uses_for_large_language_models %}


## Automating

The goal is to perform few-shot, multi-label classification of vehicle makes.
Few-shot because we are going to give the model just a handful of examples of
what output we expect, and multi-label because there are many possible vehicle
makes it will have to map to.

### Prompting

The first step is to write a prompt explaining the task to the model, the
expected return value, and a few examples of input and correct outputs. Here
is a shortened version, the full one is [here][prompt], starting with the
instructions:

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

Then the output format, with instructions to include an explanation of its
logic first, which can [help model accuracy][cot]:

[cot]: https://arxiv.org/abs/2201.11903

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

And finally some examples of inputs and correct outputs:

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

Since I was manually copying the prompt into the model's web interface, I used
batches of 100--200 string sorted alphabetically. With API access, I could
have used [retrieval-augmented generation][rag] to create custom examples for
each string while sending them one at a time.

[rag]: https://en.wikipedia.org/w/index.php?title=Prompt_engineering&oldid=1179231833#Retrieval-augmented_generation

Splitting the data into batches helped the model figure out very short
entries. For example, the model failed when given `WNBG` (Winnebago) by
itself, but succeeded when I gave it the list:

```
WINN
WINNE   
WINNEBAG
WINNEBAGO
WINNI
WNBG 
WNBGO
```

I believe seeing multiple short versions next to eachother helped the model
infer the right mapping.

### Performance

I obtained the following performance on my 902 hand-mapped entries:

- The model correctly fixed 2 entries that I had gotten wrong.
- It matched 682 (75.6%) of my hand-labeled mappings. 
- It missed 218 (24.1%) of the mappings, frequently using made-up enum values.

This is reasonably good performance, as finding wrong entries is pretty quick
(and many could be fixed with find and replace).
