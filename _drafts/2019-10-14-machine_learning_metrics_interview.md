---
layout: post
title: "Interview Question: What Machine Learning Metric to Use"
description: >
  One of my favorite questions to ask in an interview is what metric to use to
  decide if you model works. Read on to find out what a good answer looks
  like!
image: /files/interviews/Artgate_Fondazione_Cariplo_-_Canova_Antonio,_Allegoria_della_Giustizia.jpg
image_alt: >
  TODO REPLACE
categories: inteviewing
---

{% capture file_dir %}/files/interviews/{% endcapture %}

{% include lead_image.html %}

As part of our interview cycle, candidates work with some data and build a
simple model. After we talk through the modeling and data work, I ask them to
come up with a business case for the model. Once they have done so, I follow
up with:

> How would you measure the success of this model in production?

I have heard a lot of answers. They generally fall into two categories: machine learning
theory focused, and business focused. The first is good, the second is better.
I will go through each below.

To have something concrete to discuss, we will consider the following problem:
"Train a model to classify customers as _'high value customer'_, and use it to
decide if we are going to show them an up-sell page."

## Machine Learning Theory Focused

A common answer, especially from more junior interviewees, is "Accuracy",
which is the number of things your model classifies correctly divided by the
total number of things.

**Accuracy is rarely a good answer for real world problems**, because the
classes are often imbalanced. If only 1 in 1000 users is a _'high value
customer'_, then a model that only returns false would have an accuracy of
99.9%, but is clearly worthless.

When pushed about accuracy's obvious shortcomings, the candidate may fall back
to something like F1 score, which is the harmonic mean of precision and
recall. **F1 is a lazy answer**. It is better than accuracy because it is
relatively less sensitive to imbalanced data, but rarely are precision and
recall equally important. Instead, we consider how a customer might interact
with the model to decided of the two metrics to weight more heavily.

## Customer Focused

The best candidates consider the problem more deeply. Instead of jumping to
find a metric, they start by thinking about the experience of using a model
from a business or user perspective. A good way to frame this is "What does a
false positive cost my user?" and "How does that compare to the cost of a
false negative?" 

Sometimes a _false positive is costly_, as might be the case if the action we
take with out model is drastic like shutting down a user's account. In that
case we need to be confident that when we do take action, we are only
targeting the right users. Then [precision][precision] is more important,
since we want to make sure the most of the events the model flags are true
positives. This is not the case for our _'high value customer'_ model, because
showing a user an up-sell page is unlikely to hurt them or cause them to
churn.

[precision]: https://en.wikipedia.org/wiki/Precision_and_recall#Recall 

Instead, in our case a _false negative is costly_, because we lose the chance
at a large revenue increase from the up-sell. [Recall][recall] is more
important, as we would rather show a few extra users our up-sell page than
miss the chance to convert a sale.

[recall]: https://en.wikipedia.org/wiki/Precision_and_recall#Recall 

A good answer then would conclude that recall is the right metric to weight
more heavily, but the answer would include the rational I explained above
considering the cost of the model on the user.

## The Best Metric: Dollars

The best metric then is the formalized version of our customer focused one:
dollars. Assigning a dollar value to each model result (true positive, false
positive, etc.) would allow us to optimize for revenue. This is often doable
in simple models (like our _'high value customer'_ model), but in more
complicated ones (like the fraud models I work on) it can be difficult.[^1]
For an example of using dollars in model optimization, see Airbnb's post on
[_Fighting Financial Fraud with Targeted Friction_][airbnb].

[airbnb]: https://medium.com/airbnb-engineering/fighting-financial-fraud-with-targeted-friction-82d950d8900e

---

[^1]: One of our largest costs is [reputational risk][rep_risk], which is very hard to assign a number to.

[rep_risk]: https://en.wikipedia.org/wiki/Reputational_risk
