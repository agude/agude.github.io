---
layout: post
title: "Data Science Interview Practice: Data Manipulation"
description: >
  I often get asked how to practice data science interviews, so here is a
  practice dataset with a set of questions to answer. Good luck!
image: /files/interview-prep/food_conservation_workers_at_comstock_hall_cornell_1917.jpg
image_alt: >
  A black and white photo of four women sitting at desks with typewriters,
  stacks of papers, and card catalogs.
categories:
  - career-advice
  - interviewing
  - interview-prep
---

{% capture file_dir %}/files/interview-prep{% endcapture %}

I often get asked by newly-minted PhDs trying to get their first data job:

> How can I prepare for dataset-based interviews? Do you have any examples of
> datasets to practice with?

I never had a good answer. I would tell them about how the interviews worked,
but I wished I had something to share that they could get their hands on.

As of today, that's changing. In this post I put together a series of practice
questions like the kind you might see (or be expected to come up with) in a
hands-on data interview using the [curated and hosted dataset of California
Traffic accidents][switrs_dataset]. The dataset is available for download from
both [Kaggle][kaggle] and [Zenodo][zenodo], and I even have an [example
notebook][example_notebook] demonstrating how to work with the data entirely
online within Kaggle.

[switrs_dataset]: {% post_url 2020-11-24-switrs_sqlite_hosted_dataset %}
[kaggle]: https://www.kaggle.com/alexgude/california-traffic-collision-data-from-switrs
[zenodo]: https://zenodo.org/record/4284843
[example_notebook]: https://www.kaggle.com/alexgude/starter-california-traffic-collisions-from-switrs

## Interview Format

As I mentioned in [my post about my most recent interview
experience][last_post], data science and machine learning interviews have
become more practical, covering tasks that show up in the day-to-day work of a
data scientist instead of hard but irrelevant problems. One common interview
type involves working with a dataset, answering some simple questions about
it, and then building some simple features.

[last_post]: {% post_url 2020-09-21-interviewing_for_data_science_positions_in_2020 %}

Generally these interviews use Python and [Pandas][pandas] or pure SQL.
Sometimes the interviewer has a set of questions for you to answer and
sometimes they want you to come up with your own.

[pandas]: https://en.wikipedia.org/wiki/Pandas_(software)

To help people prepare, I have created a set of questions similar to what you
would get in a real interview. For the exercise you will be using the SWITRS
dataset. I have included a notebook to get you started in [**SQL**][sql_start]
([rendered on Github][sql_start_rendered]) or [**Pandas**][python_start]
([rendered on Github][python_start_rendered]). The solution notebooks can be
found at the very end and I have included answers in this post, click the
arrow to show them.

{% capture sql_start_notebook_uri %}{{ "Interview Prep SQL.ipynb" | uri_escape }}{% endcapture %}
[sql_start]: {{ file_dir }}/{{ sql_start_notebook_uri }}
[sql_start_rendered]: https://github.com/agude/agude.github.io/blob/master{{ file_dir }}/{{ sql_start_notebook_uri }}

{% capture python_start_notebook_uri %}{{ "Interview Prep Python.ipynb" | uri_escape }}{% endcapture %}
[python_start]: {{ file_dir }}/{{ python_start_notebook_uri }}
[python_start_rendered]: https://github.com/agude/agude.github.io/blob/master{{ file_dir }}/{{ python_start_notebook_uri }}

Good luck, and if you have any questions or suggestions please reach out to me
on Twitter: [@{{ site.author.twitter }}][twitter]

[twitter]: https://twitter.com/{{ site.author.twitter }}

## Questions

### How many collisions are there in the dataset?

<details markdown="1">

<summary markdown="1">
A good first thing to check is "How much data am I dealing with?"
</summary>

Each row in the collisions database represents one collision, so the solution
is nice and short:

```sql
SELECT COUNT(1) AS collision_count
FROM collisions
```

Which returns:

<div class="low-width-table" markdown="1" style="max-width: 20%">

|   collision_count |
|------------------:|
|         9,172,565 |

</div>
</details>

### What percent of collisions involve males aged 16--25?

<details markdown="1">

<summary markdown="1">
Young men are famously unsafe drivers so let's look at how many collisions
they're involved in.
</summary>

The age and gender of the drivers are in the parties table so the query does a
simple filter on those entries. The tricky part comes from needing to
calculate the ratio as this requires us to get the total number of collisions.
We could hard-code the number, but I prefer calculating it as part of the
query. There isn't a super elegant way to do it in SQLite, but a sub-query
works fine. We also have to cast to a float to avoid integer division.

```sql
SELECT 
    COUNT(DISTINCT case_id) 
    / (SELECT CAST(COUNT(DISTINCT case_id) AS FLOAT) FROM parties)
    AS percentage
FROM parties
WHERE party_sex = 'male'
AND party_age BETWEEN 16 AND 25
```

The result is:

<div class="low-width-table" markdown="1" style="max-width: 20%">

|   percentage |
|-------------:|
|        0.242 |

</div>

</details>

### How many solo motorcycle crashes are there per year?

<details markdown="1">

<summary markdown="1">
A "_solo_" crash is one where the driver runs off the road or hits a
stationary object. How many solo motorcycle crashes were there each year? Why
does 2020 seem to (relatively) have so few?
</summary>

To select the right rows we filter with `WHERE` and to get the count per year
we need to use a `GROUP BY`. SQLite does not have a `YEAR()` function, so we
have to use `strftime` instead. In a real interview, you can normally just
assume that the function you need will exist without getting into the
specifics of the SQL dialect.

```sql
SELECT
  STRFTIME('%Y', collision_date) AS collision_year,
  COUNT(1) AS collision_count
FROM collisions
WHERE motorcycle_collision = True
  AND party_count = 1
GROUP BY collision_year
ORDER BY collision_year
```

This gives us:

<div class="low-width-table" markdown="1" style="max-width: 20%">

|   collision_year |   collision_count |
|-----------------:|------------------:|
|             2001 |              3258 |
|             2002 |              3393 |
|             2003 |              3822 |
|             2004 |              3955 |
|             2005 |              3755 |
|             2006 |              3967 |
|             2007 |              4513 |
|             2008 |              4948 |
|             2009 |              4266 |
|             2010 |              3902 |
|             2011 |              4054 |
|             2012 |              4143 |
|             2013 |              4209 |
|             2014 |              4267 |
|             2015 |              4415 |
|             2016 |              4471 |
|             2017 |              4373 |
|             2018 |              4240 |
|             2019 |              3772 |
|             2020 |              2984 |

</div>

The count is low in 2020 primarily because the data doesn't cover the whole
year. It is also low due to the COVID pandemic keeping people off the streets,
at least initially. To differentiate these two causes we could compare month
by month to last year.

</details>

### What make of vehicle has the largest fraction of accidents on the weekend? During the work week?

<details markdown="1">

<summary markdown="1">
Weekdays are generally commute and work-related traffic, while weekends
involves recreational travel. Do we see different vehicles involved in
collisions on these days?

Only consider vehicle makes with at least 10,000 collisions, in order to focus
only on common vehicles where the difference between weekend and weekday usage
will be significant.

</summary>

This query is tricky. We need to aggregate collisions by vehicle make, which
means we need the parties table. We also care about when the crash happened,
which means we need the collisions table. So we need to join these two tables
together.

In an interview setting, I would write two simpler queries: one
that gets the highest weekend fraction and one that gets the highest weekday
fraction with a lot of copy and pasted code. This is a lot easier to work out.
Here is an example of one of those queries:

```sql
SELECT 
  make,
  weekday_count / CAST(total AS FLOAT) AS weekday_ratio
FROM (    
  SELECT
    p.vehicle_make AS make,
    SUM(
      CASE WHEN STRFTIME('%w', c.collision_date) IN ('0', '6') THEN 1 ELSE 0 END
    ) AS weekend_count,
    SUM(
      CASE WHEN STRFTIME('%w', c.collision_date) IN ('0', '6') THEN 0 ELSE 1 END
    ) AS weekday_count,
    count(1) AS total
  FROM collisions AS c
  LEFT JOIN parties AS p
    ON c.case_id = p.case_id
  GROUP BY make
  HAVING total >= 10000
)
ORDER BY weekday_ratio DESC
LIMIT 1
```

Then I would copy and paste this but replace the `weekend_ratio` with a
`weekday_ratio`. It isn't as "elegant" because we have to duplicate code, but
it is easy to write.

Combining the queries is possible. To do so I first use a sub-query to do the
aggregation. A `WTIH` clause keeps it tidy so we don't have to copy/paste the
sub-query twice. I use `HAVING` to filter out makes with too few collisions;
it has to be `HAVING` and not `WHERE` because it filters **after** the
aggregation.

I then construct two queries that read from the sub-query to select the
highest row for the weekend and weekdays. I `UNION` the two queries together
so we end up with a single table containing our results. The double select is
to allow the `ORDER BY` before the `UNION`.

A note: for complicated queries like this one there are always many ways to do
it. I'd love to hear how you got it to work!

```sql
WITH counter AS (
  SELECT
    p.vehicle_make AS make, 
    SUM(
      CASE WHEN STRFTIME('%w', c.collision_date) IN ('0', '6') THEN 1 ELSE 0 END
    ) AS weekend_count,
    SUM(
      CASE WHEN STRFTIME('%w', c.collision_date) IN ('0', '6') THEN 0 ELSE 1 END
    ) AS weekday_count,
    count(1) AS total
  FROM collisions AS c
  LEFT JOIN parties AS p
    ON c.case_id = p.case_id
  GROUP BY make
  HAVING total >= 10000
)

SELECT * FROM (
  SELECT 
    *,
    weekend_count / CAST(total AS FLOAT) AS weekend_fraction,
    weekday_count / CAST(total AS FLOAT) AS weekday_fraction
  FROM counter
  ORDER BY weekend_fraction DESC
  LIMIT 1
)

UNION

SELECT * FROM (
  SELECT 
    *,
    weekend_count / CAST(total AS FLOAT) AS weekend_fraction,
    weekday_count / CAST(total AS FLOAT) AS weekday_fraction
  FROM counter
  ORDER BY weekday_fraction DESC
  LIMIT 1
)
```

Which yields:

| make            |   weekend_count |   weekday_count |   total |   weekend_fraction |   weekday_fraction |
|:----------------|----------------:|----------------:|--------:|-------------------:|-------------------:|
| HARLEY-DAVIDSON |          19,125 |          30,477 |  49,602 |             0.385  |             0.614  |
| PETERBILT       |            6477 |          64,102 |  70,579 |             0.092  |             0.908  |

These results makes sense, Peterbilt is a commercial truck manufacturer which
you expect to be driven for work. Harley-Davidson makes iconic motorcycles
that people ride for fun on the weekend with their friends.

</details>

### How many different values represent "Toyota" in the Parties database? How would you go about correcting for this?

<details markdown="1">

<summary markdown="1">Data is **_never_** as clean as you would hope,  and this applies even to the
[curated SWITRS dataset][switrs_dataset]. How many different ways does
"Toyota" show up?

What steps would you take to fix this problem?
</summary>

This is a case where there is no _right_ answer. You can get a more and more
correct answer as you spend more time, but at some point you have to decide it
is good enough.

The first step is to figure out what values might represent Toyota. I do that
with a few simple `LIKE` filters:

```sql
SELECT 
  vehicle_make,
  COUNT(1) AS number_seen
FROM parties
WHERE LOWER(vehicle_make) = 'toyota'
  OR LOWER(vehicle_make) LIKE 'toy%'
  OR LOWER(vehicle_make) LIKE 'ty%'
GROUP BY vehicle_make
ORDER BY number_seen DESC
```

Which gives us this table (truncated):

<div class="low-width-table" markdown="1" style="max-width: 20%">

| vehicle_make   |   number_seen |
|:---------------|--------------:|
| TOYOTA         |     2,374,621 |
| TOYO           |       166,209 |
| TOYT           |       146,746 |
| TOYOT          |          2823 |
| TOY            |          2262 |
| TOYTA          |           246 |
| TOYOTA/        |           181 |
| TOYTO          |            84 |
| TOYTOA         |            71 |
| TOYOYA         |            66 |
| TOYT.          |            65 |
| TOYA           |            51 |
| TOYTOTA        |            45 |
| TOYOA          |            43 |
| TOYO /         |            39 |
| TOYT /         |            17 |
| TOYT/          |            14 |
| TYMCO          |            13 |
| TOYOTO         |            10 |
| TOY0           |            10 |
| TOYOYTA        |             7 |
| TOYTT          |             6 |
| TOYOY          |             6 |
| TOYOTS         |             5 |
| TYOTA          |             4 |
| ...            |           ... |

</div>

Most of those look like they mean Toyota, although Tymco is a different
company that makes street sweepers.

Here is how I would handle this issue: the top 5 make up the vast majority of
entries. I would fix those by hand and move on. More generally it seems that
makes are represented mostly by their name or a four-letter abbreviation. It
wouldn't be too hard to detect and fix these for the most common makes.

</details>

## Solutions

So that's it! I hope it was useful and you learned something!

Here are my notebooks with the solutions:

- The [SQL solution notebook][sql_answers] ([Rendered on
Github][sql_rendered])
- The [Python/Pandas solution notebook][pandas_answers] ([Rendered on
Github][python_rendered])

[sql_answers]: {{ file_dir }}/Interview Prep SQL Solutions.ipynb
{% capture sql_notebook_uri %}{{ "Interview Prep SQL Solutions.ipynb" | uri_escape }}{% endcapture %}
[sql_rendered]: https://github.com/agude/agude.github.io/blob/master{{ file_dir }}/{{ sql_notebook_uri }}

[pandas_answers]: {{ file_dir }}/Interview Prep Python Solutions.ipynb
{% capture python_notebook_uri %}{{ "Interview Prep Python Solutions.ipynb" | uri_escape }}{% endcapture %}
[python_rendered]: https://github.com/agude/agude.github.io/blob/master{{ file_dir }}/{{ python_notebook_uri }}

Let me know if you find any more elegant solutions!
