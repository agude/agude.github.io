---
layout: post
title: "Machine Learning Deployment: Shadow Mode"
description: >
  Deploying machine learning models is hard.
image: /files/shadow-mode/bricks_at_mit.jpg
image_alt: >
  A black and white photo of bricks making up Kresge Auditorium at MIT.
categories: machine-learning
---

{% capture file_dir %}/files/shadow-mode/{% endcapture %}

{% include lead_image.html %}

Deploying a machine learning product so that it can be used is essential to
getting value out of it. But it is one of the hardest parts of building the
product.

In this post I will focus on a small piece of deployment: _"How do I test my
new model in production?"_ One answer, and a way I often deploy models to
start, is **shadow mode**.

If you're interested in a broader overview of building and deploying machine
learning products, I highly recommend [Emmanuel Ameisen's][manu] book:
[_Building Machine Learning Powered Applications_][book]![^1]

[manu]: https://mlpowered.com/
[book]: https://mlpowered.com/book/

## What Is Shadow Mode?

To launch a model in shadow mode you deploy the new, shadow model alongside
the old, live model.[^2] The live model continues to handle all the requests,
but the shadow model also runs on some (or all) of the requests. This allows
you to test the new model while relying on the tried-and-true live model.

## When Would I Use Shadow Mode?

Shadow mode is a great way to test a few things:

- **Engineering**: With a shadow model you can test that the "pipeline" is
working, the model is getting the inputs it expects, and is returning results
in the correct format. You can also check the latency is not too high.
- **Outputs**: You can verify that the distribution of results looks the way
you expect (for example, your model is not reporting just a single value for
all input).
- **Performance**: You can verify that the shadow model is producing results
comparable to or better than the live model.

Shadow mode works well when the result of the model does not need a user
action to validate it. Models where you try to influence the user---for
example a recommendation model where success means more sales converted---are
best tested using an [A/B test][ab]. The big difference between an A/B test
and shadow mode is that in an A/B test traffic is split between the two models
and in shadow mode the models operate on the same events.

[ab]: https://en.wikipedia.org/wiki/A/B_testing

## How Do I Deploy In Shadow Mode?

There are two ways that I think of deploying in shadow mode. They are relative
to the [API][api] for the live model, and are [_in front of the live
API_][front] and [_behind the live API_][behind].

[api]: https://en.wikipedia.org/wiki/Application_programming_interface
[front]: #in-front-of-the-api
[behind]: #behind-the-api

### In Front of the API

To put a model in shadow mode _in front of the API_, you host two API
endpoints: one for the live model and one for the shadow model. The caller
makes a call to both of them whenever they would normally call the live model.
The caller can disregard the response, but they should log it so that the
results can be compared.

This way of deploying is great when the calling team is change-adverse or has
very strict requirements for how the shadow model must perform, because it
gives them control. I have found it useful for deploying models that have a
large effect on some [conversion funnel][funnel], like a model that runs at
new user creation and blocks suspected bad actors.

[funnel]: https://en.wikipedia.org/wiki/Conversion_funnel

The advantages of this method are:

- **The caller has control.** They decide when to switch the shadow model to
live. They can roll back instantly if there are problems. They can even stop
the experiment if it is hurting their system. 
- **The call can be different.** If the shadow model requires different inputs
(perhaps a new ID associated with the user) its API can be different than the
live model.

The main disadvantages are: 

- **The change is closer to the customer.** The calling code is generally
closer to the core business, so any bug introduced is likely to be more
impactful. 
- **Tighter coordination is required.** The team that owns the model and the
team that calls it will both have to make changes to their code, the model
team to spin up an endpoint and the calling team to add the second call and
logging action.

### Behind the API

To put a model in shadow mode _behind the API_, you change the code that
responds to API requests to call the live and shadow model. You log the
results of both models[^3] but only return the result from the live model.

This method is great when you want to move quickly, because you can change the
shadow model without having to coordinate with the calling team. To the
outside world the API looks unchanged and so hides the testing going on behind
it.

The advantages of this method are:

- **The model host has control.** You can change the shadow model, turn it
on, turn it off, swap in a new one at a whim. You can log exactly what you are
interested in recording.
- **Little coordination with other teams is required.** To the outside world
the API looks the same as before; no one else has to change their code.

The main disadvantages are:

- **The shadow model must be input compatable with the live model.** Since the
outside world is not changing what they pass to the API, your shadow model can
only use the same inputs as the live model (although it _can_ use a subset, or
get additional inputs via some other method).
- **You still have to change the calling code.** Eventually, when the model is
ready to replace the live model, you will need to change the API version and
change the calling code to use this new version. This means there is a little
extra work to be done once you are satisfied with your test results.

---

[^1]: **Disclaimer**: I was a technical editor for the book, but make no money off sales.
[^2]: By _"live model"_, I mean whatever system is currently doing the job that the shadow model will do. It could be a model, a heuristic, a simple `if` statement or even nothing at all.
[^3]: You are logging your live results, right?
