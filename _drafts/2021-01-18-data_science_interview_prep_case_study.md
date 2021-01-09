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

<!-- Simple script to call from the "Show/Hide" buttons-->
<script type="text/javascript">
function showhide(element) {
  if (element.style.display !== "none") {
    element.style.display = "none";
  } else {
    element.style.display = "block";
  }
}
</script>

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

Here is the question:

> Here at Twitter, bad actors occasionally use automated accounts, known as
> "bots", to abuse our platform. How would build a system to help detect bot
> accounts?

### Problem

Here are some questions I would ask about the problem:

**What systems do you currently have to do this?** Likely they have some
heuristic or simple rules system already. If so, I'd want to find out what
it's failing at. If they don't have a system in place currently, it means I
can target lower hanging fruit.

**Is there a specific type of bot that's causing problems? Like foreign
influence operations ("Russian Bots!") or cryptocurrency fraud bots or spam
bots?** Here I am trying to do two things: 

- Show that I have done my homework and have thought about some likely problems the company faces.
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

Often the interviewer will turn a question back to you. I suspect Twitter has
humans do some review of spam bots now, so I'd ask about that. If they do I
would proposed using the model to automatically block the most egregious
examples so humans can focus their attention elsewhere.

The metrics we would track are:

- Precision: We only want to block accounts we're really sure of; if some get
through humans can review those.

[metrics_post]: {% post_url 2019-10-28-machine_learning_metrics_interview %}
