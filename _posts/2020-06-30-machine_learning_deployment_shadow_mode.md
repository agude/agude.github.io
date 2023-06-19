---
layout: post
title: "Machine Learning Deployment: Shadow Mode"
description: >
  Deploying machine learning models is hard; Shadow Mode is one way to make
  testing a little easier.
image: /files/shadow-mode/bricks_at_mit.jpg
image_alt: >
  A black and white photo of bricks making up Kresge Auditorium at MIT.
categories: 
  - machine-learning
  - machine-learning-engineering
---

{% capture file_dir %}/files/shadow-mode/{% endcapture %}

Deploying a machine learning product so that it can be used is essential to
getting value out of it. But it is one of the hardest parts of building the
product.

In this post I will focus on a small piece of deployment: _"How do I test my
new model in production?"_ One answer, and a method I often employ when
initially deploying models, is **shadow mode**.

If you're interested in a broader overview of building and deploying machine
learning products, I highly recommend [Emmanuel Ameisen's][manu] book:
[_Building Machine Learning Powered Applications_][book]![^disclaimer]

[manu]: https://mlpowered.com/
[book]: https://mlpowered.com/book/
[^disclaimer]: **Disclaimer**: I was a technical editor for the book, but make no money off sales. 

## What Is Shadow Mode?

To launch a model in shadow mode, you deploy the new, shadow model alongside
the old, live model.[^live] The live model continues to handle all requests,
but the shadow model also runs on some (or all) of the requests. This allows
you to safely test the new model against real data while avoiding the risk of
service disruptions.

[^live]:
    By _"live model"_, I mean whatever system is currently doing the job that
    the shadow model will do. It could be a model, a heuristic, a simple `if`
    statement, or even nothing at all.

## When Would I Use Shadow Mode?

Shadow mode is a great way to test a few things:

- **Engineering**: With a shadow model you can test that the "pipeline" is
working: the model is getting the inputs it expects, and it is returning
results in the correct format. You can also verify that the latency is not too
high.
- **Outputs**: You can verify that the distribution of results looks the way
you expect (for example, your model is not reporting just a single value for
all input).
- **Performance**: You can verify that the shadow model is producing results
that are comparable to or better than those of the live model.

Shadow mode works well when the result of the model does not need a user
action to validate it. Models where you try to influence the user---for
example a recommendation model where success means more sales converted---are
better tested using an [A/B test][ab]. The big difference between an A/B test
and shadow mode is that in an A/B test traffic is split between the two models
whereas in shadow mode the two models operate on the same events.

[ab]: https://en.wikipedia.org/wiki/A/B_testing

## How Do I Deploy In Shadow Mode?

There are two general methods that I use for deploying in shadow mode. Both
are relative to the [API][api] for the live model: either [_in front of the
live API_][front] or [_behind the live API_][behind].

[api]: https://en.wikipedia.org/wiki/Application_programming_interface
[front]: #in-front-of-the-api
[behind]: #behind-the-api

### In Front of the API

To put a model in shadow mode _in front of the API_, you host two API
endpoints: one for the live model and one for the shadow model. The caller
makes a call to both of them whenever they would normally call the live model.
The caller can disregard the response, but they should log it so that the
results can be compared. I have drawn this structure below:

[![A diagram showing how in front of the API shadow mode is constructed.][front_pic]][front_pic]

[front_pic]: {{ file_dir }}/shadow_mode_in_front_of_the_api.svg

This way of deploying is well-suited to situations where the calling team is
change-adverse or has very strict requirements for how the shadow model must
perform because it gives them control. I have found it useful for deploying
models that have a large effect on some [conversion funnel][funnel], like a
model that runs at new user creation and blocks suspected bad actors.

[funnel]: https://en.wikipedia.org/wiki/Conversion_funnel

The advantages of this method are:

- **The caller has control.** They decide when to switch the shadow model to
live. They can roll back instantly if there are problems. They can even stop
the experiment if it is hurting their system. 
- **The call can be different.** If the shadow model requires different inputs
(perhaps a new ID associated with the user), its API can be different than
that of the live model.

The main disadvantages are: 

- **The change is closer to the customer.** The calling code is generally
closer to the core business, so any bug introduced during integration of the
shadow model is likely to be more impactful. 
- **Tighter coordination is required.** The team that owns the model and the
team that calls it will both have to make changes to their code: the model
team to spin up an endpoint, and the calling team to add the call to the
second model as well as a logging action.

### Behind the API

To put a model in shadow mode _behind the API_, you change the code that
responds to API requests to call the live and shadow model. You log the
results of both models[^logging] but only return the result from the live
model. I have drawn a schematic of this below:

[^logging]: You _are_ logging your live results, right?

[![A diagram showing how behind the API shadow mode is constructed.][behind_pic]][behind_pic]

[behind_pic]: {{ file_dir }}/shadow_mode_behind_the_api.svg

This method is great when you want to move quickly (and break things), because
you can change the shadow model without having to coordinate with the calling
team. To the outside world the API looks unchanged and so hides the testing
going on behind it.

The advantages of this method are:

- **The model host has control.** You can change the shadow model, turn it on,
turn it off, and swap in a new one at a whim. You can log exactly what you are
interested in recording.
- **Little coordination with other teams is required.** To the outside world
the API looks the same as before; no one else has to change their code.

The main disadvantages are:

- **The shadow model must be input compatible with the live model.** Since the
outside world is not changing what it passes to the API, your shadow model is
restricted to the same inputs as the live model (although it _can_ choose to
use only a subset, or get additional inputs via some other method).
- **You still have to change the calling code.** Eventually, when the model is
ready to replace the live model, you will need to change the API version and
change the calling code to use this new version. This means there is a little
extra work to be done once you are satisfied with your test results.

## Conclusion

Deploying a model in shadow mode is an easy way to test your model on live
data. It is flexible and allows you to empower the right team to control the
experiment.
