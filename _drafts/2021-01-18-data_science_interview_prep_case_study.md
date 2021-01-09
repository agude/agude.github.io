---
layout: post
title: "Data Science Interview Practice: Machine Learning Case Study"
description: >
  I often get asked how to practice data science interviews, so here is a
  practice dataset with a set of questions to answer. Good luck!
image: /files/interview-prep/food_conservation_workers_at_comstock_hall_cornell_1917.jpg
image_alt: >
  A black and white photo of four women sitting at desks with typewriters,
  stacks of papers, and card catalogs.
categories:
  - career-advice
  - interviewing
  - interview-prep
---

{% capture file_dir %}/files/interview-prep{% endcapture %}

A common interview type for data scientists and machine learning engineers is
the machine learning case study. In it, the interviewer will ask a question
about how the candidate would build a certain model. These questions can be
challenging for new data scientists because they often lack a lot of practical
experience building and shipping models in a business.

Just like last time where I [put together and example data manipulation
interview practice problem][last_post], this time I will walk you through a
practice case study.

[last_post]: {% post_url 2020-12-14-data_science_interview_prep_data_manipulation %}

## My Approach

I attack case study interviews in a set order:

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

Here are some questions I would ask about the problem:

**What systems do you currently have to do this? Do you have an ops team that
reviews bot accounts?** Likely they have some heuristic or simple rules system
already. If so, I'd want to find out what it's failing at. If they don't have
a system in place currently, it means I can target lower hanging fruit. In
either case a team and rules can be used to bootstrap labels for a model.

**Is there a specific type of bot that's causing problems? Like foreign
influence operations ("Russian Bots!") or cryptocurrency fraud bots or spam
bots?** Here I am trying to do two things: 

- Show that I have done my homework and have thought about some likely
problems the company faces.
- Trying to reduce the scope of the problem to a well-defined use case.

By the end of this discussion the interviewer and I have agreed to focus on
"spam bots", which are accounts that tweet advertising messages at people.

### Metric

Having decided to focus on spam, my first question is:

**How is this model going to be used? Is it just for tracking trends or is
there an enforcement action?** What action the model takes drives what metrics
we care most about. If this is just for tracking, perhaps we care most about
tagging all the bots, even if some humans get flagged. On the other hand, if
we're going to ban accounts we want to be reasonably sure that we have
targeted the right accounts. I covered thinking about metrics in detail in
another post: [_What Machine Learning Metric to Use_][metrics_post].

[metrics_post]: {% post_url 2019-10-28-machine_learning_metrics_interview %}

Often the interviewer will turn a question back to you. I suspect Twitter has
humans do some review of spam bots now, so I'd ask about that. If they do I
would proposed using the model to automatically block the most egregious
examples so humans can focus their attention elsewhere.

The metrics we will track are:

- Precision: We only want to block accounts we're really sure of; if some get
through humans can review those.
- Automated Spam fraction: Our goal is to reduce the amount of spam on the
platform, so we track that as a ratio to account for growth in the platform
that might make spam look like it's increasing. 

### Data

The interviewer will often tell you about a source of data in the prompt, but
there are often more sources you can reason about. For Twitter here are some
database they likely have that will be useful:

- A database of tweets, including sending account, any accounts mentioned,
time of the tweet, text of the tweet.
- A database of accounts with information about each user, when they signed
up, follower count, following count, etc.
- A database of login events with information about when accounts logged in,
the device and IP address of the login, if any multi-factor authentication was
passed.
- An ops database with information about what humans thought of various
different accounts that were reported as bots.

### Labels and Features

It helps to think what sort of behavior a spam bot might do, and then try to
build features around those. For example:

- Bots do not write each message, they use a template or other method of
generating text. So _message similarity_ is probably a good feature.
- Bots are used because they're cheap and scale, so things like number of
messages sent is likely useful, also number of unique accounts contacted.
- Bots are controlled from some place, so they might login from a small set of
IPs (or known cloud IPs), or from a small set of devices.
- Bots don't sleep or eat, so they can message around the clock as opposed to
a couple hours a day, so a feature around the number of hours active is likely
useful.

I'm going to treat this as a supervised classification, so I'll need labels as
well. If we have rules or an ops team we will likely be able to get some
labels from them. Otherwise we might have to do it by hand.

### Model Selection

I generally try to start at the simplest model that will work. Since this is
a supervised classification problem, logistic regression or a forest are good
candidates. I would likely go with a forest because they tend to "just work"
and are a little less sensitive to feature processing.

Deep learning is not something I would use here. It's great for image and
video, audio, or NLP, but for a problem where you have a set of labels, a set
of features that you believe to be predictive, it is generally overkill.

One thing to consider when training is the dataset is probably going to be
wildly imbalanced. I would start by down sampling (since we likely have
millions of events), but would be ready to discuss other methods and trade
offs.

### Validation
