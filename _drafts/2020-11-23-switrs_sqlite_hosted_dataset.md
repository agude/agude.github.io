---
layout: post
title: "Introducing the SWITRS SQLite Hosted Dataset"
description: >
  California traffic collision data has been hard to get, that's why I am now
  currating and hosting it! Come take a look!
image: /files/switrs_to_sqlite/chp.jpg
image_alt: >
  A sports utility vehicle belonging to the California Highway Patrol is
  parked in front of the Golden Gate Bridge.
redirect_from: /2016/11/01/switrs_to_sqlite/
categories: switrs my_projects
---

{% capture file_dir %}/files/switrs_to_sqlite{% endcapture %}

{% include lead_image.html %}

The State of California maintains a database of traffic collisions called the
[Statewide Integrated Traffic Records System (SWITRS)][switrs]. I have made
extensive use of the data, including:

[switrs]: http://iswitrs.chp.ca.gov/Reports/jsp/userLogin.jsp

- Finding out when [automobiles][car], [motorcycles][moto], and
  [bicycles][bike] crash.
- Quantifying the dangers of [daylight saving time][dst] and the [end of
  daylight saving time][dst_end].

[car]: {% post_url 2016-12-02-switrs_crashes_by_date %}
[moto]: {% post_url 2017-02-21-switrs_motorcycle_crashes_by_date %}
[bike]: {% post_url 2019-02-20-switrs_bicycle_crashes_by_date %}
[dst]: {% post_url 2017-03-20-switrs_daylight_saving_time_accidents %}
[dst_end]: {% post_url 2018-11-03-switrs_daylight_saving_time_end_accidents %}

I even maintain a [helpful script][s2s] to convert the messy CSV files
California will let you download into a clean [SQLite database][sqlite].

[s2s]: {% post_url 2016-11-01-switrs_to_sqlite %}

But requesting the data was painful; you had to set up an account with the
state, submit your request, and wait for them to compile it. Worse, in the
last few years California has limited the data to 2008 and later!

## SWITRS Hosted Dataset

Now I have made it much easier: you can download the already processed
database here: [**TODO**][db_link]

[db_link]: TODO

Read on for an example of how to use the dataset and an explanation of how I
created it.

### Data Merging

I have saved four copies of the data, requested in 2016, 2017, 2018, and 2020.
The first three copies have data from 2001 until their request date, while the
2020 dataset only covers 2008--2020 due to the new limit California
instituted. To created the hosted dataset I had to merge these four datasets.
There were two main challenges:

1. Each dataset contains three tables: collision records, party records, and
   victim records; but _only_ the collision records table contains a [**primary
   key**][primary_key]. That key is the `Case_ID`.
2. The records are occasionally updated after the fact, but again only the
   collision records table has a column (`Process_Date`) indicating when the
   record was last modified.

[primary_key]: https://en.wikipedia.org/wiki/Primary_key

I made the following assumptions when merging the datasets: 

- The collision records table from the more recent datasets were correct when
  there was a conflict.
- The corresponding part records and victim records were also the most
  correct.

These assumptions allowed me to write out the join logic to create the hosted
set. First I selected `Case_ID` from each copy of the data, preferring the
newer ones:

```sql
-- Select all from 2020
CREATE TABLE outputdb.Case_IDs AS 
SELECT Case_ID, '2020' AS db_year
FROM db20.Collision;

-- Now add the rows that don't match from earlier databases, in
-- reverse chronological order so that the newer rows are not
-- overwritten.
INSERT INTO outputdb.Case_IDs
SELECT * FROM (
    SELECT older.Case_ID, '2018'
    FROM db18.Collision AS older
    LEFT JOIN outputdb.Case_IDs AS prime
    ON prime.Case_ID = older.Case_ID
    WHERE prime.Case_ID IS NULL
);

-- and the same for 2017 and 2016
```

Then I selected the rows from the collision records, part records, and victim
records that matched for each year:

```sql
CREATE TABLE outputdb.Collision AS
SELECT *
FROM db20.Collision;

INSERT INTO outputdb.Collision
SELECT * FROM (
    SELECT col.*
    FROM db18.Collision AS col
    INNER JOIN outputdb.Case_IDs AS ids
    ON ids.Case_ID = col.Case_ID
    WHERE ids.db_year = '2018'
);

-- and similarly for 2017 and 2016, and
-- for party records and victim records
```

The [script to do this is here][script].

[script]: TODO

### Using the dataset
