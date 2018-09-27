---
layout: post
title: "Introducing 'SWITRS to SQLite'"
description: >
  The State of California stores information about all the traffic accidents
  in the state in the SWITRS database; this script lets you convert it to
  SQLite for easy querying!
image: /files/switrs_to_sqlite/chp.jpg
image_alt: >
  A sports utility vehicle belonging to the California Highway Patrol is
  parked in front of the Golden Gate Bridge.
redirect_from: /2016/11/01/switrs_to_sqlite/
categories: switrs
---

{% capture file_dir %}/files/switrs_to_sqlite{% endcapture %}

{% include lead_image.html %}

The State of California maintains a database called the [Statewide Integrated
Traffic Records System (SWITRS)][switrs]. It contains a record of every
traffic accident that has been reported in the state—the time of the accident,
the location, the vehicles involved, and the reason for the crash. And even
better, it is [publicly available][data]!

[switrs]: http://iswitrs.chp.ca.gov/Reports/jsp/userLogin.jsp
[data]: https://github.com/agude/SWITRS-to-SQLite/blob/master/requesting_data.md

Unfortunately, the data is delivered as a set of large [CSV files][csv].
Normally you could just load them into [Pandas][pandas], but there is one, big
problem: the data is spread across three files! This means you must join the
rows between them to select the incidents you are looking for. Pandas can do
these joins, but not without overflowing the memory on my laptop. If only the
data were in a proper database!

[csv]: https://en.wikipedia.org/wiki/Comma-separated_values
[pandas]: https://pandas.pydata.org/

## SWITRS-to-SQLite

To solve this problem, I wrote [SWITRS-to-SQLite][s2s]. SWITRS-to-SQLite is a
Python script that takes the three CSV files returned by SWITRS and converts
them into a [SQLite3 database][sqlite]. This allows you to perform standard
[SQL queries][sql] on the data before pulling it into an analysis system like
Pandas. Additionally, the script does some data cleanup like converting the
various null value indicators to a true `NULL`, and converting the date and
time information to a form recognized by SQLite.

[s2s]: https://github.com/agude/SWITRS-to-SQLite
[sqlite]: https://sqlite.org/
[sql]: https://en.wikipedia.org/wiki/SQL

### Installation and Running

Installation is easy with `pip`:

{% highlight shell %}
pip install switrs-to-sqlite
{% endhighlight %}

Running the script on the downloaded data is simple:

{% highlight shell %}
switrs_to_sqlite \
CollisionRecords.txt \
PartyRecords.txt \
VictimRecords.txt
{% endhighlight %}

This will run for a while (about an hour on my ancient desktop) and produce a
SQLite3 file named `switrs.sqlite3`.

### Accident Mapping Example

Now that we have the SQLite file, let us make a map of all recorded accidents.
We load the file and select all accidents with GPS coordinates as follows:

{% highlight python %}
import pandas as pd
import sqlite3

# Read sqlite query results into a pandas DataFrame
with sqlite3.connect("./switrs.sqlite3") as con:

    query = (
        "SELECT Latitude, Longitude "
        "FROM Collision AS C "
        "WHERE Latitude IS NOT NULL AND Longitude IS NOT NULL"
    )

    # Construct a Dataframe from the results
    df = pd.read_sql_query(query, con)
{% endhighlight %}

Then making a map is simple:

{% highlight python %}
from mpl_toolkits.basemap import Basemap
import matplotlib.pyplot as plt

fig = plt.figure(figsize=(20,20))

map = Basemap(
    projection='gall',
    llcrnrlon = -126,   # lower-left corner longitude
    llcrnrlat = 32,     # lower-left corner latitude
    urcrnrlon = -113,   # upper-right corner longitude
    urcrnrlat = 43,     # upper-right corner latitude
)

x,y = map(df['Longitude'].values, df['Latitude'].values)

map.plot(x, y, 'k.', markersize=1.5)
{% endhighlight %}

This gives us a map of the locations of all the accidents in the state of
California from 2001 to 2016:

[![A map of the location of all the accidents in the state of California from
2001 to 2016][crash_map]][crash_map]

[crash_map]: {{ file_dir }}/switrs_crash_map.png

There are some weird artifacts and grid patterns that show up which are not
due to our mapping but are inherent in the data. Some further clean up will be
necessary before doing any analysis! A Jupyter notebook used to make the map
can be found [here][notebook] ([rendered on Github][rendered]).

{% capture notebook_uri %}{{ "SWITRS Crash Map.ipynb" | uri_escape }}{% endcapture %} 

[notebook]: {{ file_dir }}/{{ notebook_uri }}
[rendered]: https://github.com/agude/agude.github.io/blob/master{{ file_dir }}/{{ notebook_uri }}
