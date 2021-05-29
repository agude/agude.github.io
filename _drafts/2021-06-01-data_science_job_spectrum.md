---
layout: post
title: "The Data Science Spectrum:<br>From Analyst to Machine Learning"
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

I discovered data science as a possible career in 2014 when I was looking for
something to do after [deciding not to pursue a career in academia][phd]. Less
than a year later I was a professional data scientist,[^pro] having moved
across country and gotten a job with the help of [Insight][insight]. It was
there that I realized that the data science role was already splintering into
multiple, specialized roles.

[^pro]: At least in the sense that I was paid to do it... I don't claim to
    have been any good.

[phd]: /blog/should-i-get-a-phd/#but-there-are-no-jobs
[insight]: {% post_url 2018-08-21-should_i_go_to_insight %}

## The Spectrum

But data science did not just split in two or even three pieces. It expanded
into a full spectrum of roles. You could define the differences between these
roles along multiple axises, but I find using just one works pretty well:

**Engineeriness**: Roughly, how close the role is to a traditional software
engineering role.

On the "low engineeriness" side of the spectrum you have roles that work
almost entirely with data and domain-specific languages for data access and
processing. As you move towards the other end you start working with
"lower-level" languages and often less on the content on the data and more on
supportive tooling around it.

A specific job at a particular company could fall anywhere on the spectrum,
but the title gives a good idea of where exactly it fits. Below are five
common job titles in a rough order from least to most "engineery". Of course,
in the real world, the responsibilities of these jobs overlaps heavily with
their neighbors on the spectrum.

### Business Analyst

A _business analyst_[^biz] uses data to help the company understand what has
happened, what is happening, and what will likely happen so they can make
better decisions. Their primary deliverables are internal-facing reports,
dashboards, and presentations. They are generally really adapt at SQL and
making data visualizations, but are less likely to use general-purpose
languages like Python.

[^biz]: Sometimes data analyst, business intelligence analyst, or even data
    scientist.

### Data Scientist

A _data scientist_[^ds] is an expert at statistics and experimental design.
They don't just plot trends, they understand what causes them, and how you can
influence them. They can clean a dataset, find biases, and then use it to
power decisions and products. They use more general programing languages like
R or Python.

[^ds]: Also product data scientist, sometimes decision scientist,
    statistician. These align closely with [Michael
    Hochster's][@michaelhochster] [Type A Data Scientists][type_a_b].

[@michaelhochster]: https://twitter.com/michaelhochster
[type_a_b]: https://www.quora.com/What-is-data-science/answer/Michael-Hochster

### Modeler

_Machine learning modeler_[^mlm] is a rare title, but I include it because I
feel it fills the hole between data scientist and machine learning engineer.
This role focuses on building models that directly impact customers. They find
customer problems, building models to solve them, and own them all the way
from first iteration through hosting it in production. They use Python,
machine learning frameworks like TensorFlow, sometimes Scala and Spark,
Docker, and REST APIs.

This is the role I feel most comfortable in, with its mix of software
development, machine learning, and direct impact on customers.

[^mlm]: This role is sometimes called data scientist, sometimes machine
    learning engineer; often it those two roles split the responcibility.
    These rolls are closer to [Michael Hochster's][@michaelhochster] [Type B
    Data Scientists][type_a_b].

### Machine Learning Engineer

A _machine learning engineer_[^mle] focuses on the engineering underlying
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
these systems are mostly hosted) and scaling systems meet the demands of
millions or billions of users while collecting and organizing their data.

---
