---
layout: post
title: "Improving An Old Supernova Plot"
description: >
  Test
image: /files/supernova-plot-update/virgo_by_sidney_hall.jpg
image_alt: >
  A drawing by Sidney Hall of the constellation Virgo represented as a Woman
  with angel wings and a pink and green dress.
---


{% capture file_dir %}/files/supernova-plot-update/{% endcapture %}

<!--{% include lead_image.html %}-->

I worked as a [supernova cosmologist][sn_cosmo] when I was an undergraduate,
which was more than ten years ago now. During that time, I made this plot of
the peculiar [supernova 2002cx][2002cx] showing its spectrum at four different
points in time. As I [mentioned in my animated plot post using
supernova][old_post], the spectrum tells us what is going on during the
explosion and what elements are present.

[sn_cosmo]: https://en.wikipedia.org/wiki/Supernova_Cosmology_Project
[2002cx]: https://en.wikipedia.org/wiki/SN_2002cx
[old_post]: {% post_url 2018-04-07-matplotlib_blitting_supernova %}

[![The spectrum of Supernova 2002cx at four different times during the
explosion.][old_supernova]][old_supernova]

[old_supernova]: {{ file_dir }}/SN_2002cx_Spectra_log_old.svg

It is not a bad plot, it conveys the information it is required to, but it has
a lot of opportunities for improvement! Not surprising since it was one of the
first plots I made in my scientific career. The spectra overlap a bit. A lot
of the space is wasted with large margins in order to fit the legend. The axes
titles are wrong and do not include the units they measure. The tick labels
collide at the corner.

The code that generated this plot can be found [here][old_plot_code]
([rendered on Github][old_rendered]). It is not very good, but then I did
write it almost a decade ago.

{% capture old_notebook_uri %}{{ "Old Plot.ipynb" | uri_escape }}{% endcapture %} 
[old_plot_code]: {{ file_dir }}/{{ old_notebook_uri }}
[old_rendered]: https://github.com/agude/agude.github.io/blob/master{{ file_dir }}/{{ old_notebook_uri }}

## Improvements

I had not thought of the plot for years, until I ran into the plot again while
browsing Wikipedia. Fixing it using the experience I have gained since then,
and re-releasing it to the world, seemed like the right thing to do. The
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

Why is this plot an improvement? It fixes the obvious errors and reduces the
clutter and unused space so the information shines through. 

To start, I removed the legend and replaced it with a label by each spectra.
This not only helps you to identify the lines quicker, it cuts down on the
space needed. This let me reduce the margins to just what I need to display
the full range of data.

Then, I fixed the axes labels to the indicate what they measure, for example
adding the units to the x-axis and relaying that it is the log of the flux on
the y-axis with an offset. I also removed the values on the y-axis because
they are meaningless; each spectrum is area normalized and then arbitrarily
offset to prevent them from obscuring each other.

Finally, I cleaned up a couple of things: the spectra no longer overlap, the
axes do not collide, the title and labels are larger to be more readable, and
I removed the spines on the top and right side to reduce the feeling of
clutter.

It is not perfect, I am still missing the units of the flux (because,
honestly, I forgot what they are) after all, but I think it is clearly better.
