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
ValueError: Specifying the columns using strings is only supported for pandas DataFrames
```

But scikit-learn [just updated their pipeline API][pr] to fix this! Now there
is the option to output Pandas dataframes!

[pr]: https://github.com/scikit-learn/scikit-learn/pull/23734

## A working pipeline

Now that the [`set_output` API][setoutput] exists, we can chain
`ColumnTransformer` without error!

[setoutput]: https://scikit-learn.org/dev/auto_examples/miscellaneous/plot_set_output.html

For example, we can define a pipeline for each group of columns we want to
apply a transform to, like so:

```python
imputation_pipeline = Pipeline(
  steps=[
    ("impute_missing", SimpleImputer()),
    ("standard_scale", StandardScaler()),
  ]
)

scalar_pipeline = Pipeline(
  steps=[
    ("standard_scale", StandardScaler()),
  ]
)
```

Then we apply each of those pipelines to the correct columns using a single
`ColumnTransformer`:

```python
# Apply each feature pipeline using a column transform
col_transform = ColumnTransformer(
  transformers=[
    ("imputation_pipeline", imputation_pipeline, ["num_1"]),
    ("scalar_pipeline", scalar_pipeline, ["num_2", "num_3"],),
  ],
)
```

And then we can even chain another `ColumnTransformer`:

```python
# Use PCA on just some of the columns
col_pca = ColumnTransformer(
  transformers=[
    ("pca", PCA(), ["feature_processing__num_1", "feature_processing__num_2"]),
  ],
)

# Put it all together in a pipeline to train a model
final_pipeline = Pipeline(
  steps=[
    ("feature_processing", col_transform),
    ("reduce_dimensions", col_pca),
    ("train_model", model_training_code_here),
  ]
)

```

The one trick, as you can see, is the columns are renamed based on previous
transformers. So instead of `num_1`, the column is now called
`feature_processing__num_1` since it goes through the `feature_processing`
transform right before the [PCA][pca] step.

[pca]: https://en.wikipedia.org/wiki/Principal_component_analysis

## Complete Example

Here is a [Jupyter notebook][notebook] ([rendered on Github][rendered])
with a toy dataset and a full Pandas pipeline example. Hope it helps!

{% capture notebook_uri %}{{ "pandas_pipeline_example.ipynb" | uri_escape }}{% endcapture %}

[notebook]: {{ file_dir }}/{{ notebook_uri }}
[rendered]: https://github.com/agude/agude.github.io/blob/master{{ file_dir }}/{{ notebook_uri }}
