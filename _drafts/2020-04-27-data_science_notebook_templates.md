---
layout: post
title: "Jupyter Notebook Templates for Data Science"
description: >
  Jupyter notebooks are great for data exploration; jump start your work with
  this library of userful notebook templates!
image: /files/jupyter-library/jupiter_cassini_20001229.jpg
image_alt: >
  A photo of the Library of Congress in 1902.
categories: 
  - jupyter
  - my_projects
---

{% capture file_dir %}/files/jupyter-library/{% endcapture %}

{% include lead_image.html %}

I love Jupyter notebooks (even if [I have strong opinions about their
misuse][nb_post]) and so I use them constantly, both at work and here in my
articles. They are the best way to explore a dataset and make visualizations.
But my workflow with notebooks is not very efficient; it is:

[nb_post]: {% post_url 2016-10-17-jupyter_not_for_development %}


1. Start a brand new, _completely empty_ notebook.
2. Load the data and start cleaning it.
3. Begin making plots.
4. Realize I already have some code to make nice plots for a different project.
5. Dig through my repositories looking for the code.
6. Copy and paste the first code I find that sort of does what I need (and
   which probably is not the most recent or nicest version).
7. Hack the code up and make it even uglier.

After five years I am ready for something better. That something is my [**Jupyter
Notebook Template Library**][library].

## Jupyter Notebook Template Library

The [Jupyter Notebook Template Library][library] is a repository of notebook
templates, each targeted at a different use case. The templates let you get
right to working with the data as quickly as possible. And the library
guarantees that your notebook will always have the latest and greatest helper
functions without having to dig through your old work.

[library]: https://github.com/agude/Jupyter-Notebook-Template-Library

### The Plotting Template

The first notebook in the library is the [**Plotting Template**][plotting].
Its goal is change the above workflow, to this:

1. Download the right template.
2. Load data and start cleaning it.
3. Make **beautiful** plots.

[plotting]: https://github.com/agude/Jupyter-Notebook-Template-Library/blob/8c13dc10c4dbcf724357857692ab7ac64fb83e09/notebooks/basic-plotting-template.ipynb

It lets you write this:

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

And get this:

[![An example plot from the notebook library][example]][example]

[example]: {{ file_dir }}/example_plot.svg

With all the font sizes already set, my patented stripes in the background,
and a focused legend.

Enjoy the templates, I hope they make you more productive! And it you are
feeling generous, I would love [contributions][submit]!

[submit]: https://github.com/agude/Jupyter-Notebook-Template-Library/issues
