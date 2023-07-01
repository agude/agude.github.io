---
layout: post
title: "Machine Learning Deployment: <br>Return Actions, Not Scores"
description: >
  A poorly designed machine learning model API will leave you trapped.
  Properly hiding your implementation will make life much easier!
image: /files/ml-api/00678-3489016266-a_simple_color_pencil_drawing_a_cute_robot,_plugging_cat5_cable_into_a_network_switch,_white_background.png
image_alt: >
    A colorful pencil drawing of two robots fussing with some techno-thingy
    between them. Generated with stable diffusion. Prompt: A simple color
    pencil drawing a ((cute robot)), plugging cat5 cable into a network
    switch, white background
categories:
  - machine-learning
  - machine-learning-engineering
---

{% capture file_dir %}/files/shadow-mode/{% endcapture %}

At a previous job, my team built models that stopped ATOs---[Account
takeovers][ato_wiki], where a fraudster steals someone's account credentials
and attempts to use them. The engineering team that owned the login flow would
call our model [API][api_wiki], and we would return the model score. The
engineering team had a threshold in their code, and if the score crossed that
threshold, they would take some action.

[ato_wiki]: https://en.wikipedia.org/wiki/Credit_card_fraud#Account_takeover
[api_wiki]: https://en.wikipedia.org/wiki/API

You can probably already see the problem: APIs are **meant to hide the inner
workings behind them**. But by returning the raw model scores, we revealed too
much detail. Any changes to the model, like retraining it, could change the
scores and break the front end.

In my guide to [_deploying machine learning models in shadow
mode_][shadow_mode_post], I stated that deploying changes "in front of the
API" has the advantage of giving the calling team control. This is precisely
why we built the ATO API the way we did: to address the organizational issue
that the engineering team did not trust the machine learning team.

[shadow_mode_post]: {% post_url 2020-06-30-machine_learning_deployment_shadow_mode %}#in-front-of-the-api

But if your teams trust each other, there is a much better way to build.

## What is a better way?

A better way is for the API to return **a set of actions**. For example, the
ATO model API might return the following actions:

- _Allow_: The login looks fine, allow it.
- _Step-up_: The login looks odd, require the user to provide a second factor
of authentication, such as a code sent to their email.
- _Lock_: The login looks clearly fraudulent, deny the login and lock the
account until the user recovers it.

These actions do a really good job of hiding the implementation behind the
API. You can freely change thresholds when the model performance changes,
retrain the model, or even replace it entirely.

But you can do something else too, you can add more models!

### Using multiple systems

A common fraud-prevention strategy is to train a model for each new fraud
pattern identified. This allows each model to be highly [precise][pr_wiki],
while also improving the [recall][pr_wiki] of the overall system. These
multi-model systems are often augmented with simple rules, such as "No logins
from Russia allowed." In the end, the system takes the outputs of the various
models and rules and aggregates them in some way. In our ATO example, the
system returns the most drastic action recommended by any model or rule.

[pr_wiki]: https://en.wikipedia.org/wiki/Precision_and_recall

In code:

```python
def ato_api(event_token):
  # List of actions returned by all the models and rules,
  # consists of values from {'Allow', 'Step-up', 'Lock'}
  all_results = get_ato_system_results(event_token)

  if 'Lock' in all_results:
    return 'Lock'
  elif 'Step-up' in all_results:
    return 'Step-up'

  return 'Allow'
```

Of course, this is a great place to use [enums][enum_post] and
[max][max_post]:

[enum_post]: {% post_url 2019-01-22-python_patterns_enum %}
[max_post]: {% post_url 2018-06-14-python_patterns_max_not_if %}

```python
from enum import IntEnum, unique

@unique
class Action(IntEnum):
  ALLOW = 0
  STEPUP = 1
  LOCK = 2

def ato_api(event_token):
  # List of actions returned by all the models and rules,
  # consists of values from Action() enum
  all_results = get_ato_system_results(event_token)

  return max(all_results)
```
