---
layout: post
title: "Data Science Interview Practice: Data Manipulation"
description: >
image: /files/switrs-dataset/tram_auto_crash_in_1957_frederiksplein_amsterdam.jpg
show_lead_image: True
image_alt: >
categories:
  - career-advice
  - interview-prep
---

<!-- Simple script to call from the "Show/Hide" buttons-->
<script type="text/javascript">
function showhide(d) {
  d.style.display = (d.style.display !== "none") ? "none" : "block";
}
</script>

{% assign twitter-name = site.author.twitter %}

{% capture file_dir %}/files/switrs-dataset{% endcapture %}

I often get asked by newly-minted PhDs trying to get their first job:

> How can I prepare for dataset interviews? Do you have any examples of
> datasets to practice with that you can share?

I never had a good answer. I would tell them a lot about how interviews went,
but I wished I had something to share that they could work with and practice
on.

As of today, that's changing. In this post I put together a series of practice
questions like the kind you might see (or be expected to come up with) in a
hands-on data interview using the [curated and hosted dataset of California
Traffic accidents][switrs_dataset]. The dataset is avaliable for download from
both [Kaggle][kaggle] and [Zenodo][zenodo], and I even have an [example
notebook][example_notebook] for how to work with the data entirely online
within Kaggle.

[switrs_dataset]: {% post_url 2020-11-24-switrs_sqlite_hosted_dataset %}
[kaggle]: https://www.kaggle.com/alexgude/california-traffic-collision-data-from-switrs
[zenodo]: https://zenodo.org/record/4284843
[example_notebook]: https://www.kaggle.com/alexgude/starter-california-traffic-collisions-from-switrs

## Interview Format

As I mentioned in [my post about my last interview experience][last_post],
data science and machine learning interviews have gotten more practical,
covering tasks that we are commonly expected to do instead of hard but
irrelevant problems. One common interview section involves working with a
dataset, answering some simple questions about it, and then building some
simple features.

[last_post]: {% post_url 2020-09-21-interviewing_for_data_science_positions_in_2020 %}

Generally these interviews use Python and [Pandas][pandas] or pure SQL.
Sometimes the interviewer has a set of questions for you to answer and
sometimes they want you to come up with your own.

[pandas]: https://en.wikipedia.org/wiki/Pandas_(software)

I have prepared a set of questions similar to what you would get in a real
interview. For the exercise you will be using the SWITRS dataset. I have included
a notebook to get your start in Pandas or SQL (but with a dataframe as the
output). The solution notebooks can be found at the very end.

Good luck, and if you have any questions or suggestions please reach out to me
on Twitter: [@{{ twitter-name }}][twitter]

[twitter]: https://twitter.com/{{ twitter-name }}

## Questions


### How many collisions are there in the dataset?

A good first thing to check is "How much data am I dealing with?"

<button id="button" onclick="showhide(hidden1)">Show solution</button>
<div class="hidden" id="hidden1" markdown="1" style="display: none;">
```sql
SELECT COUNT(1) AS collision_count
FROM collisions
```
</div>

### How many solo motorcycle accidents are there per year?

Now we're going to look at a subset of the data, so we need to select only the
correct rows. Note, by _solo_ I mean the motorcycle is the only vehicle
involved in the crash.

<button id="button" onclick="showhide(hidden2)">Show solution</button>
<div class="hidden" id="hidden2" markdown="1" style="display: none;">
```sql
SELECT
  strftime('%Y', collision_date) as collision_year,
  count(1) AS collision_count
FROM collisions
WHERE motorcycle_collision = True
  AND party_count = 1
GROUP BY collision_year
ORDER BY collision_year
```
</div>

### What percent of collisions involve males aged 16-25?

Young men are famously unsafe drivers, lets look at how many collisions
they're involved in.

<button id="button" onclick="showhide(hidden3)">Show solution</button>
<div class="hidden" id="hidden3" markdown="1" style="display: none;">
```sql
SELECT
  COUNT(DISTINCT c.case_id) 
  / (SELECT CAST(COUNT(1) AS FLOAT) FROM collisions) AS percentage
FROM collisions AS c
    LEFT JOIN parties AS p
    ON c.case_id = p.case_id
WHERE p.party_sex = 'male'
AND p.party_age BETWEEN 16 AND 25
```
</div>

### What make of vehicle has the largest fraction of accidents on the weekend? During the work week?

Weekdays are generally commute and work traffic, while weekends involves
recreational travel. Do we see different vehicles involved in collisions on
these days?

Only consider vehicle makes with at least 10,000 collisions.

<button id="button" onclick="showhide(hidden4)">Show solution</button>
<div class="hidden" id="hidden4" markdown="1" style="display: none;">
```sql
WITH counter AS (
  SELECT
    p.vehicle_make AS make, 
    SUM(
      CASE WHEN strftime('%w', c.collision_date) IN ('0', '6') THEN 1 ELSE 0 END
    ) AS weekend_count,
    SUM(
      CASE WHEN strftime('%w', c.collision_date) IN ('0', '6') THEN 0 ELSE 1 END
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

This makes sense, Peterbilt is a commercial truck manufacturer which you
expect to be driven for work. Harley-Davidson makes iconic motorcycles that
people ride for fun on the weekend with their friends.

</div>

### How many different values represent "Toyota" in the Parties database? How would you go about correcting for this?

Data is **_never_** as clean as you would hope, even after I [curated it for
you][switrs_dataset]. How many different ways does "Toyota" show up?

What steps would you take to fix this problem?

<button id="button" onclick="showhide(hidden5)">Show solution</button>
<div class="hidden" id="hidden5" markdown="1" style="display: none;">
This is a case where there is no _right_ answer, just more and more correct
the more work you put in. We have to find the values that are likely to
represent "Toyota" and then figure out how to handle them.

A really simple query does pretty well at finding likely candidates:

```sql
SELECT 
  vehicle_make,
  COUNT(1) AS number_seen
FROM parties
WHERE LOWER(vehicle_make) = 'toyota'
  OR LOWER(vehicle_make) LIKE 'toy%'
  OR LOWER(vehicle_make) LIKE 'ty%'
GROUP BY vehicle_make
ORDER BY number_seen DESC;
```

Which gives us this table (truncated):

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

Here is how I would handle it: The top 5 make up the vast majority of entries.
I would fix those by hand and move on.

</div>
