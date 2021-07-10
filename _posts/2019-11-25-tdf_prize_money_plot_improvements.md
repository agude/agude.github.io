---
layout: post
title: "Improving Wikipedia's Tour de France Prize Money Plot"
description: >
  Time to improve another plot from Wikipedia. This time I tackle one showing
  the prize money in the Tour de France over time!
image: /files/tdf-prize-money/godinat_and_level_in_1934.jpg
hide_lead_image: True
image_alt: >
  Black and white photograph of Léon Level and André Godinat looking at a map
  during the Paris–Saint-Etienne race in 1934.
categories:
  - cycling
  - data-visualization
---

{% capture file_dir %}/files/tdf-prize-money/{% endcapture %}

The Tour de France is the most important bike race of the year, and it is
therefore the race with the most prize money awarded. Wikipedia has this plot
showing how that prize money has grown over the years:

{% capture wiki_plot %}{{file_dir}}/TdFPrizeMoney.svg{% endcapture %}
{% include figure.html
  url=wiki_plot
  image_alt="A line plot showing the Total and Winner's prize money in the
  Tour de France over its history."
  caption='<a
  href="https://en.wikipedia.org/wiki/File:TdFPrizeMoney.svg"><em>Prize money in the Tour de France</em></a>, ©<a
  href="https://en.wikipedia.org/wiki/User:EdgeNavidad">EdgeNavidad</a>
  (<a href="https://en.wikipedia.org/wiki/Public_domain">Public Domain</a>)'
%}

The plot is pretty good, at least at first glance! It is (appropriately) a
[log plot][log_wiki].[^exp] It labels all of its pieces. It even has gaps for
when the race was not held. But the plot also has a few problems:

[log_wiki]: https://en.wikipedia.org/wiki/Semi-log_plot
[^exp]: Inflation is exponential.

- The X-axis is wrong; the race did not start before 1900 and the two gaps are
from the World Wars which did not happen in 1898 and 1921.
- The text is too small to read easily at Wikipedia's default 200px image
size.
- The axis labels are redundant and tick labels have a lot of zeroes.

I decided to fix it up using [data from Bike Race Info][bikeraceinfo], like I
did [last time when I fixed the _Hour Record Plot_][lastpost].

[lastpost]: {% post_url 2019-07-09-hour_record_plot_improvements %}
[bikeraceinfo]: https://www.bikeraceinfo.com/tdf/tdf-prizes.html

## Improvements

Here is my version:

[![The same information as above, but using a step plot with better labeling.][my_plot]][my_plot]

[my_plot]: {{ file_dir }}/tdf_prize_money_in_2013_euro.svg

The code that generated the improved plots can be found [here][new_plot_code]
([rendered on Github][new_rendered]). The data [is here][data], and the code
that cleaned the data [is here][data_code] ([rendered on
Github][data_rendered]).

{% capture new_notebook_uri %}{{ "Tour de France Prize Plot.ipynb" | uri_escape }}{% endcapture %}
[new_plot_code]: {{ file_dir }}/{{ new_notebook_uri }}
[new_rendered]: https://github.com/agude/agude.github.io/blob/master{{ file_dir }}/{{ new_notebook_uri }}
[data]: {{ file_dir }}/tdf_prizes_dataframe.json
{% capture data_notebook_uri %}{{ "bikeraceinfo.com Scraper.ipynb" | uri_escape }}{% endcapture %}
[data_code]: {{ file_dir }}/{{ data_notebook_uri }}
[data_rendered]: https://github.com/agude/agude.github.io/blob/master{{ file_dir }}/{{ data_notebook_uri }}


I fixed the X-axis so that the dates are now correct! The first race is in
1903 as expected. I have also removed the axis label because I think the tick
labels make it clear what is plotted. I have added my ([patent pending
😛][pending]) grey stripes to the background to indicate each decade.

[pending]: {% post_url 2020-07-27-data_science_plotting_notebook_template %}#draw-bands

I changed the Y-axis to be more readable by abbreviating the numbers using
_K_ and _M_. I also removed the label and replaced it with the euro symbol (€)
on each tick.

I made all the text larger and the lines thicker to improve legibility when the plot
is downscaled. I have also changed from a line plot to a step plot because the amount 
of prize money changes at specific moments in time, not continually.

Finally, I have cleaned up the data a bit. The original plot used uncorrected
Euro even though the original prizes were in old Franc, new Franc, and Euro
depending on the year. I have normalized all values to
2013 Euro. I have included this information in the subtitle so that it
survives even if the plot is separated from its caption on Wikipedia.

Overall I think it is an improvement, so I have contributed it back to the
community [here][plot_link].

[plot_link]: https://commons.wikimedia.org/wiki/File:Tdf_prize_money_in_2013_euro.svg
