---
layout: post
title: "The Spectrum of Data Science Jobs:<br>From Unicorns to Teams"
description: >
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
there I realized that the data science role was splintering into multiple,
specialized roles.

[phd]: /blog/should-i-get-a-phd/#but-there-are-no-jobs
[insight]: {% post_url 2018-08-21-should_i_go_to_insight %}

## The Split

At Insight people fell into two broad skill sets: those most interested in
statistics and experiment design and those most interested in coding and
machine learning. We interviewed for the same roles because most companies
were not more specific about what they were looking for than "data <span
class="nowrap">scientists".[^unicorn]</span>

This wasted a lot of time for us and for the companies as they interviewed
people who did not fit the job profile nor were interested in doing so.
It became clear that data science covered too many skills and responsibilities
to be lumped into one job title, which meant it would inevitably split into
multiple, distinct roles.

The split made sense for many reasons:

- **There are no unicorns.** Data scientists who are experts in every part of
  the data ecosystem are not just rare, they are mythical. Everyone has
  strengths and weaknesses. By splitting the role, people could focus on the
  part they were most passionate about.
- **Training a person to do it all takes too long.** In the beginning, most
  data scientists had PhDs in some data-related field. They each spent a
  decade learning math, statistics, coding, how to work with large datasets,
  how to structure an experiment, et cetera, et cetera, et cetera. But that
  process was and is too slow to meet the current demand for data scientists.
  A shorter, undergraduate major was required (and has since been adopted by
  almost every major college). Of course the best way to teach ten years worth
  of knowledge in four is to split it across three people. Splitting the job
  into multiple different ones allows people to be trained more quickly.

## The Spectrum

But data science did not just split in two or even three pieces. It expanded
into a full spectrum of roles. You could define the difference between these
roles along multiple axises, but I find just one works pretty well:
**Engineeriness** That is, how close the role is to a traditional software
engineering role?

On the "low engineeriness" side of the spectrum you have roles that work
almost entirely with data and domain-specific languages for data access and
processing. As you move towards the other end you start working with
"lower-level" languages and often less on the content on the data and more on
supportive tooling around it.

A specific job can fall anywhere on the spectrum, but the job title will give
you a rough idea of where. Here are five common job titles in a rough order
from least to most "engineery". Of course, in the real world, these jobs often
overlap heavily with their neighbors.

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

A _data scientist_[^ds] helps the company make better decisions like an
analyst, 

[^ds]: Also product data scientist, sometimes decision scientist.

Tools: Python, Jupyter notebooks, Pandas, R

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

### Machine Learning Engineer

Tools: Java, Docker, Kubernetes?, Airflow?, Cloud Stuff!

### Data Engineer

Tools: SQL Databases, MongoDB Spark, Kafka, Redshift, Airflow


---
[^pro]: At least in the sense that I was paid to do it... I don't claim to
        have been any good.

[^unicorn]: In the **Unicorn Era** companies tried to hire people who spanned
    the entire spectrum of data jobs from setting up the basic infrastructure,
    to building analyses on top of it, and shipping and owning models into
    production. This full skill set was incredibly rare (hence, "unicorn"),
    but since there weren't a ton of data science jobs and the field was still
    ill defined, it worked OK.

    But the demand for data scientists exploded and the tasks they were asked
    to perform became more and more demanding. It no longer made sense to try
    to find one person to do it all. For one, you just could not hire enough
    people who were "unicorns". Instead the role was split into multiple
    different positions so that the work that had before been owned by
    individuals with ill defined titles instead was distributed across an
    entire teams. Hence, the **Team Era**.
