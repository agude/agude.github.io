---
layout: post
title: "Jupyter Notebooks: Not for Development"
description: >
  Jupyter Notebooks are great for a lot of things; development of code is not
  one of them.
image: /files/jupyter_dev/red_spot.jpg
image_alt: >
  An image of the planet Jupiter showing the Great Red Spot.
redirect_from: /2016/10/17/jupyter_dev/
categories:
  - jupyter
  - software-development
---

{% capture file_dir %}/files/jupyter_dev{% endcapture %}

[Jupyter Notebooks][jpy] are great! They make it really convenient to tinker
with a new library and are excellent for documenting projects that include
code. What Jupyter Notebooks are not great for, and what I find many people
(including my lab) using them for, is development. There are three reasons for
this:

[jpy]: https://jupyter.org/

### 1. Version Control

Version controlling notebooks is a mess; in addition to code, they also
contain data and output, which results in a high number of changes every time
the notebook is run. Worse, even if the output is identical, things like cell
numbering update every run and so flag the notebook as changed to the version
control system. Further, JSON is already hard to `diff`, and adding these
superfluous changes makes it harder still.

### 2. Modularity

Other code can not easily call code defined in notebooks. This leads to lots
of duplicated code, and means that notebooks need to either appear at the end
of the pipeline or write to disk to pass on data. This lack of modularity also
makes it difficult to write unit tests to verify the correctness of notebook
code.

### 3. Complex History

Notebooks have complicated history; they cache the results of previous cells
including set variables. Notebooks are so flexible that you will often add and
delete cells when working on them, leaving you in a state with impossible to
remember history. This means that unless you have run the notebook from a
fresh kernel it is possible that the results are dependent on now deleted
cells.

## Good Uses

This is not to say that the use of [Jupyter Notebooks should be considered
harmful][harmful]; they are great for:

- **Exploring data:** In-line plots make it very easy to check
  something, make a tweak, and check again. The caching of variables means
  that expensive operations can often be called once and the results used for
  plot after plot.

- **Testing out new libraries:** Notebooks really shorten the time between
  hitting an error, editing, and rerunning code, making them ideal for
  trying out new libraries, classes, and functions.

- **Providing a final deliverable:** Notebooks can include runnable code,
  text, and images so they make an excellent way to document an analysis and
  provide a way for others to interface with it.

[harmful]: https://en.wikipedia.org/wiki/Considered_harmful

So in closing: I use Jupyter Notebooks where they excel---like documenting
analyses for this blog or tweaking algorithms for
[WhereTo.Photo][whereto]---and try to stick to pure code for other cases.

[whereto]: {% post_url 2016-09-22-whereto_photo %}
