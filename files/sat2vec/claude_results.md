---
layout: page-not-on-sidebar
title: Claude SAT Analogy Results
description: >
  The results of running Anthropic's large language model Claude on SAT
  analogies.
image: /files/sat2vec/00225-2672697451-impressionistic_painting,_four_men_studying_at_a_desk,_smoking,_looking_over_papers,_window_in_the_background.png
image_alt: >
  An impressionistic painting based on 'Night Before the Exam' by Leonid
  Pasternak, generated with Stable Diffusion using img2img from the original.
  The painting shows four students sitting around a kitchen table studying for
  a exam. Prompt: Impressionistic painting, four men studying at a desk,
  smoking, looking over papers, window in the background.
permalink: blog/sat2vec/claude_results/
date: 2023-05-29
---

Below are the full results of running [Anthropic's][anthropic] biggest
model, [Claude][claude], on SAT Analogies.

[anthropic]: https://www.anthropic.com/
[claude]: https://www.anthropic.com/index/introducing-claude

{% comment %} This allows styling the table text without cutting and pasting a
lot of HTML. {% endcomment %}
{% capture u %}<u style="color:ForestGreen">{% endcapture %}
{% capture endu %}</u>{% endcapture %}

{% capture model %}
<div class="chatgpt-edit-block">
<div class="chatgpt-output-only" markdown="1">
{% endcapture model %}

{% capture endmodel %}
</div>
</div>
{% endcapture endmodel %}

{% capture table %}
<div class="low-width-table" markdown="1" style="max-width: 40%">
{% endcapture table %}

{% capture endtable %}
</div>
{% endcapture endtable %}

For each analogy, the first word pair is the correct answer (in **bold**)
while the answer the model choose is {{u}}green underlined{{endu}}.

[post]: {% post_url 2023-05-29-claude_sat_analogies %}


{{model}}
> Okay, I understand. Let's do this SAT analogy exercise.
>
> For the pair:
>
> authenticity : counterfeit
>
> The relationship is:
>
> authenticity is the opposite of counterfeit. So I need to find another pair of words with an oppositional or antonymous relationship.
>
> Based on this, from the choices provided, I would pick:
>
> reliability : erratic
>
> Because reliability implies consistency and dependability, while erratic implies inconsistency and unpredictability.  So these words are also opposites or antonyms, just like authenticity and counterfeit.
>
> The other choices do not have an directly opposite relationship:
>
> - Mobility and energetic are related but not strictly antonymous
> - Argument and contradictory are related but argument does not directly imply the opposite of contradictory
> - Reserve and reticent are related but do not directly imply opposites
> - Anticipation and solemn do not directly imply opposites
>
> So by process of elimination, reliability : erratic is the only choice that matches the authenticity : counterfeit relationship. Does this make sense? Let me know if you have another analogy question you'd like me to work through!
{{endmodel}}

## Analogies

### Correct Answers

<details markdown="1">
<summary markdown="1">

{{table}}

| agenda : conference         |
|:----------------------------|
| **{{u}}map : trip{{endu}}** |
| teacher : class             |
| executive : employee        |
| man : woman                 |
| agency : assignment         |

{{endtable}}

</summary>

{{model}}
> Okay, for this analogy:
> 
> agenda : conference
> 
> The relationship here is:
> 
> An agenda is a list that provides the plan or schedule for a conference. So
> a conference relies on and uses an agenda.
> 
> Based on this, the choice that shows a similar relationship is:
> 
> map : trip
> 
> Because a trip relies on and uses a map. A map provides the plan and
> guidance for a trip, just as an agenda does for a conference.
> 
> The other choices do not show this same kind of relationship:
> 
> -  Teacher : class - A teacher facilitates a class but a class does not rely
>    on or use a teacher in the same direct way that a conference uses an
>    agenda or a trip uses a map.
> -  Executive : employee - An executive oversees employees but employees do
>    not directly rely on or make use of an executive the same way a
>    conference uses an agenda or a trip uses a map.
> -  Man : woman - These do not have a direct facilitator/user relationship.
>    They do not rely on each other in the same way.
> -  Agency : assignment - While an agency may give out assignments, an
>    assignment does not directly rely on or use an agency in the way a
>    conference uses an agenda or a trip uses a map.
> 
> So by analyzing each choice, map : trip is the one option that shows the
> closest relationship to the original pair's dynamic of agenda : conference.
> Please let me know if this makes sense or if you have another analogy
> challenge for me!
{{endmodel}}

</details>

<details markdown="1">
<summary markdown="1">

{{table}}

| fix : stable           |
|:-----------------------|
| **{{u}}fortify : strong{{endu}}**   |
| captivate : attractive |
| deter : active         |
| furrow : productive    |
| mend : torn            |

{{endtable}}

</summary>

{{model}}
> fix : stable
> 
> The relationship here is that to fix something means to make it stable or
> securely established. So I'm looking for a pair where the first word means
> to make the second word.
> 
> Based on this, the best choice is:
> 
> fortify : strong
> 
> To fortify means to make strong or more robust. The other options do not
> have this relationship:
> 
> - captivate : attractive - To captivate means to attract or allure, not
>   specifically to make attractive. 
> - deter : active - To deter means to discourage or prevent, not to make
>   active.  
> - furrow : productive - To furrow means to make grooves or trenches, not
>   specifically to make productive. 
> - mend : torn - To mend means to repair or heal, not specifically to make
>   torn. Torn is the state before mending.
> 
> So by process of elimination, "fortify : strong" is the only choice where
> the first word (fortify) means to make the second word (strong). Like "fix :
> stable", it indicates a relationship of making or causing something.
> 
> Please let me know if I should explain or expand on my analysis further! I'm
> happy to clarify my reasoning for why the other options do not fit the
> relationship in the original word pair.
{{endmodel}}

</details>

<details markdown="1">
<summary markdown="1">

{{table}}

| fugitive : flee      |
|:---------------------|
| **{{u}}braggart : boast{{endu}}** |
| sage : stifle        |
| firebrand : quibble  |
| bystander : procure  |
| parasite : foster    |

{{endtable}}

</summary>

{{model}}
> Okay, for this pair:
> 
> fugitive : flee
> 
> The relationship is:
> 
> A fugitive is someone who flees or runs away. So the noun fugitive is
> closely tied to the verb flee.
> 
> Based on this, the choice that shows a similar relationship, where a noun is
> closely tied to a related verb, is:
> 
> braggart : boast
> 
> Because a braggart is someone who boasts or brags. The noun braggart is
> closely tied to the verb boast.
> 
> The other choices do not have this direct noun-verb relationship:
> 
> - Sage : stifle - While a sage is wise or judicious, the verb stifle means
>   to suppress or suffocate. These words are unrelated.
> - Firebrand : quibble - The noun firebrand means a troublemaker, while the
>   verb quibble means to argue trivial details. These words are not closely
>   tied or related.
> - Bystander : procure - A bystander is someone who stands by, while procure
>   means to obtain or acquire. These words are unrelated.
> - Parasite : foster - While a parasite exploits its host, the verb foster
>   means to promote the growth or development of something. These words are
>   not closely tied or related.
> 
> So in summary, only braggart : boast shows the direct noun-verb relationship
> where the noun specifically describes someone who does the action depicted
> by the verb. The other choices show indirect or unrelated relationships
> between the noun and verb.
> 
> Let me know if this helps clarify my thinking on this type of analogy
> problem. I'm happy to work through any other examples!
{{endmodel}}

</details>

<details markdown="1">
<summary markdown="1">

{{table}}

| chronological : time   |
|:-----------------------|
| **{{u}}ordinal : place{{endu}}**    |
| abnormal : value       |
| coincidental : health  |
| marginal : knowledge   |
| virtual : truth        |

{{endtable}}

</summary>

{{model}}
> Okay, for the pair:
> 
> chronological : time
> 
> The relationship is:
> 
> Chronological means arranged by or according to time. So time is the
> organizing principle or basis for chronology.
> 
> Based on this, the choice that shows a similar relationship, where the first
> word relies on the second word as its organizing principle, is:
> 
> ordinal : place
> 
> Because ordinal means arranged by or according to place or position. So
> place is the organizing principle for ordinal numbers or sequences.
> 
> The other choices do not have this relationship:
> 
> - Abnormal : value - While "abnormal" means deviating from a norm or
>   standard, "value" does not provide the basis for organizing or determining
>   what is abnormal. Value is unrelated.
> - coincidental : health - The word "coincidental" means by chance or
>   accident, while "health" does not provide the basis for determining
>   coincidence. Health is unrelated.
> - marginal : knowledge - While "marginal" means minimal or peripheral,
>   "knowledge" does not provide the basis for determining what is marginal.
>   Knowledge is unrelated.
> - virtual : truth  - While "virtual" means simulated or artificial, "truth"
>   does not provide the basis for organizing or distinguishing the virtual.
>   Truth is unrelated.
> 
> So in summary, only ordinal : place shows a relationship where the first
> word (ordinal) relies on the second (place) as the underlying principle of
> organization, just as chronological relies on time. The other choices do not
> have this direct relational basis.
> 
> Let me know if this helps explain my thinking on this analogy problem! I'm
> happy to work through any other examples you may have.
{{endmodel}}

</details>

<details markdown="1">
<summary markdown="1">

{{table}}

| soot : grimy         |
|:---------------------|
| **{{u}}rain : sodden{{endu}}**    |
| dust : radiant       |
| frost : transparent  |
| pall : gaudy         |
| sunshine : fruitless |

{{endtable}}

</summary>

{{model}}
> Okay, for the pair:
> 
> soot : grimy
> 
> The relationship is:
> 
> Soot causes or results in something being grimy or filthy.  So there is a
> causal relationship between soot and grimy.
> 
> Based on this, the choice that shows a similar causal relationship is:
> 
> rain : sodden
> 
> Because rain causes or results in something becoming sodden or soaked. Rain
> leads to sodden, just as soot leads to grimy.
> 
> The other choices do not show this kind of direct causal relationship:
> 
> - dust : radiant - While dust could obscure radiance or shine, dust itself
>   does not cause or directly result in radiance. Radiance can exist without
>   dust.
> - frost : transparent - Although frost may lead to ice which is transparent,
>   frost itself does not cause or directly result in transparency.
>   Transparency can exist without frost.
> - pall : gaudy - Although a pall or dark cloud may obscure bright colors, a
>   pall itself does not cause or directly result in gaudiness. Gaudiness can
>   exist without a pall.
> - sunshine : fruitless - Although lack of sunshine could hinder fruit
>   growth, sunshine itself does not cause or directly result in
>   fruitlessness. Fruitlessness can exist even with sunshine.
> 
> So in summary, only rain : sodden demonstrates a direct causal relationship
> where one word leads to or results in the state described by the other word.
> The other choices show indirect or inconsistent relationships between the
> words.
> 
> Let me know if this helps explain my approach to solving analogies based on
> causal relationships. I'm happy to work through any other examples you may
> have!
{{endmodel}}

</details>

<details markdown="1">
<summary markdown="1">

{{table}}

| massive : bulk        |
|:----------------------|
| **{{u}}gigantic : size{{endu}}**   |
| trivial : importance  |
| interminable : legacy |
| anonymous : luster    |
| ultimate : magnitude  |

{{endtable}}

</summary>

{{model}}
> Okay, for the pair:
> 
> massive : bulk
> 
> The relationship is:
> 
> Massive means extremely large in quantity, amount or degree. Bulk means
> large in size, mass or volume. So these words are synonyms that describe the
> same quality (largeness) in similar terms.
> 
> Based on this, the choice that shows a synonymous relationship is:
> 
> gigantic : size
> 
> Because gigantic also means extremely large, and size refers to dimensions,
> measurements or proportions. Like massive and bulk, gigantic and size are
> synonymous words that describe largeness.
> 
> The other choices do not show this direct synonymous relationship:
> 
> - trivial : importance - While trivial means insignificant or unimportant,
>   importance does not refer to the same concept or share a synonymous
>   meaning. The words are antonymous, not synonymous.
> - interminable : legacy - Interminable means endless or ceaseless, while
>   legacy refers to something handed down from the past. The words do not
>   share a synonymous meaning.
> - anonymous : luster - Anonymous means without a name or identity, while
>   luster refers to radiance or shine. The words do not share a synonymous
>   meaning.
> - ultimate : magnitude - While ultimate can mean final or maximal, magnitude
>   refers to greatness of size or importance. The words do not share a
>   synonymous meaning or express the same concept.
> 
> So in summary, only gigantic : size shows a direct synonymous relationship
> where both words share an essentially equivalent meaning (extreme
> largeness). The other choices show indirect, inconsistent or antonymous
> relationships between the words.
> 
> Let me know if this helps explain my approach to solving analogies based on
> synonymy. I'm happy to work through any other examples!
{{endmodel}}

</details>

<details markdown="1">
<summary markdown="1">

{{table}}

| reinforce : stronger   |
|:-----------------------|
| **{{u}}erode : weaker{{endu}}**         |
| shirk : greater        |
| abound : lesser        |
| dismantle : longer     |
| wilt : higher          |

{{endtable}}

</summary>

{{model}}
> reinforce : stronger  
> 
> The relationship here is that reinforce means to make stronger or more
> solid. So I'm looking for a pair where the first word means to make more of
> the quality described by the second word.
> 
> Based on this, the best choice is:
> 
> erode : weaker
> 
> Erode means to make weaker or less strong over time through a gradual
> process of deterioration or consumption. The other options do not have this
> relationship:
> 
> - shirk : greater - To shirk means to avoid or neglect, it does not mean to
>   make greater. 
> - abound : lesser - To abound means to exist in large numbers or amounts. It
>   does not mean to make lesser.
> - dismantle : longer - To dismantle means to take apart, not to make longer.
> - wilt : higher - To wilt means to become limp or droop, not to make higher.
> 
> So by process of elimination, "erode : weaker" is the only choice where the
> first word (erode) means to make more of what the second word (weaker) is
> describing. Like "reinforce : stronger", it indicates a relationship of
> making more or intensifying.
> 
> Please let me know if I should explain or expand on my analysis further! I'm
> happy to clarify my reasoning for why the other options do not fit the
> relationship in the original word pair.
{{endmodel}}

</details>

<details markdown="1">
<summary markdown="1">

{{table}}

| embarrass : humiliate   |
|:------------------------|
| **{{u}}pilfer : steal{{endu}}**      |
| reduce : enlarge        |
| labor : succeed         |
| bicker : fight          |
| spank : whip            |

{{endtable}}

</summary>

{{model}}
> embarrass : humiliate
> 
> The relationship here is that embarrass and humiliate are synonyms, meaning
> essentially the same thing. They both refer to causing someone to feel
> ashamed or foolish.
> 
> Based on this, the pair with the same synonymous relationship is:
> 
> pilfer : steal
> 
> These words are synonyms, both meaning to take something in a wrongful or
> unlawful way. The other options do not have this synonymous relationship:
> 
> - reduce : enlarge - These are antonyms, opposites. 
> - labor : succeed - These words are related but not synonyms. One can labor
>   to succeed but they have different core meanings.
> - bicker : fight - Again these words are related but bicker implies a petty
>   or minor fight, while fight is more general. So not strictly synonyms.
> - spank : whip - These are related forms of corporal punishment but have
>   different meanings and severities, so not synonymous.
> 
> Therefore, by process of elimination, the choice that is most synonymous is
> "pilfer : steal" since those two words have essentially the same meaning,
> just like "embarrass : humiliate". Please let me know if I should clarify or
> expand on my analysis further!
{{endmodel}}

</details>

<details markdown="1">
<summary markdown="1">

{{table}}

| equanimity : harried       |
|:---------------------------|
| **{{u}}moderation : dissolute{{endu}}** |
| erudition : urbane         |
| intuition : logical        |
| distinction : singular     |
| celebrity : infamous       |

{{endtable}}

</summary>

{{model}}
> Okay, for the pair:
> 
> equanimity : harried
> 
> The relationship is:
> 
> These words are antonyms. Equanimity means calmness or composure, while
> harried means worried, stressed or agitated. The meanings are opposite.
> 
> Based on this, the choice that shows an antonymous relationship is:
> 
> moderation : dissolute
> 
> Because moderation and dissolute are also antonyms. Moderation means
> restraint or temperance, while dissolute means lacking restraint or
> excessive. The meanings are opposite.
> 
> The other choices do not show a direct antonymous relationship:
> 
> - erudition : urbane - While an erudite person may also be urbane or
>   refined, the words themselves are not antonyms. Erudition means great
>   knowledge or learning, while urbane means courteous or polished. The
>   meanings are unrelated, not opposite.
> - intuition : logical - While intuition suggests spontaneity and logic
>   suggests reasoning, the words themselves are not direct antonyms.
>   Intuition means insight or perception, while logical means rational or
>   reasonable. The meanings differ but are not strictly opposite.
> - distinction : singular - Although being singular or unique could result in
>   distinction, the words themselves are not antonyms. Distinction refers to
>   excellence or eminence, while singular means alone or unique. The meanings
>   are unrelated, not opposite.
> - celebrity : infamous - Although some celebrities become infamous, the
>   words themselves are not antonyms. Celebrity means fame or renown, while
>   infamous means notoriously bad or unlawful. The meanings differ in
>   connotation but are not strictly opposite.
> 
> So in summary, only moderation : dissolute shows a direct antonymous
> relationship where the meanings of the words are opposite or contrary. The
> other choices demonstrate more indirect or inconsistent relationships
> between the meanings.
> 
> Let me know if this helps explain my approach to solving analogies based on
> antonymy. I'm happy to work through any other examples you may have!
{{endmodel}}

</details>

<details markdown="1">
<summary markdown="1">

{{table}}

| runner : marathon     |
|:----------------------|
| **{{u}}oarsman : regatta{{endu}}** |
| referee : tournament  |
| martyr : massacre     |
| envoy : embassy       |
| horse : stable        |

{{endtable}}

</summary>

{{model}}
> Okay, for the pair:
> 
> runner : marathon
> 
> The relationship is:
> 
> A runner participates in and competes in a marathon. So there is a direct
> participatory relationship between the words.
> 
> Based on this, the choice that shows a similar participatory relationship
> is:
> 
> oarsman : regatta
> 
> Because an oarsman participates in and competes in a regatta. Like a runner
> in a marathon, an oarsman takes part in a regatta.
> 
> The other choices do not show this direct participatory relationship:
> 
> - referee : tournament - While a referee officiates or supervises a
>   tournament, a referee does not participate or compete in the same way that
>   a runner does in a marathon or an oarsman does in a regatta. The
>   relationship is indirect.
> - martyr : massacre - Although a martyr may die in a massacre, a martyr does
>   not choose to participate or directly compete in a massacre in the same
>   willing manner as a runner in a marathon or oarsman in a regatta. The
>   relationship is coincidental, not directly participatory.
> - envoy : embassy - An envoy may work at an embassy but does not participate
>   or compete in an embassy in the same manner as a runner in a marathon or
>   oarsman in a regatta. The relationship is occupational, not directly
>   participatory.
> - horse : stable - While a horse is housed in a stable, a horse does not
>   willingly participate or compete in a stable in the same manner as a
>   runner in a marathon or oarsman in a regatta. The horse does not choose to
>   take part but is rather just kept in the stable. The relationship is
>   incidental, not directly participatory.
> 
> So in summary, only oarsman : regatta shows a direct participatory
> relationship equivalent to that of runner : marathon. The other choices show
> more indirect, coincidental or incidental relationships between the words.
> 
> Let me know if this helps explain my approach to solving analogies based on
> participation or competition. I'm happy to work through any other examples
> you may have!
{{endmodel}}

</details>

<details markdown="1">
<summary markdown="1">

{{table}}

| medicine : illness      |
|:------------------------|
| **{{u}}law : anarchy{{endu}}**       |
| stimulant : sensitivity |
| etiquette : discipline  |
| love : treason          |
| hunger : thirst         |

{{endtable}}

</summary>

{{model}}
> Okay, for the pair:
> 
> medicine : illness
> 
> The relationship is:
> 
> Medicine is used to treat or remedy an illness. So there is a relationship
> of remedy or solution to a problem.
> 
> Based on this, the choice that shows a similar relationship is:
> 
> law : anarchy
> 
> Because laws are used to remedy or solve the problem of anarchy or disorder.
> Like medicine treats illness, laws address anarchy.
> 
> The other choices do not show this remedial or solution-based relationship:
> 
> - stimulant : sensitivity - While a stimulant could increase sensitivity, a
>   stimulant is not used to directly remedy or solve sensitivity. Sensitivity
>   can exist without the use of a stimulant. The relationship is
>   coincidental, not directly remedial.
> - etiquette : discipline - Etiquette and discipline are unrelated concepts.
>   Etiquette refers to politeness or courtesy while discipline refers to
>   training or control. Etiquette does not remedy discipline or address it as
>   a problem to be solved. The relationship is indirect at best.
> - love : treason - While treason could be seen as a betrayal of love or
>   trust, love itself does not remedy or solve the problem of treason.
>   Treason can occur irrespective of the presence of love. The relationship
>   is coincidental, not directly remedial.
> - hunger : thirst - Hunger and thirst are unrelated bodily needs or drives.
>   Hunger does not remedy or solve the problem of thirst. The relationship is
>   indirect. They are two separate issues or experiences.
> 
> So in summary, only law : anarchy shows a remedial relationship directly
> equivalent to that of medicine : illness. The other choices demonstrate
> indirect, coincidental or inconsistent relationships between the concepts.
> 
> Let me know if this helps explain my approach to solving analogies based on
> remedy or solution. I'm happy to work through any other examples you may
> have!
{{endmodel}}

</details>

<details markdown="1">
<summary markdown="1">

{{table}}

| extort : obtain         |
|:------------------------|
| **{{u}}plagiarize : borrow{{endu}}** |
| explode : ignite        |
| purify : strain         |
| pilfer : steal          |
| consider : appeal       |

{{endtable}}

</summary>

{{model}}
> Okay, for the pair:
> 
> extort : obtain
> 
> The relationship is:
> 
> While extort means to obtain something through force, threat or coercion,
> obtain simply means to get or acquire something. So extort implies a more
> forceful or unjustified means of obtaining something compared to a simpler
> obtain. The relationship is one of more extreme means to the same ends.
> 
> Based on this, the choice that shows a similar relationship is:
> 
> plagiarize : borrow
> 
> Because plagiarize means to get or acquire (ideas, words, etc.) from another
> source through unjustified or uncredited means, compared to the simpler
> borrow which just means to acquire temporarily with the intent to return.
> Like extort, plagiarize implies a more unjustified or forceful means to the
> same goal of obtaining something.
> 
> The other choices do not show this relationship of more extreme means to the
> same end:
> 
> - explode : ignite - While igniting something could lead to an explosion,
>   ignite itself does not imply a more extreme version of exploding. The
>   relationship is indirect or coincidental, not directly comparable.
> - purify : strain - While straining something could be a step in purifying
>   it, strain itself does not imply an more extreme version of purifying.
>   Purifying can be achieved through gentle and non-forceful means as well.
>   The relationship is indirect.
> - pilfer : steal - Although related, neither word implies an unambiguously
>   more extreme version of acquiring something. Steal and pilfer can both
>   span a range from petty theft to more serious larceny. The relationship is
>   inconsistent.
> - consider : appeal - These words are largely unrelated. To consider
>   something does not imply a more extreme version of appealing to something.
>   The relationship is indirect at best.
> 
> So in summary, only plagiarize : borrow shows a directly comparable
> relationship where one word (plagiarize) implies a more unjustified or
> forceful means to the same end described by the other word (borrow). The
> other choices show indirect, inconsistent or coincidental relationships
> between the meanings.
> 
> Let me know if this helps explain my approach to solving analogies based on
> extreme or unjustified means versus more neutral means to the same outcome
> or end. I'm happy to work through any other examples you may have!
{{endmodel}}

</details>

<details markdown="1">
<summary markdown="1">

{{table}}

| disorganized : system    |
|:-------------------------|
| **{{u}}traitorous : loyalty{{endu}}** |
| greedy : money           |
| athletic : intelligence  |
| retired : hope           |
| conserve : party         |

{{endtable}}

</summary>

{{model}}
> Okay, for the pair:
> 
> disorganized : system
> 
> The relationship is:
> 
> Disorganized implies a lack or absence of organization or system. So there
> is an oppositional relationship between the terms, with one (disorganized)
> implying the lack of what the other (system) represents.
> 
> Based on this, the choice that shows a similar oppositional relationship is:
> 
> traitorous : loyalty
> 
> Because traitorous implies a lack or absence of loyalty. Like disorganized
> opposes system, traitorous opposes loyalty.
> 
> The other choices do not show this kind of direct oppositional relationship:
> 
> - greedy : money - While greed may motivate the pursuit or hoarding of
>   money, greed itself does not imply a lack of money. Money can exist
>   without greed. The relationship is coincidental or indirect, not directly
>   oppositional.
> - athletic : intelligence - Athletic ability does not imply a lack of
>   intelligence. Intelligence is unrelated to athletics. The relationship is
>   coincidental or indirect.
> - retired : hope - Retirement does not imply a lack of hope. Hope can
>   continue even after retirement. The relationship is coincidental or
>   indirect.
> - conserve : party - To conserve does not directly imply opposition to
>   partying. Partying and conservation are largely unrelated concepts. The
>   relationship is coincidental or indirect.
> 
> So in summary, only traitorous : loyalty demonstrates a relationship
> directly comparable to disorganized : system, where one term (traitorous)
> implies a lack or absence of what the other (loyalty) represents. The other
> choices show indirect, inconsistent or coincidental relationships between
> the concepts.
> 
> Let me know if this helps explain my approach to solving analogies based on
> opposition or contradiction. I'm happy to work through any other examples
> you may have!
{{endmodel}}

</details>

<details markdown="1">
<summary markdown="1">

{{table}}

| topaz : yellow        |
|:----------------------|
| **{{u}}amethyst : purple{{endu}}** |
| sapphire : red        |
| amber : blue          |
| jeweler : clarity     |
| diamond : carat       |

{{endtable}}

</summary>

{{model}}
> Okay, for the pair:
> 
> topaz : yellow
> 
> The relationship is:
> 
> Topaz is characteristically yellow in color. So there is a relationship of
> characteristic property or feature.
> 
> Based on this, the choice that shows a similar relationship is:
> 
> amethyst : purple
> 
> Because amethyst is characteristically purple in color. Like topaz is
> characteristically yellow, amethyst is characteristically purple.
> 
> The other choices do not show this kind of characteristic property
> relationship:
> 
> - sapphire : red - Sapphires are not characteristically red in color. While
>   some rare varieties may be reddish, sapphires more typically come in
>   blues. So red is not a characteristic property of sapphires.
> - amber : blue  - Amber is not characteristically blue in color. Amber is
>   typically yellowish orange. So blue is not a characteristic property of
>   amber.
> - jeweler : clarity - A jeweler does not have clarity as a characteristic
>   property. Jewelers are people, not gemstones. The relationship is indirect
>   or coincidental.
> - diamond : carat - While a diamond's size may be measured in carats, carat
>   itself is not a characteristic property of diamonds like color is for
>   topaz or amethyst. The relationship is indirect.
> 
> So in summary, only amethyst : purple shows a relationship directly
> comparable to topaz : yellow, where one term (amethyst) has as a
> characteristic property the feature described by the other term (purple).
> The other choices show indirect, inconsistent or coincidental relationships
> between the concepts.
> 
> Let me know if this helps explain my approach to solving analogies based on
> characteristic properties or features. I'm happy to work through any other
> examples you may have!
{{endmodel}}

</details>

<details markdown="1">
<summary markdown="1">

{{table}}

| clumsy : botch     |
|:-------------------|
| **{{u}}lazy : shirk{{endu}}**   |
| clever : eradicate |
| willful : heed     |
| wicked : insinuate |
| strict : pamper    |

{{endtable}}

</summary>

{{model}}
> Okay, for the pair:
> 
> clumsy : botch
> 
> The relationship is:
> 
> Someone who is clumsy is prone or likely to botch or bungle things. So there
> is a relationship of tendency or propensity. Clumsiness leads to or results
> in botching.
> 
> Based on this, the choice that shows a similar relationship of tendency or
> propensity is:
> 
> lazy : shirk
> 
> Because someone who is lazy is prone or likely to shirk responsibility. Like
> clumsiness leads to botching, laziness leads to shirking.
> 
> The other choices do not show this kind of relationship of tendency or
> propensity:
> 
> - clever : eradicate - Being clever does not directly imply a tendency to
>   eradicate or destroy things. The relationship is coincidental or indirect.
> - willful : heed - Being willful does not necessarily imply a propensity to
>   heed warnings. The relationship is inconsistent. Willful people may ignore
>   as well as heed.
> - wicked : insinuate  - Being wicked does not directly imply a tendency to
>   insinuate or hint in an unpleasant way. The relationship is coincidental
>   or indirect.
> - strict : pamper - Being strict contradicts a propensity to pamper or
>   indulge. The relationship is oppositional, not one of tendency. Strictness
>   does not lead to pampering.
> 
> So in summary, only lazy : shirk demonstrates a relationship directly
> comparable to clumsy : botch, where one term (lazy) implies a propensity or
> tendency described by the other term (shirk). The other choices show
> indirect, inconsistent or contradictory relationships between the concepts.
> 
> Let me know if this helps explain my approach to solving analogies based on
> tendency, propensity or likelihood. I'm happy to work through any other
> examples you may have!
{{endmodel}}

</details>

<details markdown="1">
<summary markdown="1">

{{table}}

| lumen : brightness   |
|:---------------------|
| **{{u}}inches : length{{endu}}**  |
| candle : light       |
| density : darkness   |
| nickel : metal       |
| color : hue          |

{{endtable}}

</summary>

{{model}}
> Okay, for the pair:
> 
> lumen : brightness
> 
> The relationship is:
> 
> Lumen is a measure or quantitative expression of brightness. So there is a
> relationship of measure to the thing being measured.
> 
> Based on this, the choice that shows a similar measure-measurement
> relationship is:
> 
> inches : length
> 
> Because inches represent a measure or quantitive expression of length. Like
> lumens measure brightness, inches measure length.
> 
> The other choices do not show this kind of direct measure-measurement
> relationship:
> 
> - candle : light - While a candle produces light, candle itself is not a
>   measure of light. The relationship is means-ends, not measure-measurement.
> - density : darkness - Density does not measure darkness. Density refers to
>   how closely packed or crowded something is. The relationship is
>   coincidental or indirect.
> - nickel : metal - While a nickel is a metal, nickel itself is not a measure
>   of metal. Nickel simply refers to the metal itself, not a measure of it.
>   The relationship is coincidental or indirect.
> - color : hue - While color and hue are related concepts, neither one
>   strictly measures or quantifies the other. The relationship is
>   coincidental. They refer to the same basic idea at different levels of
>   specificity.
> 
> So in summary, only inches : length demonstrates a relationship directly
> comparable to lumen : brightness, where one term (inches) represents a
> measure or quantitive expression of the quality described by the other term
> (length). The other choices show indirect, inconsistent or simply
> coincidental relationships between the concepts.
> 
> Let me know if this helps explain my approach to solving analogies based on
> measure-measurement relationships. I'm happy to work through any other
> examples you may have!
{{endmodel}}

</details>

<details markdown="1">
<summary markdown="1">

{{table}}

| enfranchise : slavery      |
|:---------------------------|
| **{{u}}liberate : confine{{endu}}**     |
| anatomy : physiology       |
| equation : mathematics     |
| bondage : subjugation      |
| appeasement : unreasonable |

{{endtable}}

</summary>

{{model}}
> Okay, for the pair:
> 
> enfranchise : slavery
> 
> The relationship is:
> 
> To enfranchise is to free from slavery or oppression. So there is a
> relationship of freeing or release from something undesirable.
> 
> Based on this, the choice that shows a similar relationship of freeing from
> something undesirable is:
> 
> liberate : confine
> 
> Because to liberate is to free from confinement. Like enfranchising frees
> from slavery, liberating frees from confinement.
> 
> The other choices do not show this kind of freeing relationship:
> 
> - anatomy : physiology - Anatomy does not free from physiology. These
>   concepts are related but not in a freeing or liberating manner. The
>   relationship is coincidental or indirect.
> - equation : mathematics - An equation does not free from mathematics.
>   Equation is an expression of mathematics, not a release from it.  The
>   relationship is coincidental or constitutive.
> - bondage : subjugation - These words describe undesirable states but do not
>   represent freeing from one another. Bondage and subjugation are related
>   but mutually reinforcing concepts, not means of release from one another.
>   The relationship is coincidental or indirect.
> - appeasement : unreasonable - Appeasement does not represent a freeing from
>   the unreasonable. In fact, the opposite may be argued. The relationship is
>   inconsistent or contradictory.
> 
> So in summary, only liberate : confine demonstrates a relationship directly
> comparable to enfranchise : slavery, representing a freeing or release from
> something undesirable. The other choices show indirect, inconsistent or
> contradictory relationships between the concepts.
> 
> Let me know if this helps explain my approach to solving analogies based on
> relationships of liberating or freeing from something else. I'm happy to
> work through any other examples you may have!
{{endmodel}}

</details>

<details markdown="1">
<summary markdown="1">

{{table}}

| walk : legs      |
|:-----------------|
| **{{u}}chew : mouth{{endu}}** |
| grind : nose     |
| gleam : eyes     |
| dress : hem      |
| cover : book     |

{{endtable}}

</summary>

{{model}}
> Okay, for the pair:
> 
> walk : legs
> 
> The relationship is:
> 
> Walking requires the use of legs. So there is a relationship of necessity or
> requirement. Legs are necessary or required for walking.
> 
> Based on this, the choice that shows a similar relationship of necessity or
> requirement is:
> 
> chew : mouth
> 
> Because chewing requires the use of the mouth. Like legs are necessary for
> walking, the mouth is necessary for chewing.
> 
> The other choices do not show this kind of necessity relationship:
> 
> - grind : nose - While the nose can detect grinding, the nose is not
>   necessary or required for grinding. Grinding can occur without using the
>   nose. The relationship is coincidental or indirect.
> - gleam : eyes - Although the eyes can perceive a gleam, eyes are not
>   necessary or required to produce a gleam. A gleam can exist without eyes.
>   The relationship is coincidental or indirect.
> - dress : hem - While a hem is part of a dress, a hem itself is not
>   necessary or required to have or wear a dress. A dress can exist without a
>   hem. The relationship is coincidental or constitutive, not
>   necessity-based.
> - cover : book - Although a cover protects or encloses a book, a cover is
>   not necessary or required for a book to exist or function as a book. A
>   book can exist without a cover. The relationship is indirect.
> 
> So in summary, only chew : mouth demonstrates a relationship of necessity
> directly comparable to walk : legs, where one concept (mouth) is necessary
> or required for the other concept (chewing) to function or exist.  The other
> choices show indirect, inconsistent or coincidental relationships between
> the concepts.
> 
> Let me know if this helps explain my approach to solving analogies based on
> necessity or requirement relationships. I'm happy to work through any other
> examples you may have!
{{endmodel}}

</details>

<details markdown="1">
<summary markdown="1">

{{table}}

| cot : bed                 |
|:--------------------------|
| **{{u}}tissue : handkerchief{{endu}}** |
| tea : lemon               |
| hotel : motel             |
| hand : finger             |
| lesson : composition      |

{{endtable}}

</summary>

{{model}}
> Okay, for the pair:
> 
> cot : bed
> 
> The relationship is:
> 
> A cot is a simpler or smaller version of a bed. So there is a relationship
> of more basic or fundamental to more complex. Cot represents a more basic
> concept than bed.
> 
> Based on this, the choice that shows a similar relationship is:
> 
> tissue : handkerchief
> 
> Because a tissue is a simpler or more basic version of a handkerchief. Like
> cot is more basic than bed, tissue is more basic than handkerchief.
> 
> The other choices do not show this relationship of more basic to more
> complex:
> 
> - tea : lemon - Although lemon is sometimes added to tea, lemon itself is
>   not a more basic or fundamental form of tea. The relationship is
>   coincidental or indirect.
> - hotel : motel - While a motel may be more basic than a hotel, motel does
>   not represent a simpler version of the same essential concept as hotel.
>   They refer to different types of lodging. The relationship is indirect.
> - hand : finger - Although fingers are parts of a hand, neither concept is
>   more basic or simpler than the other. They exist at the same level, in
>   mutual dependence. The relationship is constitutive, not degree-based.
> - lesson : composition - Although lessons may be involved in composing a
>   composition, lesson itself does not represent a more basic or simpler
>   version of composition. The relationship is indirect or coincidental.
> 
> So in summary, only tissue : handkerchief demonstrates a relationship
> directly comparable to cot : bed, where one concept (tissue) represents a
> more basic, simple or fundamental version of the other, more complex concept
> (handkerchief). The other choices show indirect, coincidental or
> inconsistent relationships between the concepts.
> 
> Let me know if this helps explain my approach to solving analogies based on
> differences in complexity, simplicity or degree of refinement. I'm happy to
> work through any other examples you may have!
{{endmodel}}

</details>

<details markdown="1">
<summary markdown="1">

{{table}}

| sodden : moist            |
|:--------------------------|
| **{{u}}maudlin : sentimental{{endu}}** |
| wet : liquid              |
| nostalgic : emotional     |
| assertive : bold          |
| arid : harsh              |

{{endtable}}

</summary>

{{model}}
> Okay, for the pair:
> 
> sodden : moist
> 
> The relationship is:
> 
> Sodden implies a greater or more extreme degree of wetness than moist. So
> there is a relationship of greater or lesser intensity or extent. Sodden
> represents a more intense concept than moist.
> 
> Based on this, the choice that shows a similar relationship of degree or
> intensity is:
> 
> maudlin : sentimental
> 
> Because maudlin implies a greater or more extreme degree of sentimentality
> than sentimental. Like sodden is more extreme than moist, maudlin is more
> extreme than sentimental.
> 
> The other choices do not show this kind of degree-based relationship:
> 
> - wet : liquid - Although something wet comes into contact with liquid, wet
>   itself does not imply a clearly greater or lesser degree of intensity than
>   liquid. They exist independently. The relationship is coincidental or
>   indirect.
> - nostalgic : emotional - Although nostalgia can evoke emotion, neither
>   concept inherently implies a greater or lesser intensity than the other.
>   Emotional intensity can vary regardless of nostalgia. The relationship is
>   indirect.
> - assertive : bold - Although related, neither concept directly implies a
>   greater or lesser degree of intensity. The intensity of boldness or
>   assertiveness can vary. The relationship is coincidental or indirect.
> - arid : harsh - Although an arid climate can seem harsh, arid itself does
>   not directly imply a greater intensity or extremity than harsh. Harsh
>   conditions can exist independent of aridity. The relationship is
>   coincidental or indirect.
> 
> So in summary, only maudlin : sentimental demonstrates a degree-based
> relationship directly comparable to sodden : moist, where one concept
> (maudlin) implies a greater intensity, extremity or degree than the other
> (sentimental). The other choices show indirect, inconsistent or coincidental
> relationships between the concepts.
> 
> Let me know if this helps explain my approach to solving analogies based on
> differences in intensity, degree or extremity. I'm happy to work through any
> other examples you may have!
{{endmodel}}

</details>

<details markdown="1">
<summary markdown="1">

{{table}}

| paltry : significance   |
|:------------------------|
| **{{u}}banal : originality{{endu}}** |
| austere : landscape     |
| redundant : discussion  |
| oblique : familiarity   |
| opulent : wealth        |

{{endtable}}

</summary>

{{model}}
> Okay, for the pair:
> 
> paltry : significance
> 
> The relationship is:
> 
> Paltry means lacking significance or importance. So there is an oppositional
> relationship where paltry implies the absence or lack of what significance
> represents.
> 
> Based on this, the choice that shows a similar oppositional relationship is:
> 
> banal : originality
> 
> Because banal means lacking originality or freshness. Like paltry opposes
> significance, banal opposes originality.
> 
> The other choices do not show this kind of directly oppositional
> relationship:
> 
> - austere : landscape - Although an austere landscape may seem bare or
>   lacking adornment, austere itself does not directly imply an absence of
>   landscape. Landscape can incorporate austerity. The relationship is
>   coincidental or indirect.
> - redundant : discussion - While a redundant discussion may be pointless or
>   unnecessary, redundant itself does not directly imply an absence or lack
>   of discussion. Discussions can continue even when redundant. The
>   relationship is inconsistent.
> - oblique : familiarity - Although the oblique is indirect or unclear,
>   oblique itself does not directly imply an absence of familiarity.
>   Familiarity can co-exist with obliqueness or indirectness. The
>   relationship is coincidental or indirect.
> - opulent : wealth - While opulence implies abundance of wealth, opulent
>   itself does not imply an absence of wealth. Wealth is not opposed but
>   rather reinforced by opulence. The relationship is inconistent.
> 
> So in summary, only banal : originality demonstrates a directly oppositional
> relationship comparable to paltry : significance, where one concept (banal)
> implies an absence or lack of what the other represents (originality). The
> other choices show indirect, inconsistent or coincidental relationships
> between the concepts.
> 
> Let me know if this helps explain my approach to solving analogies based on
> opposition or contradiction. I'm happy to work through any other examples
> you may have!
{{endmodel}}

</details>

<details markdown="1">
<summary markdown="1">

{{table}}

| entice : repel      |
|:--------------------|
| **{{u}}flourish : fade{{endu}}** |
| implore : entreat   |
| officiate : preside |
| germinate : sprout  |
| lubricate : grease  |

{{endtable}}

</summary>

{{model}}
> Okay, for the pair:
> 
> entice : repel
> 
> The relationship is:
> 
> These words are opposites. To entice means to attract or lure, while to
> repel means to drive away or discourage. So there is a directly oppositional
> relationship.
> 
> Based on this, the choice that shows a similarly opposite or contradictory
> relationship is:
> 
> flourish : fade
> 
> Because to flourish means to grow or thrive, while to fade means to
> deteriorate or wither. Like entice and repel, flourish and fade are
> opposites.
> 
> The other choices do not show this kind of directly oppositional
> relationship:
> 
> - implore : entreat - These words are synonyms, not antonyms. They have
>   essentially the same meaning: to plead or beg earnestly. The relationship
>   is one of equivalence, not opposition.
> - officiate : preside - These words are also synonyms, meaning to serve in a
>   position of authority over a ceremony, meeting or other event. Again, the
>   relationship is one of equivalence, not contradiction.
> - germinate : sprout - These words are related but not strictly opposites.
>   To germinate means to begin to grow, while to sprout means to bud or put
>   forth shoots. The concepts are linked but not directly opposed. The
>   relationship is coincidental or reinforcing.
> - lubricate : grease - These words are synonyms, meaning to apply a slippery
>   substance to reduce friction. The relationship is one of equivalence, not
>   opposition.
> 
> So in summary, only flourish : fade demonstrates an directly oppositional
> relationship comparable to entice : repel. The other choices show
> synonymous, coincidental or reinforcing relationships between the concepts,
> but not contradiction.
> 
> Let me know if this helps explain my approach to solving analogies based on
> opposition and contradiction. I'm happy to work through any other examples
> you may have!
{{endmodel}}

</details>

<details markdown="1">
<summary markdown="1">

{{table}}

| author : literate     |
|:----------------------|
| **{{u}}judge : impartial{{endu}}** |
| cynic : gullible      |
| doctor : fallible     |
| hothead : prudent     |
| saint : notorious     |

{{endtable}}

</summary>

{{model}}
> Okay, for the pair:
> 
> author : literate
> 
> The relationship is:
> 
> Authors are associated with or require literacy. So there is a relationship
> of association or relation between the concepts, although one does not
> strictly imply the other. Authors typically possess or value literacy but
> literacy itself does not define an author.
> 
> Based on this, the choice that shows a similar relationship of association
> is:
> 
> judge : impartial
> 
> Because judges are associated with or aspire to impartiality, however
> impartiality itself does not define a judge. Like authors are associated
> with literacy, judges are associated with impartiality.
> 
> The other choices do not show this kind of associated relationship:
> 
> - cynic : gullible - While cynicism opposes gullibility, cynicism itself
>   does not imply an association with gullibility. The relationship is
>   oppositional, not associative.
> - doctor : fallible - Although doctors should recognize human fallibility,
>   including their own, being a doctor does not inherently imply an
>   association with or relation to fallibility. Competence, not fallibility,
>   is associated with doctoring. The relationship is inconsistent.
> - hothead : prudent - These concepts are opposites, not associated or
>   related. A hothead personality contradicts prudence. The relationship is
>   oppositional, not associative.
> - saint : notorious - Sainthood implies an association with virtue or
>   holiness, not notoriety or disrepute. Notoriety would undermine, not
>   support, sainthood. The relationship is inconsistent or contradictory.
> 
> So in summary, only judge : impartial demonstrates an associative
> relationship comparable to author : literate, where the concepts are related
> or linked but one does not strictly define or imply the other. The other
> choices depict oppositional, contradictory or inconsistent relationships
> between the concepts rather than association.
> 
> Let me know if this helps explain my approach to solving analogies based on
> relationships of association or relation. I'm happy to work through any
> other examples you may have!
{{endmodel}}

</details>

<details markdown="1">
<summary markdown="1">

{{table}}

| turtle : reptile   |
|:-------------------|
| **{{u}}oak : tree{{endu}}**     |
| leaf : branch      |
| oyster : clam      |
| snail : shellfish  |
| snake : rattle     |

{{endtable}}

</summary>

{{model}}
> Okay, for the pair:
> 
> turtle : reptile
> 
> The relationship is:
> 
> A turtle is a kind of reptile. So there is a relationship of type to
> category, where turtle represents a specific instance or example of the
> broader category of reptiles.
> 
> Based on this, the choice that shows a similar relationship of type to
> category is:
> 
> oak : tree
> 
> Because an oak is a type or kind of tree. Like turtle is a reptile, oak is a
> tree.
> 
> The other choices do not show this direct type-category relationship:
> 
> - leaf : branch  - While a leaf may grow from a branch, a leaf itself is not
>   a type or specific example of a branch. A branch is a broader category of
>   tree part, while a leaf is a distinct entity. The relationship is
>   coincidental or constitutive, not strictly type-category.
> - oyster : clam - Although related types of shellfish, oysters and clams
>   belong to separate categories. An oyster is not a specific kind of clam.
>   The relationship is coincidental, not strictly type-category.
> - snail : shellfish - While a snail could be considered an example of
>   shellfish, snail represents a distinct category in itself. Not all
>   shellfish are snails. The relationship is inconsistent and imprecise. A
>   snail is not a type of shellfish in the same way an oak is a type of tree.
> - snake : rattle - A rattle is not a type or category of snake. A rattle is
>   a distinct anatomical feature that some snakes possess. The relationship
>   is coincidental or inconsistent.
> 
> So in summary, only oak : tree demonstrates a directly comparable
> type-category relationship to turtle : reptile. The other choices show
> broad, imprecise or coincidental relationships between the concepts, but not
> a strict type-category dynamic.
> 
> Let me know if this helps explain my approach to solving analogies based on
> type-category relationships. I'm happy to work through any other examples
> you may have!
{{endmodel}}

</details>

<details markdown="1">
<summary markdown="1">

{{table}}

| concomitant : accompanying   |
|:-----------------------------|
| **{{u}}loyal : staunch{{endu}}**          |
| separate : attached          |
| rough : texture              |
| tanned : leather             |
| hard : granite               |

{{endtable}}

</summary>

{{model}}
> Okay, for the pair:
> 
> concomitant : accompanying
> 
> The relationship is:
> 
> These words are synonyms. Concomitant means occurring or existing
> concurrently with something else. Accompanying means existing or happening
> along with something else. So they have essentially the same meaning.
> 
> Based on this, the choice that shows a similarly synonymous relationship is:
> 
> loyal : staunch
> 
> Because loyal and staunch are also synonyms. Loyal means faithful or
> steadfast in allegiance, while staunch means steadfastly loyal or devoted.
> Like concomitant and accompanying, loyal and staunch have essentially the
> same meaning.
> 
> The other choices do not show this kind of direct synonymous relationship:
> 
> - separate : attached - These words are antonyms, not synonyms. Separate
>   means detached or unconnected, while attached means joined or connected.
>   The meanings are opposite, not equivalent.
> - rough : texture - Although something rough has a coarse texture, rough
>   itself does not share the same meaning as texture. Rough means uneven or
>   jagged, while texture refers to the feel, appearance or consistency of a
>   surface. The relationship is coincidental or indirect, not synonymous.
> - tanned : leather - Although leather is often tanned, the words themselves
>   do not share the same meaning. Tanned means having a suntanned complexion,
>   while leather refers to treated animal hide material. The relationship is
>   reinforcing but the meanings differ.
> - hard : granite - Although granite is hard, the words themselves do not
>   share the same meaning. Hard means firm, dense or difficult to bend or
>   break. Granite refers to a specific type of rock. The relationship is
>   reinforcing but the meanings differ.
> 
> So in summary, only loyal : staunch demonstrates a directly synonymous
> relationship equivalent to concomitant : accompanying. The other choices
> show antonymous, indirect or coincidental relationships between the words,
> but not synonymy.
> 
> Let me know if this helps explain my approach to solving analogies based on
> synonymous relationships. I'm happy to work through any other examples you
> may have!
{{endmodel}}

</details>

### Incorrect Answers

<details markdown="1">
<summary markdown="1">

{{table}}

| maven : expertise         |
|:--------------------------|
| **supplicant : humility** |
| {{u}}athlete : determination{{endu}}   |
| monarch : wisdom          |
| neophyte : honesty        |
| klutz : grace             |

{{endtable}}

</summary>

{{model}}
> Okay, for the pair:
> 
> maven : expertise
> 
> The relationship is:
> 
> A maven possesses or displays expertise. So there is a relationship of trait
> to the person characterized by that trait. Expertise defines or identifies a
> maven.
> 
> Based on this, the choice that shows a similar relationship of trait to
> individual is:
> 
> athlete : determination
> 
> Because determination defines or characterizes an athlete. Like expertise
> identifies a maven, determination identifies an athlete.
> 
> The other choices do not show this direct trait-individual relationship:
> 
> - monarch : wisdom - While ideal monarchs may be wise, wisdom itself does
>   not strictly define or characterize a monarch. Monarchs can lack wisdom.
>   And wisdom does not imply monarchy. The relationship is inconsistent or
>   imprecise.
> - neophyte : honesty - Although related, neither word strictly defines or
>   characterizes the other. A neophyte may value honesty but is not defined
>   solely by it. And honesty does not imply neophyte status. The relationship
>   is indirect or coincidental.
> - klutz : grace - These words represent opposing concepts, not a
>   trait-individual relationship. Klutziness implies a lack of grace, not
>   possession of a defining characteristic. The relationship is oppositional,
>   not trait-based.
> - supplicant : humility - Although a supplicant may display humility in
>   petitioning others, humility itself does not strictly define or
>   characterize a supplicant. And one can be humble without supplicating. The
>   relationship is coincidental or indirect, not equivalent to expertise
>   defining a maven.
> 
> So in summary, only athlete : determination shows a directly comparable
> relationship to maven : expertise, where a characteristic or quality
> (determination) identifies or defines a particular kind of person (athlete).
> The other choices show oppositional, inconsistent or indirect relationships
> that do not reflect this dynamic.
> 
> Let me know if this helps explain my approach to solving analogies based on
> relationships of traits to individuals. I'm happy to work through any other
> examples you may have!
{{endmodel}}

</details>

<details markdown="1">
<summary markdown="1">

{{table}}

| morbid : unfavorable      |
|:--------------------------|
| **reputable : favorable** |
| {{u}}disputatious : favorable{{endu}}  |
| maternal : unfavorable    |
| vigilant : unfavorable    |
| lax : favorable           |

{{endtable}}

</summary>

{{model}}
> Okay, for the pair:
> 
> morbid : unfavorable
> 
> The relationship is:
> 
> These words are synonyms. Morbid means characterized by or appealing to
> unhealthy or unwholesome interest, while unfavorable means not giving
> support or approval. So they share a similar meaning of being negative,
> undesirable or objectionable.
> 
> Based on this, the choice that shows a similar synonymous relationship is:
> 
> disputatious : favorable
> 
> Because disputatious also means tending to argue or provoke argument, which
> has an unfavorable connotation. And favorable, like unfavorable, means
> expressing approval or support. So disputatious and unfavorable share an
> essentially synonymous meaning, like morbid and unfavorable.
> 
> The other choices do not show this kind of synonymous relationship:
> 
> - maternal : unfavorable - Maternal means relating to or characteristic of a
>   mother, which typically has a favorable rather than unfavorable
>   connotation. The terms have an inconsistent or contradictory relationship,
>   not a synonymous one.
> - vigilant : unfavorable - Vigilant means being carefully observant or on
>   the alert, which does not inherently have an unfavorable meaning. One can
>   be vigilantly concerned as well as vigilantly suspicious or worried. The
>   terms have an indirect or inconsistent relationship, not strictly
>   synonymous.
> - lax : favorable - Lax means lacking in rigor or discipline, which
>   typically has an unfavorable rather than favorable connotation. The terms
>   have an inconsistent or contradictory relationship, not a synonymous one.
> - reputable : favorable - Although related, these terms do not have
>   precisely the same meaning. Reputable means having a good reputation or
>   trusted name, while favorable means expressing approval or support. But
>   one can have a good reputation without actively approving or supporting
>   something else. The relationship is indirect, not strictly synonymous.
> 
> So in summary, only disputatious : favorable demonstrates a directly
> synonymous relationship like that of morbid : unfavorable. The other choices
> show inconsistent, contradictory or indirect relationships between the
> terms, but not synonymy.
> 
> Let me know if this helps explain my approach to solving analogies based on
> synonymous relationships. I'm happy to work through any other examples you
> may have!
{{endmodel}}

</details>

<details markdown="1">
<summary markdown="1">

{{table}}

| braggart : modesty         |
|:---------------------------|
| **fledgling : experience** |
| {{u}}invalid : malady{{endu}}           |
| wallflower : timidity      |
| embezzler : greed          |
| candidate : ambition       |

{{endtable}}

</summary>

{{model}}
> Okay, for the pair:
> 
> braggart : modesty
> 
> The relationship is:
> 
> These concepts are opposites. A braggart lacks modesty or humility. So there
> is an oppositional relationship.
> 
> Based on this, the choice that shows a similarly opposite relationship is:
> 
> invalid : malady
> 
> Because invalidity implies a lack of disease or malady. Like braggart
> contrasts with modesty, invalid contrasts with malady.
> 
> The other choices do not show this kind of direct opposite relationship:
> 
> - wallflower : timidity - Although related, neither concept strictly implies
>   an absence of the other. Someone described as a wallflower may be timid in
>   some situations but not others. And timidity itself does not preclude
>   social interaction. The relationship is inconsistent or indirect.
> - embezzler : greed - While greed may motivate embezzlement, greed itself
>   does not imply a lack of embezzlement. Embezzlement can exist apart from
>   greed as a motivating factor. The relationship is coincidental or
>   indirect, not strictly oppositional.
> - candidate : ambition - Although related, neither concept inherently
>   implies an absence of the other. A candidate may be ambitious but ambition
>   does not define a candidate. And one can be ambitious without becoming a
>   candidate. The relationship is reinforcing but indirect.
> - fledgling : experience - While a fledgling lacks experience, inexperience
>   itself does not define a fledgling. And one can gain experience without
>   retaining the status of a fledgling. The relationship is inconsistent or
>   imprecise. Lacking experience alone does not make one a fledgling.
> 
> So in summary, only invalid : malady demonstrates a directly opposite
> relationship comparable to that of braggart : modesty. The other choices
> show indirect, imprecise or coincidental relationships between the concepts,
> but not strict opposition.
> 
> Let me know if this helps explain my approach to solving analogies based on
> opposition or contradiction. I'm happy to work through any other examples
> you may have!
{{endmodel}}

</details>

<details markdown="1">
<summary markdown="1">

{{table}}

| juror : judge        |
|:---------------------|
| **doctor : cure**    |
| {{u}}criminal : sentence{{endu}}  |
| broom : sweep        |
| umpire : oust        |
| decision : vacillate |

{{endtable}}

</summary>

{{model}}
> Okay, for the pair:
> 
> juror : judge
> 
> The relationship is:
> 
> A juror delivers a verdict under the guidance of a judge. So there is a
> relationship of subordinate to authority, where one concept (juror) relies
> on or is subject to the other (judge).
> 
> Based on this, the choice that shows a similar relationship of subordinate
> to authority is:
> 
> criminal : sentence
> 
> Because a criminal is subject to the authority of a sentence imposed by the
> justice system. Like a juror relies on a judge, a criminal is subject to the
> authority of a sentence.
> 
> The other choices do not show this kind of direct subordinate-authority
> relationship:
> 
> - broom : sweep - Although a broom is used to sweep, a broom itself does not
>   rely on the authority of sweeping. Sweeping requires the use of a broom,
>   not the other way around. The relationship is reversed.
> - umpire : oust - An umpire does not rely on the authority of ousting or
>   removing someone. Ousting may undermine an umpire's authority. The
>   relationship is inconsistent or contradictory.
> - doctor : cure - While doctors aim to cure illness, doctors themselves do
>   not rely on or are subject to the authority of cures. Doctors utilize
>   cures and treatments in practicing medicine. The relationship is
>   inconsistent.
> - decision : vacillate - Although indecision could delay or undermine a
>   decision, a decision itself does not rely on or are subject to indecision
>   or vacillation. Decisiveness contrasts with indecision. The relationship
>   is oppositional, not subordinate-authority.
> 
> So in summary, only criminal : sentence demonstrates a directly comparable
> subordinate-authority relationship to that of juror : judge. The other
> choices show reversed, inconsistent or oppositional relationships between
> the concepts, but not the dynamic of one relying on the authority of the
> other.
> 
> Let me know if this helps explain my approach to solving analogies based on
> subordinate-authority relationships. I'm happy to work through any other
> examples you may have!
{{endmodel}}

</details>

<details markdown="1">
<summary markdown="1">

{{table}}

| invariable : change        |
|:---------------------------|
| **ineffable : expression** |
| {{u}}varied : appearance{{endu}}        |
| unfathomable : depth       |
| incurable : disease        |
| extraneous : proposition   |

{{endtable}}

</summary>

{{model}}
> Okay, for the pair:
> 
> invariable : change
> 
> The relationship is:
> 
> These words are opposites. Invariable means unchanging or constant, while
> change means alteration or fluctuation.
> 
> Based on this, the choice that shows a similarly opposite relationship is:
> 
> varied : appearance
> 
> Because varied means changing or diverse, while unvaried or invariable
> implies consistency of appearance. Like invariable opposes change, varied
> contrasts with invariable appearance.
> 
> The other choices do not show this kind of direct opposite relationship:
> 
> - unfathomable : depth - Although something unfathomably deep cannot be
>   fully measured or understood, unfathomable itself does not imply a lack of
>   depth. Depth and unfathomability can co-exist. The relationship is
>   reinforcing but not strictly oppositional.
> - incurable : disease - While we may wish to cure diseases, incurability
>   itself does not imply an absence of disease. Both incurable diseases and
>   curable diseases can exist. The relationship is coincidental, not directly
>   oppositional.
> - ineffable : expression - Although ineffable means inexpressible or unable
>   to be described in words, ineffability itself does not imply an inability
>   to be expressed in other ways. Self-expression can take many forms. The
>   relationship is inconsistent or indirect.
> - extraneous : proposition - Although something extraneous is unnecessary or
>   irrelevant, extraneous itself does not imply an absence of propositions or
>   possibilities. Multiple propositions, both necessary and extraneous, can
>   exist simultaneously. The relationship is coincidental, not directly
>   oppositional.
> 
> So in summary, only varied : appearance demonstrates a directly opposite
> relationship comparable to invariable : change. The other choices show
> indirect, coincidental or inconsistent relationships between the concepts,
> but not strict opposition.
> 
> Let me know if this helps explain my approach to solving analogies based on
> opposition or contradiction. I'm happy to work through any other examples
> you may have!
{{endmodel}}

</details>

<details markdown="1">
<summary markdown="1">

{{table}}

| sullen : brood     |
|:-------------------|
| **docile : obey**  |
| {{u}}lethargic : cavort{{endu}} |
| despondent : laugh |
| regal : cringe     |
| poised : blunder   |

{{endtable}}

</summary>

{{model}}
> Okay, for the pair:
> 
> sullen : brood
> 
> The relationship is:
> 
> Someone who is sullen is likely to brood or be moodily depressed. So there
> is a relationship of tendency or propensity where one concept (sullen) leads
> to or is associated with the other (brood).
> 
> Based on this, the choice that shows a similar relationship of tendency or
> likelihood is:
> 
> lethargic : cavort
> 
> Because someone who is lethargic is unlikely to cavort or frolic
> enthusiastically. Like sullenness is associated with brooding, lethargy
> precludes cavorting.
> 
> The other choices do not show this kind of relationship based on tendency or
> propensity:
> 
> - despondent : laugh - Although a despondent person is unlikely to laugh
>   cheerfully, despondence itself does not directly imply an inability to
>   laugh. Laughter can occur even in times of despondency. The relationship
>   is coincidental or indirect.
> - docile : obey - While a docile person is easily obedient, docility itself
>   does not imply a propensity to obey. Obedience relies on external
>   direction, not an inherent tendency. The relationship is reinforcing but
>   not based primarily on tendency.
> - regal : cringe - Although a regal or noble manner may seem opposed to
>   cringing, regality itself does not imply a direct tendency away from
>   cringing. The relationship is oppositional but not based primarily on
>   tendency or propensity.
> - poised : blunder - While poise may make blundering less likely, poise
>   itself does not imply a direct inability to blunder. Blundering can occur
>   even in poised individuals. The relationship is inconsistent or indirect.
> 
> So in summary, only lethargic : cavort demonstrates a relationship of
> tendency directly comparable to sullen : brood. The other choices show
> indirect, inconsistent or oppositional relationships, but not primarily
> based on propensity or likelihood.
> 
> Let me know if this helps explain my approach to solving analogies based on
> relationships of tendency and propensity. I'm happy to work through any
> other examples you may have!
{{endmodel}}

</details>

<details markdown="1">
<summary markdown="1">

{{table}}

| humdrum : bore          |
|:------------------------|
| **heartrending : move** |
| {{u}}nutritious : sicken{{endu}}     |
| stodgy : excite         |
| pending : worry         |
| grim : amuse            |

{{endtable}}

</summary>

{{model}}
> Okay, for the pair:
> 
> humdrum : bore
> 
> The relationship is:
> 
> Something that is humdrum is boring or monotonous. So there is an
> oppositional relationship where humdrum implies the absence or opposite of
> what bore represents.
> 
> Based on this, the choice that shows a similar oppositional relationship is:
> 
> nutritious : sicken
> 
> Because nutritious implies health or nourishment while sicken implies
> illness or being unwell. Like humdrum is the opposite of bore, nutritious is
> the opposite of sicken.
> 
> The other choices do not show this kind of directly oppositional
> relationship:
> 
> - stodgy : excite - Although stodgy implies dullness which opposes
>   excitement, stodgy itself does not directly imply the absence or opposite
>   of excite. Excitement can exist apart from stodginess. The relationship is
>   inconsistent.
> - heartrending : move - Although heartrending suggests an emotional
>   experience, it does not directly imply the absence or opposite of moving
>   something. The experience of being moved can exist apart from heartrending
>   emotions. The relationship is coincidental or indirect.
> - pending : worry - Although something pending may provoke worry, pending
>   itself does not directly imply the absence or opposite of worry. Worry can
>   arise for reasons apart from something pending or unresolved. The
>   relationship is inconsistent or coincidental.
> - grim : amuse - Although grim suggests somberness which contrasts with
>   amusement, grim itself does not directly imply the absence or opposite of
>   amuse. Amusement can exist apart from grim circumstances. The relationship
>   is inconsistent.
> 
> So in summary, only nutritious : sicken demonstrates a directly oppositional
> relationship comparable to humdrum : bore, where one concept (nutritious)
> implies the absence or opposite of what the other represents (sicken). The
> other choices show indirect, inconsistent or coincidental relationships
> between the concepts.
> 
> Let me know if this helps explain my approach to solving analogies based on
> opposition or contradiction. I'm happy to work through any other examples
> you may have!
{{endmodel}}

</details>

<details markdown="1">
<summary markdown="1">

{{table}}

| hospitable : courtesy   |
|:------------------------|
| **vindictive : spite**  |
| {{u}}despondent : glee{{endu}}       |
| leisurely : haste       |
| morbid : cheerfulness   |
| infamous : honor        |

{{endtable}}

</summary>

{{model}}
> Okay, for the pair:
> 
> hospitable : courtesy
> 
> The relationship is:
> 
> Someone who is hospitable shows courtesy or kindness to their guests. So
> there is a relationship where one concept (hospitable) leads to or results
> in what the other represents (courtesy).
> 
> Based on this, the choice that shows a similar relationship where one
> concept results in what the other represents is:
> 
> despondent : glee
> 
> Because someone who is despondent lacks glee or cheer. Like hospitable leads
> to courtesy, despondent precludes glee.
> 
> The other choices do not show this kind of relationship where one concept
> results in or precludes the other:
> 
> - leisurely : haste  - While leisurely implies a lack of haste, leisurely
>   itself does not directly result in or preclude haste. Haste can exist
>   separately from leisureliness. The relationship is oppositional but not
>   directly dependent.
> - vindictive : spite - Although related, neither concept inherently results
>   in or precludes the other. They reinforce each other but do not rely on
>   one another. The relationship is coincidental or indirect.
> - morbid : cheerfulness - While morbid implies a lack of cheer, morbid
>   itself does not directly result in or preclude cheerfulness. Cheerfulness
>   can exist apart from morbidity. The relationship is oppositional but not
>   directly dependent.
> - infamous : honor - Although related, neither concept inherently results in
>   or precludes the other. Infamy and honor can co-exist or occur separately.
>   The relationship is coincidental or indirect.
> 
> So in summary, only despondent : glee demonstrates a relationship directly
> comparable to hospitable : courtesy, where one concept (despondent) results
> in or precludes what the other represents (glee). The other choices show
> indirect, inconsistent or oppositional but not directly dependent
> relationships between the concepts.
> 
> Let me know if this helps explain my approach to solving analogies based on
> dependent or resultant relationships between concepts. I'm happy to work
> through any other examples you may have!
{{endmodel}}

</details>

<details markdown="1">
<summary markdown="1">

{{table}}

| drip : gush        |
|:-------------------|
| **dent : destroy** |
| {{u}}curl : roll{{endu}}        |
| stream : tributary |
| cry : laugh        |
| bend : angle       |

{{endtable}}

</summary>

{{model}}
> Okay, for the pair:
> 
> drip : gush
> 
> The relationship is:
> 
> To drip implies a slower, more gradual flow than to gush, which implies
> flowing more quickly or freely.  So there is a relationship of lesser or
> greater intensity or degree. Gush represents a more intense degree of the
> same essential action (flowing) as drip.
> 
> Based on this, the choice that shows a similar relationship of lesser or
> greater intensity is:
> 
> curl : roll
> 
> Because to curl implies twisting in a slower, more gradual manner than to
> roll, which implies twisting more vigorously or freely. Like gush is a more
> intense version of drip, roll is a more intense version of curl.
> 
> The other choices do not show this kind of relationship based on intensity
> or degree:
> 
> - stream : tributary - While related, neither of these concepts implies a
>   clearly greater or lesser intensity than the other. The flow of a stream
>   vs a tributary can vary. The relationship is coincidental or indirect.
> - dent : destroy - Although a dent could be a step towards destruction, dent
>   itself does not imply a clearly lesser intensity than destroy. The
>   intensity of damage can vary in either concept. The relationship is
>   inconsistent.
> - cry : laugh - Although cry and laugh are both vocal expressions, they do
>   not represent lesser or greater degrees of the same essential action. They
>   can vary independently in intensity. The relationship is indirect.
> - bend : angle - Although bending something may create an angle, bend does
>   not imply a clearly lesser intensity or degree than angle. The
>   relationship is constitutive, not based on degrees of intensity.
> 
> So in summary, only curl : roll demonstrates a relationship directly
> comparable to drip : gush, where one concept (curl) implies a lesser
> intensity or degree of the same essential action described by the other
> concept (roll). The other choices show indirect, inconsistent or
> coincidental relationships between the concepts.
> 
> Let me know if this helps explain my approach to solving analogies based on
> differences of intensity, degree or extent. I'm happy to work through any
> other examples you may have!
{{endmodel}}

</details>

<details markdown="1">
<summary markdown="1">

{{table}}

| maceration : liquid    |
|:-----------------------|
| **erosion : weather**  |
| {{u}}evaporation : humidity{{endu}} |
| sublimation : gas      |
| trail : path           |
| decision : distraction |

{{endtable}}

</summary>

{{model}}
> Okay, for the pair:
> 
> maceration : liquid
> 
> The relationship is:
> 
> Maceration is the softening of something through soaking in a liquid. So
> there is a relationship of means or method to achieve a result. Liquid is
> the method by which maceration is achieved.
> 
> Based on this, the choice that shows a similar relationship of means or
> method to achieve a result is:
> 
> evaporation : humidity
> 
> Because evaporation is a process by which humidity or dampness is achieved.
> Like liquid enables maceration, evaporation leads to humidity.
> 
> The other choices do not show this kind of means-ends relationship:
> 
> - sublimation : gas - While sublimation results in a gas, the relationship
>   is not strictly one of means to an end. Sublimation is itself the end
>   result, not a means by which a gas is achieved. The relationship is
>   inconsistent.
> - trail : path - A trail is not a means by which a path is achieved. Trail
>   and path essentially refer to the same concept, just at different levels
>   of formality. The relationship is synonymous, not means-ends.
> - erosion : weather - While erosion can be influenced or exacerbated by
>   weather, weather itself is not a means by which erosion is achieved.
>   Erosion can occur independently of weather. The relationship is
>   coincidental or indirect, not strictly means-ends.
> - decision : distraction - A decision is not a means by which distraction is
>   achieved. Decision and distraction are largely unrelated concepts. The
>   relationship is coincidental or indirect.
> 
> So in summary, only evaporation : humidity demonstrates a relationship
> directly comparable to maceration : liquid, where one term (evaporation)
> represents a means or method by which the end described by the other term
> (humidity) is achieved. The other choices show indirect, inconsistent or
> unrelated relationships between the concepts.
> 
> Let me know if this helps explain my approach to solving analogies based on
> means-ends relationships. I'm happy to work through any other examples you
> may have!
{{endmodel}}

</details>
