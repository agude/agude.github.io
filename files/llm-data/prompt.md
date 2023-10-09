---
layout: page-not-on-sidebar
title: Claude SAT Analogy Results
description: >
  The prompt for my SWITRS Make mapping.
image: /files/sat2vec/00225-2672697451-impressionistic_painting,_four_men_studying_at_a_desk,_smoking,_looking_over_papers,_window_in_the_background.png
image_alt: >
  An impressionistic painting based on 'Night Before the Exam' by Leonid
  Pasternak, generated with Stable Diffusion using img2img from the original.
  The painting shows four students sitting around a kitchen table studying for
  a exam. Prompt: Impressionistic painting, four men studying at a desk,
  smoking, looking over papers, window in the background.
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

I will provide you with a list of strings. You are to return a Python
dictionary mapping the strings to the enum values above. And example set of
strings:

```
MINNI
CHVROLET
AMERICAN LA FRANCE
GILG
WHITEGMC
FRTH
HONDA MC
WINNE
FREIGH
VOLKWA
HYNUDAI
MAZ
VOLKW
TOT
INFI
LAND RVR
HYNU
VOLOVO
MNI
HYUNDI
```

And the correct mapping:

```python
MAKE_MAP = {
  "MINNI": Make.MINI.value,
  "CHVROLET": Make.CHEVROLET.value,
  "AMERICAN LA FRANCE": Make.AMERICAN_LAFRANCE.value,
  "GILG": Make.GILLIG.value,
  "WHITEGMC": Make.GMC.value,
  "FRTH": Make.FREIGHTLINER.value,
  "HONDA MC": Make.HONDA.value,
  "WINNE": Make.WINNEBAGO.value,
  "FREIGH": Make.FREIGHTLINER.value,
  "VOLKWA": Make.VOLKSWAGEN.value,
  "HYNUDAI": Make.HYUNDAI.value,
  "MAZ": Make.MAZDA.value,
  "VOLKW": Make.VOLKSWAGEN.value,
  "TOT": Make.TOYOTA.value,
  "INFI": Make.INFINITI.value,
  "LAND RVR": Make.LAND_ROVER.value,
  "HYNU": Make.HYUNDAI.value,
  "VOLOVO": Make.VOLVO.value,
  "MNI": Make.MINI.value,
  "HYUNDI": Make.HYUNDAI.value,
}
```
</div>
</div>
