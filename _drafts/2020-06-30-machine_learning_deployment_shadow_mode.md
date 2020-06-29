---
layout: post
title: "Comparison of My Two Sons' Language Development"
description: >
  Being a nerd dad, I recorded all the words my first two sons spoke as they
  learned them. Now, I compare their language development rate!
image: /files/my-sons-words-comparison/coal_miners_child_in_grade_school_lejunior_harlan_county_kentucky.jpg
image_alt: >
  Black and white photo of a young boy at a school desk.
categories: childhood_language
---

{% capture file_dir %}/files/my-sons-words-comparison/{% endcapture %}

Deploying machine learning models to give your users access is tough but it is
the only way to get value from them. 

[ml_powered]: https://www.oreilly.com/library/view/building-machine-learning/9781492045106/

One way of deploying a new model is *shadow mode*. 

## What Is Shadow Mode?

To launch a model in shadow mode you deploy the new, shadow model alongside
the old, live model. The live model continues to handle all the requests, but
the shadow model also runs on some (or all) of the requests. This allows you
to test the performance of the new model while relying on the tried-and-true
live model to serve the user.

Shadow mode works well when the result of the model does not need a user
action to validate it. Models where you try to influence the user, for example
a recommendation model where success means more sales converted, are best
tested using an [A/B test][ab]. The big difference between A/B and shadow mode
is that in an A/B test traffic is split between the two models and in shadow
mode the models operate on (some of) the same events.

[ab]: https://en.wikipedia.org/wiki/A/B_testing

There are two ways to put a model into shadow mode: in front of the API and
behind the API.

### In Front of the API

To put a model in shadow mode _in front of the API_, you host two API
endpoints---one for the live model and one for the shadow model---and the
caller simply makes a call to both of them whenever they would normally call
the live model. They can disregard the response, but they should log it so
that the results can be compared.

The advantages of this method are:

*The caller has control.* They decide when to switch the shadow model to live.
They can roll back instantly if there are problems. They can even stop the
experiment if it is hurting their system. *The call can be different.* If the
shadow model requires different inputs (perhaps a new ID associated with the
user) its API can be different than the live model.

The main disadvantages are: *The change is close to the customer.* The calling
code is generally closer to the core business, so any bug introduced is likely
to be more impactful. *Tighter coordination is required.* The team that owns
the model and the team that calls it have to be 

This gives the caller all the control, which is the main advantage. It lets
them decide when to switch out the models and lets them instantly switch back
if they decide to.

### In Front of the API
