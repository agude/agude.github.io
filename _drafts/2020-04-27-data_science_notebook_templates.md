---
layout: post
title: "Jupyter Notebook Templates for Data Science"
description: >
  Jupyter notebooks are great for data exploration; jump start your work with
  this library of userful notebook templates!
image: /files/wayback-machine-archiver/library_of_congress_1902_crop.jpg
image_alt: >
  A photo of the Library of Congress in 1902.
categories: 
  - jupyter
  - my_projects
---

{% include lead_image.html %}

I have [strong opinions about the best use of Jupyter notebooks in data
science][nb_post]. One of those is they are the best way to do data
exploration and visualization, and so I find I use them constantly both at
work and here on my website.

[nb_post]: {% post_url 2016-10-17-jupyter_not_for_development %}

But I am not as efficient as I could be, because this is my workflow:

1. Start a brand new, _completely empty_ notebook.
2. Load the data and start cleaning it.
3. Begin making plots.
4. Realize I already have some code to make nice plots for a different project.
5. Dig through my repositories looking for the code.
6. Copy and paste the first code I find that sort of does what I need (and
   which probably is not the most recent or nicest version).
7. Hack the code up and make it even uglier.

After five years I am tired that, so I've decided to create a set of notebook
templates that collect all my best practices into one place.

# Jupyter Notebook Template Library

The [Jupyter Notebook Template Library][library] contains notebooks that you
can grab and start working with right away. It guarantees that each project
starts with the most recent version of all my helper functions.

[library]: https://github.com/agude/Jupyter-Notebook-Template-Library
