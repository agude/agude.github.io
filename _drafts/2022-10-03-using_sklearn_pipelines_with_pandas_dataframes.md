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
columns. Just define the transformers and the columns they apply to, then
string them together, right?

[col_trans]: https://scikit-learn.org/stable/modules/generated/sklearn.compose.ColumnTransformer.html#sklearn.compose.ColumnTransformer

```python
step_1 = ColumnTransformer([
  # Name,    Transform,       columns
  ("step_1", SimpleImputer(), ["num_1"]),
])

step_2 = ColumnTransformer([
  ("step_2", StandardScaler(), ["num_1", "num_2"]),
])

pipeline = Pipeline(
  steps=[
    ("step_1", step_1), 
    ("step_2", step_2), 
  ]
)
```

But this won't work. After `step_1`, the Dataframe has been converted to a
Numpy array without column names, so `step_2` will fail.

## A working pipeline

Instead, we have to define a pipeline for each group of columns that has a
unique set of transforms, as detailed in the scikit-learn examples: [_Column
Transformer with Mixed Types_][mixed_types].

[mixed_types]: https://scikit-learn.org/stable/auto_examples/compose/plot_column_transformer_mixed_types.html

We define a pipeline for each group of columns:

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
    ("scalar_pipeline", scalar_pipeline, ["num_2"],),
  ],
)
```

It is unfortunately a little more verbose, but it gets what we need done.

We can even apply another transformation across all the columns, for example a
[principal component analysis][pca] to reduce the dimensions, by wrapping the
above transform in another pipeline:

[pca]: https://en.wikipedia.org/wiki/Principal_component_analysis

```python
# Put it into another pipeline so we can train
final_pipeline = Pipeline(
  steps=[
    ("feature_processing", col_transform),
    ("reduce_dimensions", PCA()),
    ("train_model", model_training_code_here),
  ]
)

```

There is one downside: you can't apply the columnar transforms and then apply
another transform to a different, overlapping subset. At least not easily.

##

```python
# Apply each feature pipeline using a column transform
col_transform = ColumnTransformer(
  transformers=[
    ("numeric_pipeline", numeric_pipeline, ["num1","num2"]),
    ("unordered_categories_pipeline", unordered_categories_pipeline, ["cat1"],),
    ("ordered_categories_pipeline", ordered_categories_pipeline, ["cat2"],),
  ],
  remainder="drop",
)

```
