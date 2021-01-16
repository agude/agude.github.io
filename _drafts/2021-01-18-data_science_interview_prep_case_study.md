---
layout: post
title: "Data Science Interview Practice: Machine Learning Case Study"
description: >
  A common interview type for data scientists and machine learning engineers
  is the ML case study. Read on for an example of how I solve them!
image: /files/interview-prep/henry_reid_at_his_desk_nasa.jpg
image_alt: >
  A black and white photo of Henry J.E. Reid, Directory of the Langley
  Aeronautics Laborator, in a suit writing while sitting at a desk.
categories:
  - career-advice
  - interviewing
  - interview-prep
---

{% capture file_dir %}/files/interview-prep{% endcapture %}

A common interview type for data scientists and machine learning engineers is
the machine learning case study. In it, the interviewer will ask a question
about how the candidate would build a certain model. These questions can be
challenging for new data scientists because the interview is open-ended and
new data scientists often lack practical experience building and shipping
models in a business context.

I have a lot of practice with these types of interviews, both from my time at
[Insight][should_i_go], from my many times [interviewing for a new
job][interviewing], and from designing and implementing Intuit's data science
interview. Just like last time where I [put together an example data
manipulation interview practice problem][last_post], this time I will walk you
through a practice case study and how I would work through it.

[should_i_go]: {% post_url 2018-08-21-should_i_go_to_insight %}
[interviewing]: {% post_url 2020-09-21-interviewing_for_data_science_positions_in_2020 %}
[last_post]: {% post_url 2020-12-14-data_science_interview_prep_data_manipulation %}

## My Approach

Case study interviews are just conversations. This can make them tougher than
they need to be because they lack the obvious structure of a coding interview
or [data manipulation interview][last_post]. I find it's helpful to impose
some structure on the conversation by approaching the problem in this order:

1. **Problem**: Dive in with the interviewer and explore what the problem is.
   Look for edge cases, simple cases that you might be able to close out
   quickly, and high impact parts of the problem.
2. **Metrics**: Once you have decided what exactly you're solving for, figure
   out how you will measure success. Focus on what is important to the
   business and not just what is easy to measure.
3. **Data**: Figure out what data is available to solve the problem. The
   interview might give you a couple of examples, but ask about additional
   information sources. If you know of some public data that might be useful,
   bring it up here too.
4. **Labels and Features**: Using the data sources you discussed, what
   features would you build? If you are attacking a supervised classification
   problem, how would you generate labels? How would you see if they were useful?
5. **Model**: Now that you have a metric, data, features, and labels, what
   model is a good fit? Why? How would you train it? What do you need to watch
   out for?
6. **Validation**: How would you make sure you model works offline? What data
   would you hold out? What metrics would you measure?
7. **Deployment and Monitoring**: Having developed a model you are comfortable
   with, how would you deploy it? Does it need to be real-time or can you get
   away with batch? How would you check performance in production? How would
   you monitor for drift?

I will cover each of these in more detail below as I walk through a specific
example.

## Case Study

Here is the prompt:

> At Twitter, bad actors occasionally use automated accounts, known as "bots",
> to abuse our platform. How would build a system to help detect bot accounts?

### Problem

At the start of the interview I try to fully explore the bounds of the
problem, which is often pretty open ended. My goal with this part of the
interview is to:

- Understand the problem and all the edges cases.
- Agree on the scope of the problem to solve, the tighter the better.
- Demonstrate any knowledge I have on the subject, especially from researching
  the company previously.

Our Twitter bot prompt has a lot of things we could attack. I know Twitter has
dozens of types of bots from my [harmless Raspberry Pi bots][rpi_bot], to
["Russian Bots" trying to influence elections][russia_bot], to [bots spreading
spam][spam_bot]. I would pick one problem to focus on using my best guess as
to business impact. In this case spam bots are likely a problem that causes
measurable harm (drives users away, drives advertisers away). Russian bots are
probably a bigger issue in terms of public perception, but that's much harder
to measure.

[rpi_bot]: {% post_url  2017-11-13-raspberry_pi_reboot_times %}
[russia_bot]: https://en.wikipedia.org/wiki/Russian_web_brigades 
[spam_bot]: https://en.wikipedia.org/wiki/Spambot

After deciding on the scope, I would ask more about the systems they currently
have to deal with it. Likely Twitter has an ops team to help identify spam and
block accounts and they may even have a rules based system. Those systems will
be a good source of data about the bad actors and they likely also have
metrics they track for this problem.

### Metric

Having agreed on what part of the problem to focus on, we now turn to how we
are going to measure our impact. There is no point shipping a model if you
can't measure how it's affecting the business.

Metrics and model use go hand-in-hand, so first we have to agree on what the
model will be used for. For spam we could use the model to just mark suspected
accounts for human review and tracking, or we could outright block accounts
based on the model result. If we pick the human review option, it's probably more
important to get all the bots even if some good customers are affected. If we
go with immediate action, it is likely more important to only ban bad
accounts. I covered thinking about metrics like this in detail in
another post, [_What Machine Learning Metric to Use_][metrics_post]. Take a
look!

[metrics_post]: {% post_url 2019-10-28-machine_learning_metrics_interview %}

I would argue the automatic blocking model will have higher impact because it
frees our ops people to focus on other bad behavior. We want two sets of
metrics: **offline** for when we are training and **online** for when the
model is deployed.

Our offline metric will be **precision** because, based on the argument above,
we want to be really sure we're only banning bad accounts.

Our online metrics are more business focused:

- **Ops time saved**: Ops is spending some amount of time review spam now; how
much can we cut that down?
- **Spam fraction**: What percent of Tweets are spam now? Can we reduce this?

It is often useful, as with the spam fraction metric, to normalize our metrics
so they don't go up or down just because we have more customers!

### Data

Now that we know what we're doing and how to measure its success, it's time to
figure out what data we can use. Just based on how a company operates, you can
make a really good guess as to the data they have. For Twitter we know they
have to track Tweets, accounts, and logins, so they must have databases with
that information. Here are what I think they contain:

- **Tweets database**: Sending account, mentioned accounts, parent Tweet,
  Tweet text.
- **Interactions database**: Account, Tweet, action (retweet, favorite, etc.)
- **Accounts database**: Account name, handle, creation date, creation
  device, creation IP address.
- **Following database**: Account, followed account.
- **Login database**: Account, date, login device, login IP address, success
  or fail reason.
- **Ops database**: Account, restriction, human reasoning.

And a lot more. From these we can find out a lot about an account and the
Tweets they send, who they send to, who those people react, and possibly how
login events tie different accounts together.

### Labels and Features

Having figured out what data is available, it's time to process it. Because
I'm treating this as a classification problem, I'll need **labels** to tell me
the ground truth for accounts, and I'll need **features** which describe the
behavior of the accounts.

### Labels

Since I have an ops team handling spam, I have historic examples of bad
behavior which I can use as positive labels.[^positive_labels] If there aren't
enough I can use tricks to try to expand my labels, for example looking at IP
address or devices associated with spammers and labeling other accounts from
the same place and time.

[^positive_labels]:
    In this case a _positive label_ means the account is a spam bot, and a
    _negative label_ means they are not.

Negative labels are harder to come by. I know Twitter has verified users who
are unlikely to be spam bots, so I can use them. That dataset is also likely
highly imbalanced, that is most users are not spammers, so randomly selecting
accounts is also a possibility to build negative labels.

### Features

To build features, it helps to think what sort of behavior a spam bot might
do, and then try to codify that behavior. For example:

- **Bots can't write truly unique messages**; they must use a template or
  language generator. This should lead to similar messages, so looking at how
  repetitive an accounts Tweets are is a good feature.
- **Bots are used because they scale.** They can run all the time and send
  messages to hundreds or thousands (or millions) or users. Number of unique
  Tweet recipients and number of minutes per day with a Tweet sent are likely
  good features.
- **Bots have a controller.** Someone is benefiting from the spam, and they
  have to control their bots. Features around logins might help here like
  number of accounts seen from this IP address or device, similarity of login
  time, etc.

### Model Selection

I generally try to start at the simplest model that will work. Since this is
a supervised classification problem and I have written some simple features,
logistic regression or a forest are good candidates. I would likely go with a
forest because they tend to "just work" and are a little less sensitive to
feature processing.[^processing]

[^processing]:
    If using [regularization] (and you should) you have to scale your
    features for logistic regression. Random forests do not require this.

[regularization]: https://en.wikipedia.org/wiki/Regularization_(mathematics)

Deep learning is not something I would use here. It's great for image and
video, audio, or NLP, but for a problem where you have a set of labels, a set
of features that you believe to be predictive, it is generally overkill.

One thing to consider when training is the dataset is probably going to be
wildly imbalanced. I would start by down-sampling (since we likely have
millions of events), but would be ready to discuss other methods and trade
offs.

### Validation

Validation is not too hard at this point. We focus on the offline metric we
decided on above: precision. We don't have to worry much about leaking data
between our holdout sets if we split at the account level, although if we
include bots from the same [botnet][botnet] into our different sets there will
be a little data leakage. I would start with a simple validation/training/test
split with fixed fractions of the dataset.

[botnet]: https://en.wikipedia.org/wiki/Botnet

### Deployment

Since our goal is to block accounts, I would deploy our model in **shadow
mode**, which I [discussed in detail in another post][shadow_mode]. This would
allow us to see how the model performs on real data without the risk of
blocking good accounts. I would track it's performance using our online
metrics: spam fraction and ops time saved. I can compute these metrics both
assuming the model does and does not block the flagged accounts and then
compare them. If the comparison is favorable, the model should be promoted to
action mode.

[shadow_mode]: {% post_url 2020-06-30-machine_learning_deployment_shadow_mode %}

## Let Me Know!

I hope this exercise has been helpful! Please reach out and let me know at
[@{{ site.author.twitter }}][twitter] if you have any comments or
improvements!

[twitter]: https://twitter.com/{{ site.author.twitter }}

---
{% comment %}<hr> above footnotes.{% endcomment %}
