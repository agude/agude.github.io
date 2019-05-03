---
layout: post
title: "The Gender Pay Gap in Data Science Salaries"
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
[women are historical excluded][women_in_tech]. We can explore the gap in Data
Science salaries a little with the same [Insight data][insight] I used [last
time to look at Data Science salaries in general][last_time].

[pay_gap]: https://en.wikipedia.org/wiki/Gender_pay_gap
[women_in_tech]: https://qz.com/work/1287881/how-technology-companies-alienate-women-during-recruitment/
[insight]: https://www.insightdatascience.com
[last_time]: {% post_url 2019-03-26-data_science_salaries %} 

Others have looked into the same question before: [Florian
Lindstaedt][florian] used a much larger (but less clean) dataset from Kaggle
to [look at the issue on his blog][kaggle_survey]. He found that for data
scientists younger than 30, women earned slightly more, but in the 30-35 age
group men earned more.

[florian]: https://flolytic.com/
[kaggle_survey]: https://flolytic.com/blog/gender-pay-gap-among-data-scientists-on-kaggle

Our data is much smaller, but better curated. However, it has some biases in
that it is collected from Insight alumni who are mostly:

- PhDs
- Early career
- In high-demand markets
- Coached on salary negotiation

Asking the respondant's gender was added to the survey late, so around a third
of the data does not have that information. This leaves us 79 men and 28
women. Not a huge sample, but better than nothing.

Of course, this low number of woman might itself be a further bias: Insight
generally has pretty gender-balanced cohorts, so that fact the many fewer
women have filled out the survey is worrying. It is possible that non-response
is correlated to the underlying distribution, for example, perhaps people who
are paid less refuse to report.

The data used in this post is available [here][data]. The notebook with all
the code is [here][notebook] ([rendered on Github][rendered]).

{% capture notebook_uri %}{{ "Data Science Salary Data Gender.ipynb" | uri_escape }}{% endcapture %}

[data]: {{ file_dir }}/insight_salary_survey_cleaned.csv
[notebook]: {{ file_dir }}/{{ notebook_uri }}
[rendered]: https://github.com/agude/agude.github.io/blob/master{{ file_dir }}/{{ notebook_uri }}

## Pay: Men Vs. Women

Here is total recurring compensation[^1] by gender. I have removed all
the non-data scientists (like the [MLEs I looked at last time][last_time_mle])
because I have very few responses from them. I have also removed the one data
scientist who responded "transgender" without indicating their gender identity
further.

[last_time_mle]: {% post_url 2019-03-26-data_science_salaries %}#scientists-engineers-and-analysts

So, how is pay equality in data science?

[![A swarm plot showing salaries for male and female data
scientists.][gender_plot]][gender_plot]

[gender_plot]: {{ file_dir }}/data_science_total_comp_gender.svg

Pretty equal, actually! The median woman in the sample earns more then the
median man, but of course the number of samples is really small.

| Gender  |  Median Total Compensation|
|:--------|--------------------------:|
| Female  |                     $149k |
| Male    |                     $139k |

There are lots of things I would like to explore---like "do women benefit from
seniority the same as men?", like [I observed last
time][last_time_senior]---but I just do not have enough women in the sample to
say anything conclusive.

[last_time_senior]: {% post_url 2019-03-26-data_science_salaries %}#experience-counts-a-lot

Instead I will look at salaries by region (which I know drives large pay
differences) and age, which [Florian looked at][kaggle_survey].

## By Region

Only California (LA, San Francisco, and Silicon Valley) and the Northeast
(New York, Boston, and DC) have enough respondants to form any reasonable
conclusions, so I limit my sample to those regions.

[![A swarm plot showing salaries for male and female data scientists in
California and the East Coast.][gender_plot_region]][gender_plot_region]

[gender_plot_region]: {{ file_dir }}/data_science_total_comp_gender_and_location.svg

Again, these look pretty equal, with the median woman earning more than the
median man in both regions.

{% comment %}Raw HTML is needed to have entries span columns or rows.{% endcomment %}
<table>
  <thead>
    <tr> <th>Region</th> <th>Gender</th> <th style="text-align: right">Median Total Compensation</th> </tr>
  </thead>
  <tbody>
    <tr> <td rowspan="2">California</td>  <td>Female</td>  <td style="text-align: right">$168k</td> </tr>
    <tr>                                  <td>Male</td>    <td style="text-align: right">$162k</td> </tr>
    <tr> <td rowspan="2">Northeast</td>   <td>Female</td>  <td style="text-align: right">$145k</td> </tr>
    <tr>                                  <td>Male</td>    <td style="text-align: right">$136k</td> </tr>
  </tbody>
</table>

## By Age

Finally, I can check what Florian found: that women under 30 out earned the
same age men, but men out earned women in the 30--35 age range. I use the same
selection as above, but now partitioning by age instead of region.

[![A swarm plot showing salaries for male and female data scientists in
California and the East Coast by age][gender_plot_age]][gender_plot_age]

[gender_plot_age]: {{ file_dir }}/data_science_total_comp_gender_and_age.svg

I do not see the same trend as Florian. In my data, women out earn men at
every age level.

<table>
  <thead>
    <tr><th>Age</th> <th>Gender</th> <th style="text-align: right">Median Total Compensation</th></tr>
  </thead>
  <tbody>
    <tr> <td rowspan="2">0 to 30</td>  <td>Female</td>  <td style="text-align: right">$155k</td> </tr>
    <tr>                               <td>Male</td>    <td style="text-align: right">$140k</td> </tr>
    <tr> <td rowspan="2">31–35</td>    <td>Female</td>  <td style="text-align: right">$164k</td> </tr>
    <tr>                               <td>Male</td>    <td style="text-align: right">$148k</td> </tr>
    <tr> <td rowspan="2">36+</td>      <td>Female</td>  <td style="text-align: right">$180k</td> </tr>
    <tr>                               <td>Male</td>    <td style="text-align: right">$138k</td> </tr>
  </tbody>
</table>

---
[^1]: Salary, yearly bonus, and yearly stock grant. Signing bonus is not included.
