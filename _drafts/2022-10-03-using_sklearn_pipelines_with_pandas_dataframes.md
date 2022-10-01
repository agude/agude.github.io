---
layout: post
title: "Using Scikit-learn Pipelines with Pandas Dataframes"
description: >
  When I was young and naive I tried to write very clever code. Here is one of
  the worst examples.
image: /files/worst-code/montreal_light_head_and_power_consolidated_linesmen_1928.jpg
image_alt: >
  A black and white photo of three linesmen repairing a tangle of overhead wires.
categories:
  - software-development
  - machine-learning
---

{% capture file_dir %}/files/worst-code/{% endcapture %}

[Scikit-learn][sklearn] is a popular Python library for training machine
learning models. [Pandas][pandas] is a popular Python library for manipulating
tabular data. They work great together because when you are building a machine
learning model you start by working with the data in Pandas and then when it
is cleaned up you train the model in scikit-learn.

[sklearn]: https://scikit-learn.org
[pandas]: https://pandas.pydata.org/

But one hard thing to do is to make sure you apply the exact same data
manipulating steps to the training set as to the test set and the live data
when the model is deployed. It is very easy to [leak data][leak] or to forget
a step, either of which can ruin your model.

[leak]: https://en.wikipedia.org/wiki/Leakage_(machine_learning)

To help solve this problem, Scikit-learn developed [Pipelines][pipelines].
Pipelines allow you to define a sequence of transforms, including a model
training step, that is easy to apply consistently. This post will go over how
to use Pipelines with Pandas Dataframes.

[pipelines]: https://scikit-learn.org/stable/modules/generated/sklearn.pipeline.Pipeline.html

## Pandas and Pipelines: Not So Simple

It _should_ be simple to use a Pandas dataframe in a pipeline, after all
scikit-learn [has a `ColumnTransformer`][col_trans] to work with dataframe
columns

[col_trans]: https://scikit-learn.org/stable/modules/generated/sklearn.compose.ColumnTransformer.html#sklearn.compose.ColumnTransformer
p

https://scikit-learn.org/stable/auto_examples/compose/plot_column_transformer_mixed_types.html
