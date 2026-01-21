---
layout: post
title: "Jupyter Notebook Templates for Data Science: Plotting Time Series"
description: >
  Jumpstart your time series visualizations with this Jupyter plotting notebook!
image: /files/jupyter-library/jupiter_in_the_rearview_mirror.jpg
image_alt: >
  The planet Jupiter as seen by the departing Juno spacecraft.
categories: 
  - data-visualization
  - data-science
  - jupyter
  - my-projects
---

{% capture file_dir %}/files/jupyter-library/{% endcapture %}

I often have data where each row describes an event. The data might describe
[a word that my son spoke for the first time][sons_language], or [a collision
that happened in California][collision], or [the finishing place of a rider in
the Tour de France][2020_tour]. A question I always want to answer with the
data is: _What does the distribution of these events look like in time?_

[sons_language]: {% post_url 2020-02-10-my_sons_language_development_comparison %}#development
[collision]: {% post_url 2019-02-20-switrs_bicycle_crashes_by_date %}#crashes-per-week
[2020_tour]: {% post_url 2020-10-16-2020_tour_de_france_plot %}#the-race-for-yellow

Plotting the data as a time series is the best way to answer this question,
but I never remember how to pivot the table, aggregate the events by type, and
resample to the right frequency. So I made the [**Time Series Plotting
Notebook**][plotting_nb] to remember for me.

[plotting_nb]: https://github.com/agude/Jupyter-Notebook-Template-Library/blob/master/notebooks/basic-time-series-plotting-template.ipynb

## The Time Series Plotting Notebook

Suppose we are looking at the number of automobile collisions by make using my
[curated SWITRS dataset][switrs_data]. We could extract one row for each
collision and the associated vehicle, which would look like this:

|  ID  |   datetime |  vehicle_make |
|:-----|-----------:|--------------:|
| 0    | 2020-01-01 |         Honda |
| 1    | 2020-02-01 |        Toyota |
| 2    | 2020-01-01 |         Other |
| ...  |        ... |           ... |

[switrs_data]: {% post_url 2020-11-24-switrs_sqlite_hosted_dataset %}

The [**time series plotting notebook**][plotting_nb] has two helpful functions
to visualize this data: `plot_time_series()` and `draw_left_legend()`.

### Plot Time Series

The first function, `plot_time_series()` is simple. It takes a dataframe
formatted like the above data and returns a plot showing the number of events
for each value in the categorical column. For example, to plot the number of
accidents per week by vehicle make, we would call:

```python
plot_time_series(
  df, 
  ax,
  date_col="datetime",
  category_col="vehicle_make",
  resample_frequency="W",  # Resample to 'W'eeks
)
```

Which would produce this plot:

[![A simple plot of the number of collisions by vehicle make in
California][first_plot]][first_plot]

[first_plot]: {{ file_dir }}/make_collision_in_time_first_version.svg

The function accepts a few optional parameters:

- `resample_frequency`: controls the timescale over which the data is
aggregated.

- `aggfunc` which controls how the data is aggregated.

- `linewidth` which can be used to make the lines larger if there are only a
few of them, or thinner if there is lots of data.

### Simple Legend

Simple legends are great. They convey their information effectively because
the superfluous noise has been removed. My [basic plotting
notebook][first_notebook] has a function to remove all the extra information
from the legend box leaving only the color and the label. This time I have
taken it a step further: I wrote a function to get rid of the box and label
each line.

[first_notebook]: {% post_url 2020-07-27-data_science_plotting_notebook_template %}#draw-legends

The function `draw_left_legend()` will draw labels on the end of each line,
like so:

[![A simple plot of the number of collisions by vehicle make in California
with left legend][second_plot]][second_plot]

[second_plot]: {{ file_dir }}/make_collision_in_time_second_version.svg

I've used this legend when [_Plotting the winners of the 2019 Tour de
France_][2019_tour] as well as the [_2020 Tour de France_][2020_tour].

[2019_tour]: {% post_url 2019-08-05-2019_tour_de_france_plot %}#the-race-for-yellow

## Putting It Together

The [time series plotting notebook][plotting_nb] enables you to quickly plot
your data in time with only a few lines of code. Here is the final version of
the plot:

[![An example plot from the notebook library][example]][example]

[example]: {{ file_dir }}/make_collision_in_time.svg

Which was produced by this short code snippet:

```python
import seaborn as sns

fig, ax = setup_plot(title="Collisions by Make")

pivot = plot_time_series(df, ax, date_col=DATE_COL, category_col="vehicle_make", resample_frequency="W")

# Move labels slightly to avoid overlap
nudges = {"Toyota": 15, "Honda": -8}
draw_left_legend(ax, nudges=nudges, fontsize=25)

sns.despine(trim=True)

save_plot(fig, "/tmp/make_collision_in_time.svg")
```

I hope the notebook template library is useful to you! Let me know on
[Twitter][twit] or [Github][github] if it is. Your feedback helps make the
project better for everyone!

[twit]: https://twitter.com/alex_gude/
[github]: https://github.com/agude/Jupyter-Notebook-Template-Library/issues
