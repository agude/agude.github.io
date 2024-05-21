---
layout: resume
sidebar_include: true
title: "Resume"
description: >
  Alexander Gude's Resume. Alex is a Machine Learning engineer.
---

# Alexander Gude

<div class="subtitle">Staff Machine Learning Engineer</div>

## Statement

A highly accomplished machine learning engineer with {{ "now" | date: "%Y" |
minus: 2015 }} years of experience driving innovation in fraud detection,
anti-money laundering, and financial modeling at leading technology companies
like Cash App and Intuit. Demonstrated success in spearheading high-impact
initiatives, such as enabling instant bank account opening at Cash App that
increased paycheck deposits by 90%, as well as developing cutting-edge fraud
monitoring systems that reduced fraud volumes by 12x in 18 months. A strategic
leader adept at building and managing high-performing data science teams,
implementing engineering best practices, and deploying machine learning models
that delivered tangible business value.

## Experience

{% include resume_experience.html
  company="Cash App"
  location="Remote"
  position="Senior Staff (L7) Machine Learning Engineer, Modeler"
  dates="2023--Present"
  position_2="Staff (L6) Machine Learning Engineer, Modeler"
  dates_2="2020--2023"
%}

- Estimated the impact of instant bank account opening (as opposed to delayed
  until card shipment) to customer paycheck deposit attach rates. Took the
  lead in pre-emptively building anti-fraud checkpoints for the process and
  worked with legal, compliance, and business operations to get the program
  green-lit by our external banking partners. Instant bank accounts delivered
  a 90% increase in paycheck deposits by our customers and a 55% increase in
  dollar inflows from paychecks.
- Developed high-recall metrics for monitoring fraud across all ACH transfers
  giving high visibility into developing problem areas. Built automated alerts
  based on these metrics so bad activity did not slip through any gaps.
- Using the fraud metrics, targeted high precision rules and machine learning
  models to curtail the worst fraud. Lowered fraud volumes by 12x in 18
  months.
- Monitored the fraud metrics for tax returns deposited to customer accounts.
  Briefed the IRS and state tax administrators on Cash App Tax's anti-fraud
  program, including my monitoring, alerting, models, and rules. My work gave
  them enough confidence to not redirect tax refund deposits from our
  customer's bank accounts, which were 18% of all inflows in 2022.
- Deployed first ACH categorization model for Cash App Banking, reducing
  uncategorized transactions by 50% and increasing tracked payroll deposit
  volume by 30%. The improved income categorization has allowed us to make
  more profitable loans by sizing loan offers to expected ability to repay.

{% include resume_experience.html
  company="Intuit"
  location="Mountain View, CA"
  position="Staff Data Scientist"
  dates="2017--2020"
  position_2="Senior Data Science Manager"
  dates_2="2018--2019"
%}

- Led 8 data scientists in building machine learning models to detect and stop
  fraud.
- Drove adoption of engineering best practices by the team, including
  implementation of peer review for code changes and automated correctness
  checking, building of CI/CD pipelines for code and model deployment, and
  added metrics around test coverage and code health, reducing number of P0
  production bugs from 2 in the first year to 0.
- Deployed the first in-product, real-time account takeover prevention model
  at Intuit---launched in production in TurboTax and alerted security to a
  possible breach within the first week of running. Back-testing showed it
  would have detected 95% of last year's stolen tax return downloads.
- Drove migration of machine learning models from Intuit's on-prem data center
  to AWS platform without interruption of services, saving $1.5M per year in
  operation costs.
- Improved the TurboTax Online account takeover model leading to a 90%
  reduction in wrongly challenged users, stopping 10X as many fraudsters, and
  shortening feature processing time from 2 hours to under a second.

{% include resume_experience.html
  company="Lab41, an In-Q-Tel Lab"
  location="Menlo Park, CA"
  position="Data Scientist"
  dates="2015--2017"
%}

- Led a team of 3 engineers in investigating the latest computer vision
  techniques for vehicle re-identification using deep learning and develop a
  system within 6 months that enabled clients to automatically detect the same
  vehicle across multiple videos from security cameras. Handed over the new
  system to customer's internal development team and provided training.
- Worked as part of a team of 3 scientists to develop an embedding technique
  to train a convolutional neural network on unlabeled, open-source image
  data. Built a system using TensorFlow that learned to embed images and text
  into a joint vector space, allowing customers to perform content-based image
  retrieval on a corpus of 100M untagged images.
- Designed and implemented a recommender system evaluation framework in Python
  and Spark and leveraged it to develop a Python-snippet recommender using
  word embeddings.

## Skills

{% capture latex %}
{% endcapture %}

{% include resume_skills.html
languages='Python, Scala, SQL, shell script, C++, <span class="latex">L<sup>a</sup>T<sub>e</sub>X</span>'
  tools="Sagemaker, NumPy, SciPy, Matplotlib, Tensorflow, Pandas, Spark, git, Linux, vim"
%}

## Education

{% include resume_experience.html
  company="University of Minnesota"
  location="Minneapolis, MN"
  position="PhD, High Energy Particle Physics"
  dates="2009--2015"
%}

{% include resume_experience.html
  company="University of California, Berkeley"
  location="Berkeley, CA"
  position="BA, Physics (Honors), College of Letters and Sciences"
  dates="2004--2008"
%}
