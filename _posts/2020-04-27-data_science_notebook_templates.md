---
layout: post
title: "Jupyter Notebook Templates for Data Science"
description: >
  Jupyter notebooks are great for data exploration; jumpstart your work with
  this library of useful notebook templates!
image: /files/jupyter-library/jupiter_cassini_20001229.jpg
image_alt: >
  A photo of the Library of Congress in 1902.
categories:
  - data-science
  - jupyter
  - my-projects
---

{% capture file_dir %}/files/jupyter-library/{% endcapture %}

I love Jupyter notebooks (even if [I have strong opinions about their
misuse][nb_post]) and so I use them constantly, both at work and here in my
articles. They are the best way to explore a dataset and make visualizations.

But my workflow with notebooks is not very efficient; it is made up of the
following steps:

[nb_post]: {% post_url 2016-10-17-jupyter_not_for_development %}

1. Start a brand new, _completely empty_ notebook.

2. Load the data and start cleaning it.

3. Begin making plots.

4. Realize I already have some code from a different project to make nice plots.

5. Dig through my repositories looking for the code.

6. Copy and paste the first code I find that sort of does what I need (and
   which probably is not the most recent or nicest version).

7. Hack the code up and make it even uglier.

After five years, I am ready for something better. And so I present the [**Jupyter
Notebook Template Library**][library], which has revolutionized my workflow and which
I gladly share with you as well, gentle reader.

## Jupyter Notebook Template Library

The [Jupyter Notebook Template Library][library] is a repository of notebook
templates, each targeted at a different use case. The templates let me get
right to working with the data as quickly as possible. And the library
guarantees that my notebook will always have the latest and greatest helper
functions without having to dig through my old work.

[library]: https://github.com/agude/Jupyter-Notebook-Template-Library

### The Plotting Template

The first notebook in the library is the [**Plotting Template**][plotting].
Its goal is to change the above workflow to this:

1. Download the right template.

2. Load data and start cleaning it.

3. Make **beautiful** plots.

[plotting]: https://github.com/agude/Jupyter-Notebook-Template-Library/blob/8c13dc10c4dbcf724357857692ab7ac64fb83e09/notebooks/basic-plotting-template.ipynb

It lets me write this:

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

And get this, complete with curated font sizes, a patented striped background,
and a focused legend:

[![An example plot from the notebook library][example]][example]

[example]: {{ file_dir }}/example_plot.svg

You can read more about the plotting notebook in detail here:

<!-- A grid of hand-selected related posts. -->
{% capture plotting_url %}{% post_url 2020-07-27-data_science_plotting_notebook_template %}{% endcapture %}
<div class="card-grid">
  {% article_card_lookup url=plotting_url %}
</div>

### The Time Series Plotting Template

The [**second notebook in the library**][plotting_nb_ts] helps you take a
dataframe of events and turn it into a time series plot with each item broken
out into its own line.

[plotting_nb_ts]: https://github.com/agude/Jupyter-Notebook-Template-Library/blob/master/notebooks/basic-time-series-plotting-template.ipynb

You just write:

```python
import seaborn as sns

fig, ax = setup_plot(title="Collisions by Make")

pivot = plot_time_series(df, ax, date_col=DATE_COL, category_col="vehicle_make", resample_frequency="W")

# Move labels slightly to avoid overlap
nudges = {"Toyota": 15, "Honda": -8}
draw_left_legend(ax, nudges=nudges, fontsize=25)

sns.despine(trim=True)

save_plot(fig, "/tmp/output.svg")
```

To make this plot:

[![An example plot from the time series notebook library][example_ts]][example_ts]

[example_ts]: {{ file_dir }}/make_collision_in_time.svg

You can read more about it here:

{% capture time_url %}{% post_url 2021-03-14-data_science_timeseries_plotting_notebook_template %}{% endcapture %}
<div class="card-grid">
  {% article_card_lookup url=time_url %}
</div>

## Conclusion

Enjoy the templates, I hope they make you more productive! And if you are
feeling generous, I would love [contributions][submit]!

[submit]: https://github.com/agude/Jupyter-Notebook-Template-Library/issues
