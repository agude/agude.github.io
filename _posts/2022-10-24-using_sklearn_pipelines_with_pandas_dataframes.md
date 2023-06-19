---
layout: post
title: "Using Scikit-learn Pipelines with Pandas Dataframes"
description: >
  Pandas and scikiet-learn are two important libraries for building machine
  learning models. Here is how to get them to work together.
image: /files/pandas-pipelines/navy_pipes.jpg
image_alt: >
  A black and white photo of a man wearing a naval hat filing the ends of metal
  pipes.
categories:
  - software-development
  - machine-learning
  - machine-learning-engineering
---

{% capture file_dir %}/files/pandas-pipelines/{% endcapture %}

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

## Pandas and Pipelines: Formerly Not So Simple

It used to be tough to use Pandas Dataframes and scikit-learn pipelines
together. There [was a `ColumnTransformer`][col_trans] to work with
dataframes, but it had some major limitations since the output of the
transformer was a numpy array. This meant that if you used a second
`ColumnTransformer` in your pipeline you would get the following error:

[col_trans]: https://scikit-learn.org/stable/modules/generated/sklearn.compose.ColumnTransformer.html#sklearn.compose.ColumnTransformer

```
ValueError: Specifying the columns using strings is
only supported for pandas DataFrames
```

But scikit-learn version 1.2 [updated the pipeline API][pr] to fix this! Now
there is the option to output Pandas dataframes!

[pr]: https://github.com/scikit-learn/scikit-learn/pull/23734

## A working pipeline

Now that the [`set_output` API][setoutput] exists, we can chain
`ColumnTransformer` without error!

[setoutput]: https://scikit-learn.org/dev/auto_examples/miscellaneous/plot_set_output.html

For example, we can impute for one column, and then scale it and a few others.
First we set up the two `ColumnTransformer`, one to impute and one to scale:

```python
# Apply each feature pipeline using a column transform
imputer = (
  "imputer",
  ColumnTransformer(
    [("col_impute", SimpleImputer(), ["x1"])],
    remainder="passthrough",
  ),
)

scaler = (
  "scaler",
  ColumnTransformer(
    [
      (
        "col_scale",
        StandardScaler(),
        ["col_impute__x1", "remainder__x2", "remainder__x3"],
      )
    ],
    remainder="passthrough",
  ),
)
```

Then we combined them in a pipeline:

```python
pipe = Pipeline(
    steps=[
        imputer,
        scaler,
    ]
).set_output(transform="pandas")
```

And it works! There are two tricks; we have to:

1. Make the output of each step a dataframe with `set_output(transform="pandas")`.
2. Adjust the columns names of the downstream steps because they get prepended
   with the name of the previous steps they've gone through.

## Complete Example

Here is a [Jupyter notebook][notebook] ([rendered on Github][rendered])
with a toy dataset and a full Pandas pipeline example. Hope it helps!

{% capture notebook_uri %}{{ "pandas_pipeline_example.ipynb" | uri_escape }}{% endcapture %}

[notebook]: {{ file_dir }}/{{ notebook_uri }}
[rendered]: https://github.com/agude/agude.github.io/blob/master{{ file_dir }}/{{ notebook_uri }}
