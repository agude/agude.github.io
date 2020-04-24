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

{% include lead_image.html %}

I love Jupyter notebooks (even if [I have strong opinions about their
misuse][nb_post]) and so I use them constantly, both at work and here. They
are the best way to explore a dataset and make visualizations. But my workflow
with notebooks is not very efficient; it is:

[nb_post]: {% post_url 2016-10-17-jupyter_not_for_development %}


1. Start a brand new, _completely empty_ notebook.
2. Load the data and start cleaning it.
3. Begin making plots.
4. Realize I already have some code to make nice plots for a different project.
5. Dig through my repositories looking for the code.
6. Copy and paste the first code I find that sort of does what I need (and
   which probably is not the most recent or nicest version).
7. Hack the code up and make it even uglier.

After five years I am ready for something better. That something is my Jupyter
Notebook Template Library.

# Jupyter Notebook Template Library

The [library][library] is a repository of notebook templates, each targeted at
a different use case. The goal is to allow you to go to one place, find the
right starter notebook, and get right into your work as efficiently as
possible. The library guarantees that your notebook always have the latest and
greatest helper functions without having to dig through your old work.

[library]: https://github.com/agude/Jupyter-Notebook-Template-Library
