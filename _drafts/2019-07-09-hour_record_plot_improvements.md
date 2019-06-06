---
layout: post
title: "Improving Wikipedia's Hour Record Plot"
description: >
  I learned to use matplotlib more than ten years ago. Around that time, I
  made a plot of supernova 2002cx for Wikipedia, but it was not terrible good.
  So this year, I updated it!
image: /files/hour-record/mens_hour_records_progression.svg
image_alt: >
---

{% capture file_dir %}/files/hour-record/{% endcapture %}

I am a huge fan of cycling.

Here is the progression of the hour record plot from Wikipedia:

{% capture wiki_plot %}{{file_dir}}/Progression_of_Hour_record_from_Merckx_to_Unified.png{% endcapture %}
{% include figure.html
  url=wiki_plot
  image_alt='A dot plot showing the time and distance for various mens hour records.'
  caption='<a href="https://en.wikipedia.org/wiki/File:Progression_of_Hour_record_from_Merckx_to_Unified.png"><em>Progression
  of Hour record from Merckx to Unified</em></a>, © <a
  href="https://en.wikipedia.org/wiki/User:XyZAn">XyZAn</a> (<a
  href="https://creativecommons.org/licenses/by-sa/3.0/deed.en">CC-BY-SA
  3.0</a>)'
%}

This plot gets the message across---the distance went up quickly in a short
amount of time, twice---but could be much more effective. Here are some things
it does poorly:
- Leaves a lot of empty space.
- Missing legend and title.[^1]
- Too much precision in the date labels.
- Too small text.

Here is how I would fix these.

## Improvements

I had not thought of the plot for years, until I ran into it again while
browsing Wikipedia. Using the experience I have gained since then to fix
and re-release it to the world seemed like the right thing to do. The
result of my improvements is below:

[![The same information as above, but using a step plot with better labeling.][my_plot]][my_plot]

[my_plot]: {{ file_dir }}/mens_hour_records_progression.svg

The code that generated the improved plot can be found [here][new_plot_code]
([rendered on Github][new_rendered]).

{% capture new_notebook_uri %}{{ "Hour Record Replot.ipynb" | uri_escape }}{% endcapture %}
[new_plot_code]: {{ file_dir }}/{{ new_notebook_uri }}
[new_rendered]: https://github.com/agude/agude.github.io/blob/master{{ file_dir }}/{{ new_notebook_uri }}

Why is this plot an improvement? It fixes the obvious errors, and reduces the
clutter and unused space so that the presented information is foremost.

The title makes the subject clear: the Progression of the Men's Hour Record.
The legend is pretty minimal, but conveys that there are three different types
of record, and they are each a different color.

The tick labels are now much larger and easier to read. I have changed the
date ticks to every decade, because we do not really care about an exact date,
just a rough time and the ordering. I have also removed the x-axis label
because it is clear that it shows "years".

Using the extra white space, I have added **a lot** more information to the
plot: I have added the name of the rider who set each record, and the distance
they rode. Now you can tell that the great [Eddy Merckx][merckx][^2] set the
record first, and that [Chris Boardman][boardman] set it three times across
two records.

[merckx]: https://en.wikipedia.org/wiki/Eddy_Merckx
[boardman]: https://en.wikipedia.org/wiki/Chris_Boardman

---
[^1]: Plots do not need a title or axis labels if the subject is clear without them. In this case though, you would never figure out it was the "Mens' Hour Record Progression" unless someone told you.
[^2]: The 🐐!
