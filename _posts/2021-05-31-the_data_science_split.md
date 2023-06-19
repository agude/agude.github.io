---
layout: post
title: "The Data Science Split: <br>From Unicorns to Teams"
description: >
  When data science started the job covered everything from setting up
  databases to running experiments to making models. But finding Unicorns was
  impossible; something had to give.
image: /files/data-science-spectrum/eugene_f_kranz_1965.jpg
image_alt: >
  Gene Kranz sits at a console in the NASA Mission Operations Control Room.
  He is wearing a single ear headset and flipping a pencil back and forth.
categories:
  - career-advice
  - data-science
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

[phd]: {% post_url 2018-01-19-should_i_get_a_phd %}#but-there-are-no-jobs
[insight]: {% post_url 2018-08-21-should_i_go_to_insight %}

## The Split

At Insight I ran into lots of different types of data scientists. Some were
really, really good at statistics; others lived for experiment design and
power analysis; some---like me---loved writing clean, performant code and
playing around with deep learning. Yet at the end of the program we mostly
interviewed for jobs that were no more specific than "data scientist". The
companies were looking for someone to set up their data teams and extract
value from their data.

This was the tail end of the unicorn era. Data engineering had already become
it's own specialty, but everything else was still under the umbrella term data
scientist. Even as a neophyte I could see further splits coming.

### Unicorn Era

The **Unicorn Era** was the time when data science was first being
established. Companies had heard that "data was the new oil" and were
desperate to hire someone to refine it for them. They looked to hire a person
who could span the entire spectrum of data jobs, from setting up the
infrastructure, to building analyses on top of it, to shipping and owning
models in production. But people who could master all of these skills were not
just rare, they were mythical. Hence, unicorns.

It worked OK for awhile. There were few data science jobs so companies needed
to find only a scant handful of unicorns. Still it couldn't last. Demand for
data scientists exploded and the tasks they were asked to perform became more
and more demanding and more and more specialized. It no longer made sense to
try to find a single person to do it all, for many reasons.

First, finding unicorns had always been nearly impossible. Every data
scientist is an expert in some part of the field, but almost no one is great
at everything **and** interested in all of it. Splitting the role allowed
people to focus on the areas that they were most passionate about.

Second, training a data scientist---waiting for them to finish a PhD in some
_other_ subject first while hoping the required data skills would rub off on
them in the process---took **too long**. An undergraduate degree was the
obvious solution and every college quickly spun up a data science
undergraduate program. But how could you impart the ten years of knowledge
gathered in the lead up to a PhD in just four? You can't--- unless you split
it across three different people.

### The Team Era

The data science role slowly split into multiple positions. Work that had
before been owned by individuals with ill defined titles instead was
distributed across an entire teams. Hence, the **Team Era**.

But it didn't split into just one or two new roles, it split into a whole
spectrum. The roles cover everything from setting up the underlying
infrastructure, to improving specialized tooling, to building models, to
reporting out the results. I discuss five of these roles in my next post:

<div class="card-grid">
{% assign post = site.posts | where:"title", "The Data Science Spectrum: <br>From Analyst to Machine Learning" | first %}
{% include article_card.html
  url=post.url
  image=post.image
  image_alt=post.image_alt
  title=post.title
  description=post.description
%}
</div>
