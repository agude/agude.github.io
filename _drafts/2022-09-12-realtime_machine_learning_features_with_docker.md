---
layout: post
title: "Computing Machine Learning Features in Real-time with Docker"
description: >
  Models often derive great value from real-time features, but computing them
  is hard. Using Docker, I show you one way of doing it.
image: /files/shadow-mode/bricks_at_mit.jpg
image_alt: >
  A black and white photo of bricks making up Kresge Auditorium at MIT.
categories: 
  - machine-learning
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

## Up-to-date Features

Keeping features up-to-date is challenging because every new interaction,
every event in the system, might cause a feature value to update. Consider the
feature that computes the "_Number of times the user has received a payment in
the past week_". As the user receives payments this number increases, but as
time goes on old payments drop out of the time window and the number decrease.
This feature can be computed ahead of time in most cases and the model just
retrieves the value from the feature store. This looks like this:

[![A diagram showing how computing features ahead of time works.][batch_pic]][batch_pic]

[batch_pic]: {{ file_dir }}/batched_feature_computation.svg

The events come in a never ending stream. Imagine the line of event boxes
moving from right to left, each one taking a turn to dump its data into the
feature store. The feature store then updates feature values.

The ML model also operates on events but it handles them as they're generated,
before they even have time to get to the feature store. The current event it
is considering I am calling the target event. These events will eventually
dump their data into the feature store (represented by a dotted line on the
diagram) but they have not had time to yet. The target event does give some
data to the ML model (generally something simple like a user ID or event ID so
the model knows what features to get) but this is fast.

## Real-time features

But what if the event the model is scoring is a received transaction? Or what
if the features can only be computed in real-time? For example, the feature
"_Has this user ever logged in from this location?_" is useful for detecting
and stopping account takeover attacks, but until you see the login event you
can not answer the question. 

We could use the same sort of system as the above diagram, but in this case we
have three options:

1. Run the model without the information from the most recent event.
2. Wait for the most recent event to reach the feature store and then
   predict.
3. Compute the feature in real-time outside the feature store.

The first option is easy but we lose valuable features. The second option is
slow and might add an unacceptable delay (for example we might have 100ms to
respond, but the feature store might take seconds to update).[^time_out] The
third option adds complexity, but allows a fast response while still making
use of the additional features. I will cover one way to do it below.

[^time_out]:
    A more likely outcome is the model will fail its [service-level
    agreement][sla] and the system will move on after a short time, ignoring
    the model and taking some default fallback option.

[sla]: https://en.wikipedia.org/wiki/Service-level_agreement

## Real-time Computation


