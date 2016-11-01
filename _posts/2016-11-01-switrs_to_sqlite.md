---
layout: post
title: "Introducing 'SWITRS to SQLite'"
description: >
  The State of California stores information about all the traffic accidents
  in the state in the SWITRS database; this script lets you convert it to SQLite!
image: /files/switrs_to_sqlite/chp.jpg
---

![A CHP cruiser]({{ site.url }}/files/switrs_to_sqlite/chp.jpg)

The State of California maintains a database called the [Statewide Integrated
Traffic Records System
(SWITRS)](http://iswitrs.chp.ca.gov/Reports/jsp/userLogin.jsp). It contains a
record of every traffic accident that has been reported in the state—the time
of the accident, the location, the vehicles involved, and the reason for the
crash. And even better, it is [publicly
available](https://github.com/agude/SWITRS-to-SQLite/blob/master/requesting_data.md)!

Unfortunately, the data is delivered as a set of large [CSV
files](https://en.wikipedia.org/wiki/Comma-separated_values). Normally you
could just load them into [Pandas](http://pandas.pydata.org/), but there is
one, big problem: the data is spread across three files! This means you must
join the rows between them to select the incidents you are looking for. Pandas
can do these joins, but not without overflowing the memory on my laptop. If
only the data were in a proper database!

## SWITRS-to-SQLite

To solve this problem, I wrote
[SWITRS-to-SQLite](https://github.com/agude/SWITRS-to-SQLite).
SWITRS-to-SQLite is a Python script that takes the three CSV files returned by
SWITRS and converts them into a [SQLite3 database](https://sqlite.org/). This
allows you to perform standard [SQL
queries](https://en.wikipedia.org/wiki/SQL) on the data before pulling it into
an analysis system like Pandas. Additionally, the script does some data
cleanup like converting the various null value indicators to a true `NULL`,
and converting the date and time information to a form recognized by SQLite.

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

![A map of the location of all the accidents in the state of California from
2001 to 2016]({{ site.url }}/files/switrs_to_sqlite/switrs_crash_map.png)

There are some weird artifacts and grid patterns that show up which are not
due to our mapping but are inherent in the data. Some further clean up will be
necessary before doing any analysis! A Jupyter notebook used to make the map
can be found [here]({{ site.url }}/files/switrs_to_sqlite/SWITRS Crash Map.ipynb)
([Rendered on
Github](https://github.com/agude/agude.github.io/blob/master/files/switrs_to_sqlite/SWITRS%20Crash%20Map.ipynb)).
