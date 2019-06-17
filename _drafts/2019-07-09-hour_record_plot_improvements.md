---
layout: post
title: "Improving Wikipedia's Hour Record Plot"
description: >
  I learned to use matplotlib more than ten years ago. Around that time, I
  made a plot of supernova 2002cx for Wikipedia, but it was not terrible good.
  So this year, I updated it!
image: /files/hour-record/bicycle_race_by_calvert_litho_co_1895.jpg
image_alt: >
  A chromolithograph showing six men in colorful clothing racing bikes on a
  dirt track.
categories: plotting
---

{% capture file_dir %}/files/hour-record/{% endcapture %}

The [cycling hour record][hour_record] is a grueling experience: the would-be
record setter rides as far as they can in on hour. In the modern era, it was
first set in 1972 by the great [Eddy Merckx][merckx],[^1] and it has traded
hands multiple times since. Wikipedia has a plot showing this progression,
which I have copied below:

[hour_record]: https://en.wikipedia.org/wiki/Hour_record
[merckx]: https://en.wikipedia.org/wiki/Eddy_Merckx

{% capture wiki_plot %}{{file_dir}}/Progression_of_Hour_record_from_Merckx_to_Unified.png{% endcapture %}
{% include figure.html
  url=wiki_plot
  image_alt='A dot plot showing the time and distance for various mens hour records.'
  caption='<a href="https://en.wikipedia.org/wiki/File:Progression_of_Hour_record_from_Merckx_to_Unified.png"><em>Progression
  of Hour record from Merckx to Unified</em></a>, ©<a
  href="https://en.wikipedia.org/wiki/User:XyZAn">XyZAn</a> (<a
  href="https://creativecommons.org/licenses/by-sa/3.0/deed.en">CC-BY-SA
  3.0</a>)'
%}

This plot gets the message across---the distance went up quickly in a short
amount of time, twice---but could be much more effective. Here are some
problems:

- It is missing a legend and title necessary to understand it.[^2]
- Has too much precision in the date labels, which are down to the day but do
  not align with when the records were set.
- The too text is too small to read easily.
- Has a lot of unused space.

I love cycling, and I love plots, so I gave improving it a try.

## Improvements

Here is my version:

[![The same information as above, but using a step plot with better labeling.][my_plot]][my_plot]

[my_plot]: {{ file_dir }}/mens_hour_records_progression.svg

I also made the [same type of plot for the Women's Hour Record progression][women].

[women]: {{ file_dir }}/womens_hour_records_progression.svg

The code that generated the improved plots can be found [here][new_plot_code]
([rendered on Github][new_rendered]). The data [is here][data].

{% capture new_notebook_uri %}{{ "Hour Record Replot.ipynb" | uri_escape }}{% endcapture %}
[new_plot_code]: {{ file_dir }}/{{ new_notebook_uri }}
[new_rendered]: https://github.com/agude/agude.github.io/blob/master{{ file_dir }}/{{ new_notebook_uri }}
[data]: {{ file_dir }}/hour_record_dataframe.json

I added a title and legend. The title makes the subject clear: the Progression
of the Men's Hour Record. The legend is pretty minimal, but conveys that there
are three different types of record, and they are each a different color.

The tick labels are now much larger and easier to read. I have changed the
date ticks to every decade, because we do not really care about an exact date,
just a rough time and the ordering. I have added a light shading for each
decade to make them easier to tell apart. I have also removed the x-axis label
because it is clear that it shows "years".

Using the extra white space, I have added **a lot** more information to the
plot: I have added the name of the rider who set each record, and the distance
they rode. I have also added a line indicating the status of each record at
each point in time, making it easy to see where the record is at any point,
and helping to highlight the times when the record stood for a long time.

This plot took a lot of work to make---matplotlib is not the most forgiving
library---but I think it was worth it.

---
[^1]: The 🐐!
[^2]: Plots do not need a title or axis labels if the subject is clear without them. In this case though, you would never figure out it was the "Mens' Hour Record Progression" unless someone told you.
