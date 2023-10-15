---
layout: page-not-on-sidebar
title: Claude SAT Analogy Results
description: >
  The prompt for my SWITRS Make mapping.
image: /files/llm-data/00045-1994538970-a_simple_color_pencil_drawing_a_robot,_inspecting_a_car,_holding_a_clipboard,_white_background.png
image_alt: >
  A pencil drawing of a robot inspecting a car. Prompt: A simple color pencil
  drawing a robot, inspecting a car, holding a clipboard, white background.
permalink: blog/llm-data/prompt/
date: 2023-10-15
---

<div class="chatgpt-edit-block"> 
<div class="chatgpt-prompt-only" markdown="1"> 
I am working with a dataset of traffic collisions from California. One of the
fields is the "make" of the vehicle, for example, "Honda", "Ford",
"Peterbilt", etc.

But this field a free-text field filled out by the CHP officer on the scene of
the collision. As such there are misspellings, abbreviations, and other
mistakes that have to be fixed. 

I have created a set of makes as follows (including `NONE` as a placeholder
for unknown values). Here is the list in a Python `Enum`:

```python
@unique
class Make(Enum):
    ACADIAN                 = "acadian"
    ACURA                   = "acura"
    ALFA_ROMERO             = "alfa romera"
    AMC                     = "american motors"
    AMERICAN_LAFRANCE       = "american lafrance"
    AUDI                    = "audi"
    AUTOCAR                 = "autocar"
    BENTLEY                 = "bentley"
    BLUEBIRD                = "bluebird"
    BMW                     = "bmw"
    BUICK                   = "buick"
    CADILLAC                = "cadillac"
    CHEVROLET               = "chevrolet"
    CHRYSLER                = "chrysler"
    CROWN                   = "crown"
    DAEWOO                  = "daewoo"
    DATSUN                  = "datsun"
    DELOREAN                = "delorean"
    DODGE                   = "dodge"
    DUCATI                  = "ducati"
    FERRARI                 = "ferrari"
    FIAT                    = "fiat"
    FORD                    = "ford"
    FREIGHTLINER            = "freightliner"
    GEO                     = "geo"
    GILLIG                  = "gillig"
    GMC                     = "gmc"
    GRUMMAN                 = "grumman"
    HARLEY                  = "harley-davidson"
    HINO                    = "hino"
    HONDA                   = "honda"
    HUMMER                  = "hummer"
    HYUNDAI                 = "hyundai"
    INFINITI                = "infiniti"
    INTERNATIONAL_HARVESTER = "international harvester"
    ISUZU                   = "isuzu"
    JAGUAR                  = "jaguar"
    JEEP                    = "jeep"
    JOHN_DEERE              = "john deere"
    KAWASAKI                = "kawasaki"
    KENWORTH                = "kenworth"
    KIA                     = "kia"
    LAND_ROVER              = "land rover"
    LEXUS                   = "lexus"
    LINCOLN                 = "lincoln"
    MACK                    = "mack"
    MASERATI                = "maserati"
    MAZDA                   = "mazda"
    MERCEDES_BENZ           = "mercedes-benz"
    MERCURY                 = "mercury"
    MINI                    = "mini"
    MITSUBISHI              = "mitsubishi"
    NISSAN                  = "nissan"
    NONE                    = None
    OLDSMOBILE              = "oldsmobile"
    PETERBILT               = "peterbilt"
    PLYMOUTH                = "plymouth"
    PONTIAC                 = "pontiac"
    PORSCHE                 = "porsche"
    RADPOWER                = "rad power bikes"
    RAM                     = "ram"
    SAAB                    = "saab"
    SATURN                  = "saturn"
    SCHWINN                 = "schwinn"
    SCION                   = "scion"
    SMART                   = "smart"
    STERLING                = "sterling"
    SUBARU                  = "subaru"
    SUZUKI                  = "suzuki"
    TESLA                   = "tesla"
    THOMAS                  = "thomas"
    TOYOTA                  = "toyota"
    TREK                    = "trek"
    TRIUMPH                 = "triumph"
    VESPA                   = "vespa"
    VOLKSWAGEN              = "volkswagen"
    VOLVO                   = "volvo"
    WHITE                   = "white"
    WINNEBAGO               = "winnebago"
    YAMAHA                  = "yamaha"
```

Take note that anything unknown should be tagged with `Make.None`. And do not
make up new Enum values.

I will provide you with a string. You are to return a Python dictionary with
the following keys, in this same order:

```python
{
  explanation: "An explanation of why you think the enum value is a good match, or why there is no match possible.",
  input_string: "The input string",
  enum: "The correct enum from above",
  no_match: "`True` or `False`. True if there is no matching enum or no way to make a match, otherwise False.", 
}
```

For example, for the input `VOLX`:

```python
{
  explanation: """VOLX is pronouced similarly to 'Volks' and therefore this is
    probably an abbreviation of 'Volkswagen'. There is an enum value for
    Volkswagon, `Make.VOLKSWAGEN`, already so we use that.""",
  input_string: "VOLX",
  enum: make.VOLKSWAGEN,
  no_match: False,
}
```

For example, for the input `COROLLA`:

```python
{
  explanation: """COROLLA is not a make, but is a model of car. The maker of
  the Corolla is Toyota, so the correct mapping is Make.TOYOTA.""",
  input_string: "COROLLA",
  enum: make.TOYOTA,
  no_match: False,
}
```

For example, for the input `(()`:

```python
{
  explanation: "(() is gibberish. We can not determine a correct make, so use Make.NONE.",
  input_string: "(()",
  enum: make.NONE,
  no_match: True,
}
```
