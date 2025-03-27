---
layout: post
title: "Introducing the SWITRS SQLite Hosted Dataset"
description: >
  California traffic collision data has been hard to get, that's why I am now
  curating and hosting it! Come take a look!
image: /files/switrs-dataset/tram_auto_crash_in_1957_frederiksplein_amsterdam.jpg
image_alt: >
  A photo of a tram and a delivery van collision in Frederiksplein, Amsterdam,
  1957.
categories: 
  - california-traffic-data 
  - my-projects
---

{% capture file_dir %}/files/switrs-dataset{% endcapture %}

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
[sqlite]: https://en.wikipedia.org/wiki/SQLite

But requesting the data is painful; you have to set up an account with the
state, submit your request via a rough web-form, and wait for them to compile
it. Worse, in the last few years California has _limited the data to 2008 and
later!_

Luckily I have saved all the data I've requested which goes back to January
1st, 2001. So I resolved to make the data easily available to everyone.

## The SWITRS Hosted Dataset

I have combined all of my data requests into one SQLite database. You no
longer have to worry about requesting the data or using my script to clean it
up since I have done all that work for you.

You can **download the datebase** from either [**Kaggle** (requires
account)][db_link] or [**Zenodo** (no account required!)][zen_link] and get
right to work! I have even included a [demo notebook on Kaggle][demo_nb] so
you can jump right in!

[db_link]: https://www.kaggle.com/alexgude/california-traffic-collision-data-from-switrs
[zen_link]: https://zenodo.org/record/4284843
[demo_nb]: https://www.kaggle.com/alexgude/starter-california-traffic-collisions-from-switrs

The dataset also has its own [DOI][doi]: [10.34740/kaggle/dsv/1671261][my_doi]

[doi]: https://en.wikipedia.org/wiki/Digital_object_identifier
[my_doi]: https://www.doi.org/10.34740/kaggle/dsv/1671261

Read on for an example of how to use the dataset and an explanation of how I
created it.

### Data Merging

I have saved four copies of the data, requested in 2016, 2017, 2018, and 2020.
The first three copies have data from 2001 until their request date, while the
2020 dataset only covers 2008--2020 due to the new limit California
instituted. To created the hosted dataset I had to merge these four datasets.
There were two main challenges:

1. Each dataset contains three tables: collision records, party records, and
   victim records; but _only_ the collision records table contains a
   [**primary key**][primary_key]. That key is the `case_id`.

2. The records are occasionally updated after the fact, but again only the
   collision records table has a column (`process_date`) indicating when the
   record was last modified.

[primary_key]: https://en.wikipedia.org/wiki/Primary_key

I made the following assumptions when merging the datasets: 

- The collision records table from the more recent dataset was correct when
  there was a conflict.

- The party records and victim records corresponding to that collision record
  were also the most correct.

These assumptions allowed me to write out the following join logic to create
the hosted set. First I selected `case_id` from each copy of the data,
preferring the newer ones:

```sql
-- Select all from 2020
CREATE TABLE outputdb.case_ids AS 
SELECT case_id, '2020' AS db_year
FROM db20.collision;

-- Now add the rows that don't match from earlier databases, in
-- reverse chronological order so that the newer rows are not
-- overwritten.
INSERT INTO outputdb.case_ids
SELECT * FROM (
    SELECT older.case_id, '2018'
    FROM db18.collision AS older
    LEFT JOIN outputdb.case_ids AS prime
    ON prime.case_id = older.case_id
    WHERE prime.case_id IS NULL
);

-- and the same for 2017 and 2016
```

Then I selected the rows from the collision records, part records, and victim
records that matched for each year:

```sql
CREATE TABLE outputdb.collision AS
SELECT *
FROM db20.collision;

INSERT INTO outputdb.collision
SELECT * FROM (
    SELECT col.*
    FROM db18.collision AS col
    INNER JOIN outputdb.case_ids AS ids
    ON ids.case_id = col.case_id
    WHERE ids.db_year = '2018'
);

-- and similarly for 2017 and 2016, and
-- for party records and victim records
```

The [script to do this is here][script].

[script]: https://github.com/agude/SWITRS-to-SQLite/blob/master/scripts/combine_databases.sql

### Using the dataset

Using the hosted dataset, it is simple to reproduce the work I did when I
announced the data converter script: [plotting the location off all crashes in
California][s2s_plot].

[s2s_plot]: {% post_url 2016-11-01-switrs_to_sqlite %}#crash-mapping-example

Just download the data, unzip it, and run the [notebook][notebook] ([rendered
on Github][rendered]). This will produce the following plot:

{% capture notebook_uri %}{{ "Mapping California Crashes 2001 to 2020.ipynb" | uri_escape }}{% endcapture %} 
[notebook]: {{ file_dir }}/{{ notebook_uri }}
[rendered]: https://github.com/agude/agude.github.io/blob/master{{ file_dir }}/{{ notebook_uri }}

[![A map of the location of all the crashes in the state of California from
2001 to 2020][plot]][plot]

[plot]: {{ file_dir }}/2001-2020_california_traffic_collisions_map.png

I hope this [hosted dataset][db_link] makes working with the data fast and
easy. If you make something, I'd love to see it! Send it to me on BlueSky:
[@{{ site.author.bluesky }}][bluesky]

[bluesky]: https://bsky.app/profile/{{ site.author.bluesky }}
