---
layout: post
title: "The Data Science Spectrum: <br>From Analyst to Machine Learning"
description: >
  Data science has left the era of the Unicorn and entered the era of the
  team, but that means there is now a whole spectrum of data science jobs.
  Here is what they do.
image: /files/data-science-spectrum/tribeam_prism.jpg
image_alt: >
  A triangular prism breaking white light into its components.
categories:
  - career-advice
  - data-science
  - interviewing
---

{% capture file_dir %}/files/data-science-spectrum/{% endcapture %}

The role of a data scientist has become narrower and more specialized as the
demand for them has increased. In my last post, [_The Data Science Split_][last_post], 
I talked about why I think this happened. In this post, I will walk through a
few of the most common roles in the data ecosystem and cover what they do and
what their skill sets are.

[last_post]: {% post_url 2021-05-31-the_data_science_split %}

It useful to know where you prefer to be on the data science spectrum, as it
will determine what roles you should apply for. "What are the responsibilities
of this position and what the key skills to be successful in it?" is one of
the first questions I ask when applying to a new position. The answer lets me
map that specific role to its place in the ecosystem and helps me determine if
I would be interested in the job.

## The Spectrum

You could define the spectrum of data science along multiple axises, but I
find using just one works pretty well:[^research]

[^research]: If I were to add a second axis, it would probably be
    **Researchiness** to differentiate the product focused data roles covered
    in this post from the more academic roles present at some large companies.
    The biggest difference is "publishing papers" is a metric more researchy
    roles track.

**Engineeriness**: Roughly, how close the role is to a traditional software
engineering role.

On the "low engineeriness" side of the spectrum you have roles that work
almost entirely with the contents of the data and domain-specific languages
for data access, processing, and plotting. As you move towards the other end
you start working with "lower-level" languages and often less on the on the
data itself and more on supportive tooling around it.

A particular job at a company could fall anywhere on the spectrum, but the
title gives a good idea of where exactly it fits. Below are five common job
titles in a rough order from least to most "engineery". Of course, in the real
world, the responsibilities of these jobs overlaps heavily with their
neighbors on the spectrum.

### Business Analyst

A _business analyst_[^biz] uses data to help the company understand what has
happened, what is happening, and what will likely happen so they can make
better decisions. Their primary deliverables are internal-facing reports,
dashboards, and presentations. They are generally really adept at SQL and
making data visualizations, but are less likely to use general-purpose
languages like Python.

[^biz]: Sometimes data analyst, business intelligence analyst, or even data
    scientist.

### Data Scientist

A _data scientist_[^ds] is an expert at statistics and experimental design.
They don't just plot trends, they understand what causes them, and how you can
influence them. They can clean a dataset, find biases, and then use it to
power decisions and products. They work with more general programming
languages like R or Python.

[^ds]: Also product data scientist, sometimes decision scientist,
    statistician. These align closely with [Michael
    Hochster's][@michaelhochster] [Type A Data Scientists][type_a_b].

[@michaelhochster]: https://twitter.com/michaelhochster
[type_a_b]: https://www.quora.com/What-is-data-science/answer/Michael-Hochster

### Modeler

_Machine learning modeler_[^mlm] is a rarer title, but I include it because I
feel it fills the hole between data scientist and machine learning engineer.
This role focuses on building models that directly impact customers. They find
customer problems, build machine learning models to solve them, and own those
models all the way from first iteration through hosting it in production. They
use Python, machine learning frameworks like TensorFlow, sometimes Scala and
Spark, Docker, and REST APIs.

[^mlm]: This role is sometimes called data scientist, sometimes machine
    learning engineer; often those two roles split the responcibility. These
    rolls are closer to [Michael Hochster's][@michaelhochster] [Type B Data
    Scientists][type_a_b].

This is the role I feel most comfortable in, with its mix of [software
development][dev], [machine learning][ml], and direct impact on customers.

[dev]: {% link topics/software-development.md %}
[ml]: {% link topics/machine-learning.md %}

### Machine Learning Engineer

A _machine learning engineer_[^mle] focuses on the platforms underlying
machine learning modeling and hosting. They often build ML tooling, hosting,
and pieces of ML specific infrastructure like feature stores. They focus on
making sure the machine learning models can scale to meet the demands of
running in production and return answers fast enough to be used. They
generally work with lower-level languages than the modelers like Scala or
Java. Many MLEs come from a software engineering background.

[^mle]: Sometime machine learning infrastructure engineer.

### Data Engineer

_Data engineers_ build the infrastructure the data flows through. All the SQL
databases, NoSQL, queues, streams, etc. that power the business and allow the
other data roles to make use of it. They're experts in a cloud services (where
these systems are mostly hosted) and scaling systems to meet the demands of
millions or billions of users while collecting and organizing their data.
