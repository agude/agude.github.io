---
layout: post
title: "Data Science Salaries: Men Vs. Women"
description: >
  How do data scientists salaries for women compare to men? This month we
  explore pay by gender and location.
image: /files/data-science-salaries/josef_wagner_hohenberg_the_billing_coins.jpg
image_alt: > 
  A painting of coins on a table by Josef Wagner-Höhenberg.
categories: career-advice
---

{% capture file_dir %}/files/data-science-salaries/{% endcapture %}

{% include lead_image.html %}

The [gender pay gap][pay_gap] is a contentious issue, especially in tech where
[women are historical excluded][women_in_tech]. I have some data to look at
the pay gap in Data Science, using the same [Insight][insight] alumni survey I
used [last time][last_time].

[pay_gap]: https://en.wikipedia.org/wiki/Gender_pay_gap
[women_in_tech]: https://qz.com/work/1287881/how-technology-companies-alienate-women-during-recruitment/
[insight]: https://www.insightdatascience.com
[last_time]: {% post_url 2019-03-26-data_science_salaries %} 

This data has some biases, in that it is collected from Insight
alumni who are, mostly:

- PhDs
- Early career
- In high-demand markets
- Coached on salary negotiation

Additionally, gender was not on the original survey and only added later, so
around a third of the data does not have that information. With those
limitations noted, I'll move on.

The data is available [here][data]. The notebook with all the code is
[here][notebook] ([rendered on Github][rendered]).

{% capture notebook_uri %}{{ "Data Science Salary Data Gender.ipynb" | uri_escape }}{% endcapture %}

[data]: {{ file_dir }}/insight_salary_survey_cleaned.csv
[notebook]: {{ file_dir }}/{{ notebook_uri }}
[rendered]: https://github.com/agude/agude.github.io/blob/master{{ file_dir }}/{{ notebook_uri }}

## Gendered Pay

Here are all the data scientists in the dataset, divided by gender. I have
removed all the non-data scientists (like the [MLEs I looked at last
time][last_time_mle] because I have very few responses from them. I have also
removed the one data scientist who marked themselves as "transgender" without
indicating their gender identity further.

[last_time_mle]: {% post_url 2019-03-26-data_science_salaries %}#scientists-engineers-and-analysts

So, how is pay equality in data science?

[![A swarm plot showing salaries for male and female data scientists.][gender_plot]][gender_plot]

[gender_plot]: {{ file_dir }}/data_science_total_comp_gender.svg

Pretty equal, actually! The median woman in the sample earns more then the
median man, but of course the number of samples is really small.

| Gender  |  Median Total Compensation|
|:--------|--------------------------:|
| Female  |                     $149k |
| Male    |                     $139k |

At this point I will note a further bias in the data: there are far fewer
women than men, even though Insight generally has pretty balanced cohorts. It
is possible that non-response is not random and instead is correlated to the
underlying distribution, for example, perhaps people who are paid less refuse
to report.

There are lots of things I would like to explore---like if women and men see
the same [effects from seniority that I observed last
time][last_time_senior]---but I just do not have enough women in the sample to
say anything conclusive.

[last_time_senior]: {% post_url 2019-03-26-data_science_salaries %}#experience-counts-a-lot

## By Region

[![A swarm plot showing salaries for male and female data scientists in California and the East Coast.][gender_plot_region]][gender_plot]

[gender_plot_region]: {{ file_dir }}/data_science_total_comp_gender_and_location.svg
