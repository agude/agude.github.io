---
layout: post
title: "Computing Machine Learning Features in Real-time"
description: >
  Models often derive great value from real-time features, but computing them
  is hard because it has to be done quickly. Here is one way I have done it
  successfully.
image: /files/realtime-features/20110727-14-38-39--customs_house_tower_close.jpg
image_alt: >
  A black and white photo of the clock on the Customs House Tower in Boston.
categories: 
  - machine-learning
  - machine-learning-engineering
---

{% capture file_dir %}/files/realtime-features/{% endcapture %}

Machine learning models are excellent at automating simple, high frequency
decision, like:

- Should I allow this transaction?
- Should I allow this login?
- What items should I show this customer?

To make these decisions they need information about the event that they are
scoring. These pieces of information are called "[features][wiki_feature]".

[wiki_feature]: https://en.wikipedia.org/wiki/Feature_(machine_learning)

## Up-to-date Features and Real-time Features

Some features are easy to update. Features like "_The number of times the user
has received a payment in the past week_" are just counts that can be
maintained in a feature store. When a new payment comes in, add one to the
value. When another day has passed, subtract all the old payments out. Simple.

But some features are hard to keep up-to-date. What if we needed the value of
the received payment feature above, but to make a decision on _a received
payment_. Whatever system is keeping count now has to be very fast so it can
update the feature and return the value to the model in order to make a
decision without keeping the user waiting too long. In a payment system "too
long" could much less than a second!

Worse, some features can not be pre-computed at all. For example, the feature
"_Has this user ever logged in from this location?_" is very useful for
stopping account takeover fraud, but the model needs to make a decision before
the login completes. However, the feature can only be computed once the login
has started because only then do we know the location!

These features, that have to be computed during the event that a decision is
being made on, are called **real-time features**. I will talk about one way to
compute them below.

## A Machine Learning System

Let's consider a simplified machine learning system that that looks like this:

[![A diagram showing a machine learning system with incoming events, a feature
store, and a model host.][batch_pic]][batch_pic]

[batch_pic]: {{ file_dir }}/batched_feature_computation.svg

The **events** (in purple and green on the diagram) are a never ending stream.
Imagine the line of event boxes moving from right to left, each one taking a
turn to dump its data into the **feature store** (in orange). The feature
store uses the data in the events to update the values of features and reports
those values to other parts of the system.

The **model host** (in blue) also operates on events but it handles them as
they are generated, before they even have time to get to the feature store.
The event that the model is currently making a decision on is the **target
event** (in green).

The target event will eventually dump its data into the feature store
(represented by a dotted line on the diagram) but has not done so yet. The
target event does send some data to the model host (generally something simple
like a user ID or event ID so the model knows what features to get) but this
is fast compared to waiting for the feature store.

### Machine Learning Model Host

Let's take a closer look at the model host:

[![A diagram focusing on the model host component of the above diagram. It
shows how data handling code brings in features before passing them to the
model itself.][batch_model_pic]][batch_model_pic]

[batch_model_pic]: {{ file_dir }}/batched_model_host.svg

The **data handling code** (yellow in the diagram) gets IDs and other data
from the target event so that it knows what features to get. For example, it
might get a user ID so it can get all the features associated with that
specific user. It then passes the features it receives from the feature store
to the **machine learning model** (red in the diagram), which makes a decision
and sends it back to the target event (or the system handling the target
event).

## Real-time Computation

To use this system to calculate real-time features, we make three changes:

- Add "proto-features" to the feature store.
- Send more data from the target event to the model host.
- Do additional processing in the data handling code to combine the
  proto-features and data from the target event into a real-time feature.

The diagram changes very slightly:

[![A diagram focusing on the model host component of the first diagram. It
shows what modifying the system to calculate real-time features would look
like, with additional data handling code, proto-feature inputs, and more data
from the target event.][rt_model_pic]][rt_model_pic]

[rt_model_pic]: {{ file_dir }}/realtime_model_host.svg

Here is how that would work for our example login feature:

- Add a proto-feature that is a list of previous login locations.
- Add the current location to the data passed in from the target event.
- Update the data handling code to check if the current location is in the
  list of previous login locations from the proto-feature.
