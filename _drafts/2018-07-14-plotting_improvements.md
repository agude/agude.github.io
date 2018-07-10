---
layout: post
title: "Improving An Old Supernova Plot"
description: >
  I learned to use matplotlib more than ten years ago. Around that time, I
  made a plot of supernova 2002cx for Wikipedia, but it was not terrible good.
  So this year, I updated it!
image: /files/supernova-plot-update/virgo_by_sidney_hall.jpg
image_alt: >
  A drawing by Sidney Hall of the constellation Virgo represented as a Woman
  with angel wings and a pink and green dress.
---

{% capture file_dir %}/files/supernova-plot-update/{% endcapture %}

Ten years ago, while an undergraduate, I worked as a [supernova cosmologist][sn_cosmo].
During that time, I made this plot of the peculiar [supernova 2002cx][2002cx] showing its
spectrum at four different points in time. As I [mentioned in my previous post on creating
animated plots (which utilized supernova data in the examples)][old_post], the spectrum
tells us what is going on during the explosion and what elements are present.

[sn_cosmo]: https://en.wikipedia.org/wiki/Supernova_Cosmology_Project
[2002cx]: https://en.wikipedia.org/wiki/SN_2002cx
[old_post]: {% post_url 2018-04-07-matplotlib_blitting_supernova %}

[![The spectrum of Supernova 2002cx at four different times during the
explosion.][old_supernova]][old_supernova]

[old_supernova]: {{ file_dir }}/SN_2002cx_Spectra_log_old.svg

It is not a bad plot---it conveys the information it is required to---but it has
a lot of room for improvement! This shouldn't come as a surprise since it was one of the
earliest plots I made in my scientific career. Some of the shortcomings of the plot include:
- The spectra overlap a bit.
- Poor utilization of available space due to the need for large margins to accomodate the legend.
- The axes titles are wrong and do not include the units they measure.
- The tick labels collide at the corner.

The code that generated this plot can be found [here][old_plot_code]
([rendered on Github][old_rendered]). It is not very good but, in my defense,
it *is* almost a decade old.

{% capture old_notebook_uri %}{{ "Old Plot.ipynb" | uri_escape }}{% endcapture %}
[old_plot_code]: {{ file_dir }}/{{ old_notebook_uri }}
[old_rendered]: https://github.com/agude/agude.github.io/blob/master{{ file_dir }}/{{ old_notebook_uri }}

## Improvements

I had not thought of the plot for years, until I ran into it again while
browsing Wikipedia. Using the experience I have gained since then to fix 
and re-release it to the world seemed like the right thing to do. The
result of my improvements is below:

[![The same spectrum of Supernova 2002cx at four different times during the
explosion, but updated to better convey the information.][new_supernova]][new_supernova]

[new_supernova]: {{ file_dir }}/SN_2002cx_Spectra_log.svg

The code that generated the improved plot can be found [here][new_plot_code]
([rendered on Github][new_rendered]). The code was improved as well, something
I will cover in a future post.

{% capture new_notebook_uri %}{{ "New Plot.ipynb" | uri_escape }}{% endcapture %}
[new_plot_code]: {{ file_dir }}/{{ new_notebook_uri }}
[new_rendered]: https://github.com/agude/agude.github.io/blob/master{{ file_dir }}/{{ new_notebook_uri }}

Why is this plot an improvement? It fixes the obvious errors, and reduces the
clutter and unused space so that the presented information is foremost.

To start, I removed the legend and replaced it with a label next to each spectrum.
This not only helps the reader to quickly identify each line, it also cuts down on the
space needed for supplemntal information. Consequently, the margins can be reduced, allowing
for more of the available space to be used to display the full range of the data.

Then, I fixed the axis labels to indicate what they measure; for example,
adding the units to the x-axis, and relaying that the y-axis is the log of the flux with an offset.
I also removed the values on the y-axis because they are meaningless; each spectrum is area
normalized and then arbitrarily offset to prevent it from obscuring the other spectra.

Finally, I cleaned up a couple of things: the spectra no longer overlap, the
axes do not collide, the title and labels are larger to be more readable, and
I removed the spines on the top and right side to reduce the feeling of
clutter.

It is not perfect---I am still missing the units of the flux (because,
honestly, I forgot what they are)---but I think it is clearly better than the original.
