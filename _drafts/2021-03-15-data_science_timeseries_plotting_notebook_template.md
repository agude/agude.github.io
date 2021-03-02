---
layout: post
title: "Jupyter Notebook Templates for Data Science: Plotting Time Series"
description: >
  Jumpstart your timeseries visualizations with this Jupyter plotting notebook!
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

I often have data where each row describes an event that happened at some
time. Each row might be [a word that my son spoke for the first
time][sons_language], or [a collision that happened in California][collision],
or [the finishing place of a rider in the Tour de France][tour]. Common
questions to ask are:

[sons_language]: {% post_url 2020-02-10-my_sons_language_development_comparison %}
[collision]: {% post_url 2019-02-20-switrs_bicycle_crashes_by_date %}
[tour]: {% post_url 2020-10-16-2020_tour_de_france_plot %}

> What does the distribution of these events look like in time? Are there more
> of Type A events, or Type B?

Plotting the data as a time series is the way to answer these questions,
but I never remember how to pivot the table, aggregate the events by type, and
resample to the right frequency. So I made the [**Time Series Plotting
Notebook**][plotting_nb] to remember for me.

[plotting_nb]: TODO

## The Time Series Plotting Notebook

Suppose we are interested in the looking at the number of automobile
collisions by make using my [curated SWITRS dataset][switrs_data]. We could
extract one row for each collision and the associated vehicle, which would
look like this:

|  ID  |   datetime |  vehicle_make |
|:-----|-----------:|--------------:|
| 0    | 2020-01-01 |         Honda |
| 1    | 2020-02-01 |        Toyota |
| 2    | 2020-01-01 |         Other |
| ...  |        ... |           ... |

[switrs_data]: {% post_url 2020-11-24-switrs_sqlite_hosted_dataset %}

My [**time series plotting notebook**][plotting_nb] has two helpful functions
to visualize this data.

### Draw Bands

The first function, `plot_time_series()` is simple. It takes a dataframe
formatted like the above data and returns a plot showing the number of events
broken out by value in the categorical column. For example, to plot the number
of accidents per week by vehicle make, we would call:

```python
plot_time_series(
  df, ax,
  date_col="datetime",
  category_col="vehicle_make",
  resample_frequency="W",
)
```

Which would produce this plot:

[![A simple plot of the number of collisions by vehicle make in
California][first_plot]][first_plot]

[first_plot]: {{ file_dir }}/make_collision_in_time_first_version.svg

The function has as few optional parameters:

- `resample_frequency` which controls the timescale over which the data is
aggregated.
- `aggfunc` which controls how the data is aggregated.
- `linewidth` which can be used to make the lines larger if there are only a
few of them, or thinner if there is lots of data.

### Simple Legend

I like simple legends. My [basic plotting notebook][first_notebook] has a
function to remove all the extra information from the legend box leaving only
the color and the label. This time I have taken it a step further: I wrote a
function to get rid of the box and label each line.

[first_notebook]: {% post_url 2020-07-27-data_science_plotting_notebook_template %}#draw-legends

The function `draw_left_legend()` will draw labels on the end of each line,
like so:

[![A simple plot of the number of collisions by vehicle make in California
with left legend][second_plot]][second_plot]

[second_plot]: {{ file_dir }}/make_collision_in_time_second_version.svg


I like minimal, but informative, legends. Color alone is often enough to
differentiate lines or points, so I wrote a function to change the color of
the legend text to match the line, called `draw_colored_legend()`. It produces
a legend like on this plot:

[![A plot showing my colored legend.][legend_plot]][legend_plot]

[legend_plot]: {{ file_dir }}/legend.svg

This legend style can be seen in these posts:

- [**Plotting my son's language development**][son_post] to label each language.
- [**Plotting Tour de France Prize Money**][tdf_post] to label the winner's prize compared to the total.
- [**Comparing Data Science Salaries by Gender**][salary_post] to differentiate the points for men and women.

[son_post]: {% post_url 2020-01-30-my_second_sons_words %}#the-words
[tdf_post]: {% post_url 2019-11-25-tdf_prize_money_plot_improvements %}#improvements
[salary_post]: {% post_url 2019-05-09-data_science_salaries_by_gender %}#by-region

## Putting It Together

The [plotting notebook][plotting_nb] enables you to make beautiful plots
quickly and easily. For example, this plot:

[![An example plot from the notebook library][example]][example]

[example]: {{ file_dir }}/example_plot.svg

Was produced by this short code snippet:

```python
fig, ax = setup_plot(
    title="Title",
    xlabel="X-axis",
    ylabel="Y-axis",
)

ax.scatter(np.random.rand(500)-0.65, np.random.rand(500), label="First dataset")
ax.scatter(np.random.rand(500)-0.35, np.random.rand(500), label="Second dataset")

draw_colored_legend(ax)

draw_bands(ax)

save_plot(fig, "/tmp/output.svg")
```

If the notebook template library is useful to you, be sure to let me know on
[Twitter][twit] or [Github][github]. Your feedback helps make the project
better for everyone!

[twit]: https://twitter.com/alex_gude/
[github]: https://github.com/agude/Jupyter-Notebook-Template-Library/issues
