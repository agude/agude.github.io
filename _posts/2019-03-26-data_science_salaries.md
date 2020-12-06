---
layout: post
title: "Data Science Salaries"
description: >
  How do data scientists salaries vary by experience and location? Read on to
  find out!
image: /files/data-science-salaries/josef_wagner_hohenberg_the_billing_coins.jpg
show_lead_image: True
image_alt: > 
  A painting of coins on a table by Josef Wagner-Höhenberg.
categories: 
  - career-advice
  - data-science
---

{% capture file_dir %}/files/data-science-salaries/{% endcapture %}

One of the most important things to know when looking for a job is your market
value. For data science positions, what better way to determine that than with
data![^1] Some sites&#8288;---&#8288;like [Indeed][indeed] and
[Glassdoor][glassdoor]&#8288;---&#8288;offer aggregate salary information, but
they won't give you all their data. That's why I prefer the survey that
[Insight][insight] alumni put together. With the full dataset I can slice it
however I want.

[indeed]: https://www.indeed.com/salaries/Data-Scientist-Salaries,-Mountain-View-CA
[glassdoor]: https://www.glassdoor.com/Salaries/san-jose-data-scientist-salary-SRCH_IL.0,8_IM761_KO9,23.htm
[insight]: https://www.insightdatascience.com

The data is available [here][data]. The notebook with all the code is
[here][notebook] ([rendered on Github][rendered]).

{% capture notebook_uri %}{{ "Data Science Salary Data.ipynb" | uri_escape }}{% endcapture %}

[data]: {{ file_dir }}/insight_salary_survey_cleaned.csv
[notebook]: {{ file_dir }}/{{ notebook_uri }}
[rendered]: https://github.com/agude/agude.github.io/blob/master{{ file_dir }}/{{ notebook_uri }}

## Scientists, Engineers, and Analysts

The dataset is mostly comprised of data scientists, but there are a few
engineers and analysts as well, so we can compare salary across job titles:

[![Box plot showing that machine learning engineers earn the most, followed by
data scientists.][vs_plot]][vs_plot]

[vs_plot]: {{ file_dir }}/data_science_total_comp_vs_others.svg

Machine learning engineers have the highest median salary, followed by data
scientists, data engineers, and data analysts. Data science salaries span a
greater range, although this is likely due to the larger number in the sample
(N=132 vs N=8). The median values are:

| Title                     |  Median Total Compensation |
|:--------------------------|---------------------------:|
| Machine Learning Engineer |                      $161k |
| Data Scientist            |                      $145k |
| Data Engineer             |                      $128k |
| Analyst                   |                      $105k |

## Location, Location, Location

The market rate for a data scientist varies wildly by location:

[![Box plot showing that the West Coast has the highest total compensation,
followed by New York City.][region_plot]][region_plot]

[region_plot]: {{ file_dir }}/data_science_total_comp_by_region.svg

Compensation in California is the highest, by far. Technology companies often
give employees stock in addition to their base pay and many of these companies
are based in California. Do those stock grants account for most of the
compensation difference between California and the rest of the nation? Let's
remove stock and look again:

[![Box plot showing that the West Coast has the highest total compensation,
followed by New York City.][region_salary_plot]][region_salary_plot]

[region_salary_plot]: {{ file_dir }}/data_science_salary_by_region.svg

The median compensation in California drops $20k when removing stock, the
median in the Northwest (another major tech hub) drops $5k, and the Northeast
and Midwest don't change. The highest paid individuals in California all drop
drastically with the new highest paid person in New York!

## Experience Counts (A Lot!)

Finally, how much does experience matter? Looking at just California this
time, because I have the most data for salaries there:

[![Box plot showing each year of experience increases a data scientist's total
compensation tremendously.][exp_plot]][exp_plot]

[exp_plot]: {{ file_dir }}/data_science_total_comp_by_experience.svg

A lot! Going from one to three years of experience increases the median
compensation by $100k!

But what is happening to people with four years of experience? There are very
few in the survey (N=4), so the median can be pulled by any particular
outlier. For example, if one of them got a job in 2012 and stayed there for
four years, they would miss out on the large raises that come from jumping to
a new company. Additionally, one of the data scientists who said they had four
years experience also said they were in a "Junior" position, so it's possible
they counted their school work when answering whereas most would not count
school.

I have found it is much easier to get a large raise when starting a new
position, so this plot argues for the importance of not staying at your first
job too long!

## Now You Know (But Knowing Is Only Half the Battle)

Now you have a better idea what the data science job market looks like, but
that isn't enough. To get what you're worth, you have to negotiate as well. I
highly recommend reading [Patrick McKenzie's][pat] [_**Salary Negotiation:
Make More Money, Be More Valued**_][negotiate] post. Negotiating has earned me
between 5% and 10% increases to my offers, which as you can see from the
numbers in this post, are substantial!

[pat]: https://twitter.com/patio11
[negotiate]: https://www.kalzumeus.com/2012/01/23/salary-negotiation/

---
[^1]: Companies pay good money to get salary data so they know exactly what a good (and bad) offer looks like. You should have the same information.
