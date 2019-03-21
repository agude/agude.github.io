---
layout: post
title: "Data Science Salaries"
description: >
image: /files/data-science-salaries/
image_alt: >
categories: career-advice
---

{% capture file_dir %}/files/data-science-salaries/{% endcapture %}

{% include lead_image.html %}

One of the most important things to know when looking for a job is your market
value. What better way to determine that than with data![^1] Some
sites&#8288;---&#8288;like [Indeed][indeed] and
[Glassdoor][glassdoor]&#8288;---&#8288;offer aggregate salary data, but give
you only a limited look at the data. That's why I prefer survey that [Insight
Data Science][] alumni put together. With the full data I can slice it however
I want.

[indeed]: https://www.indeed.com/salaries/Data-Scientist-Salaries,-Mountain-View-CA
[glassdoor]: https://www.glassdoor.com/Salaries/san-jose-data-scientist-salary-SRCH_IL.0,8_IM761_KO9,23.htm
[rsu]: https://en.wikipedia.org/wiki/Restricted_stock

The data is available [here][data]. The notebook with all the code is
[here][notebook] ([rendered on Github][rendered]).

{% capture notebook_uri %}{{ "Data Science Salary Data.ipynb" | uri_escape }}{% endcapture %}

[data]: TODO
[notebook]: {{ file_dir }}/{{ notebook_uri }}
[rendered]: https://github.com/agude/agude.github.io/blob/master{{ file_dir }}/{{ notebook_uri }}

## Scientists, Engineers, and Analysts

The dataset is mostly comprised of data scientists, but there are a few
engineers and analysts as well, so we can compare salary across multiple job
titles:

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

The market rate for a data scientist varies wildly by location. Since 

[![Box plot showing that the West Coast has the highest total compensation,
followed by New York City.][region_plot]][region_plot]

[region_plot]: {{ file_dir }}/data_science_total_comp_by_region.svg

Is the main driver stock? Let remove stock grants and look again:

[![Box plot showing that the West Coast has the highest total compensation,
followed by New York City.][region_salary_plot]][region_salary_plot]

[region_salary_plot]: {{ file_dir }}/data_science_salary_by_region.svg

The median for California drops $20k when removing stock, the median for the
Northwest drops $5k, and the Northeast and Midwest don't change. The
highest paid individuals in California all drop drastically, and the new highest paid person if in New York!

Stock grants do to drive most of the difference between California data
scientists and data scientists elsewhere.

## Experience Counts (A Lot!)

Finally, how much does experience matter? Looking at just California this
time:

[![Box plot showing each year of experience increases a data scientist's total
compensation tremendously.][exp_plot]][exp_plot]

[exp_plot]: {{ file_dir }}/data_science_total_comp_by_experience.svg

A lot! Going from one to three years of experience increases the median
compensation by $100k!

But what is happening to people with four years of experience? There are very
few in the survey (N=4), so the median can be pulled by any particular
outlier. For example, someone who got a job in 2012 (when Insight started) and
stayed there for four years. One of the data scientists is in a "Junior"
position, so it's possible they counted their school work when most do not.

I have found it is much easier to get a raise this large when starting a new
position, so this plot argues the importance of not staying at your first job
too long!

## Now You Know (But Knowing Is Only Half)

So now you have a better idea what the job market looks like, but that isn't
enough. To get what you are worth, you are going to negotiate. I highly
recommend reading [Patrick McKenzie's][pat] [_**Salary Negotiation: Make More
Money, Be More Valued**_][negotiate] post. Negotiating has earned me between 5%
and 10% increases to my offers with little work, which as you can see from the
numbers in this post, can be substantial!

[pat]: https://twitter.com/patio11
[negotiate]: https://www.kalzumeus.com/2012/01/23/salary-negotiation/

---
[^1]: Companies pay good money to get salary data so they know exactly what a good (and bad) offer looks like. You should have the same information.
