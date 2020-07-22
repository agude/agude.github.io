---
layout: post
title: "Jupyter Notebook Templates for Data Science: Plotting"
description: >
  Jupyter notebooks are great for data exploration; jumpstart your
  visualizations with this plotting notebook!
image: /files/jupyter-library/jupiter_red_spot_juno.jpg
image_alt: >
  A photo of the Library of Congress in 1902.
categories: 
  - jupyter
  - my_projects
---

{% capture file_dir %}/files/jupyter-library/{% endcapture %}

{% include lead_image.html %}

I recently released my [Jupyter Notebook Template Library][library], in part
to help myself so I do not have to spend hours poking through my old notebooks
to find handy code snippets. In this post I dive into the plotting notebook to
show you what it can do.

[library]: https://github.com/agude/Jupyter-Notebook-Template-Library

[nb_post]: {% post_url 2016-10-17-jupyter_not_for_development %}

## The Plotting Notebook

Visualizing your data is a critical step in understanding your data, and so it
is appropriate that the first notebook in the library helps with making
beautiful plots.

The notebook begins with a bunch of boilerplate to set some metadata that is
saved to the files and change some defaults like the figure size and
resolution, font size, and legend frame. After that there are a few helpful
functions which I will discuss in more detail.

### Draw Bands

One of my favorite functions is the `draw_bands()` function. It draws a set of
colored bands on the background of the plot based on the axis tick locations.

When called with just the axis, like `draw_bands(ax)`, it produces this:

[![A plot showing the default grey bands.][bands_plot]][bands_plot]

[bands_plot]: {{ file_dir }}/bands.svg

But you can also customize the color using `draw_bands(ax, color="orange",
alpha=0.05)`, which produces:

[![A plot showing the orange bands.][orange_bands_plot]][orange_bands_plot]

[orange_bands_plot]: {{ file_dir }}/orange_bands.svg

These bands help guide the eye to where the ticks are, which is especially
useful when your x-axis is time. I use these bands when:

- [**Discussing my sons' language development**][language_post] to highlight each month.
- [**Plotting the progression of the cycling hour record**][hour_post] to show each decade.  
- [**Exploring when cyclists are involved in traffic accidents**][bike_post] to highlight the seasonality.

[language_post]: {% post_url 2020-02-10-my_sons_language_development_comparison %}
[hour_post]: {% post_url 2019-07-09-hour_record_plot_improvements %}
[bike_post]: {% post_url 2019-02-20-switrs_bicycle_crashes_by_date %}

### Draw Legends

I like minimal legends. Often just color is enough for simple plots, so I
wrote a function to change the color of the legend text to match the line,
called `draw_colored_legend()`. It produces a legend like on this plot:

[![A plot showing my colored legend.][legend_plot]][legend_plot]

[legend_plot]: {{ file_dir }}/legend.svg

This function is a little [brittle][brittle]; it works well for scatter plots,
but fails for some other matplotlib objects. I plan to make it more robust in
the future.

[brittle]: https://en.wikipedia.org/wiki/Software_brittleness

I have used these types of legends when:

- [**Plotting my son's language development**][son_post] to label each language.
- [**Plotting Tour de France Prize Money**][tdf_post] to label the winner's prize compared to the total.
- [**Comparing Data Science Salaries by Gender**][salary_post] to differentiate the points for men and women.

[son_post]: {% post_url 2020-01-30-my_second_sons_words %}
[tdf_post]: {% post_url 2019-11-25-tdf_prize_money_plot_improvements %}
[salary_post]: {% post_url 2019-05-09-data_science_salaries_by_gender %}

## Putting It Together

This notebook allows you to make a plot like this:

[![An example plot from the notebook library][example]][example]

[example]: {{ file_dir }}/example_plot.svg

With only this code:

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

If the notebook template is useful, be sure to let me know on [Twitter][twit]
or [Github][github]. Your feedback helps make the project better for everyone!

[twit]: https://twitter.com/alex_gude/
[github]: https://github.com/agude/Jupyter-Notebook-Template-Library/issues
