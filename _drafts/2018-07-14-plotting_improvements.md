---
layout: post
title: "Improving An Old Supernova Plot"
description: >
  Test
image: /files/supernova/SN_2002cx_Spectra_log_old.svg
image_alt: >
  Test
---

{% capture file_dir %}/files/supernova/{% endcapture %}

<!--{% include lead_image.html %}-->

I worked as a [supernova cosmologist][sn_cosmo] when I was an undergraduate,
which was more than ten years ago now. During that time, I made this plot of
[Supernova 2002cx][2002cx] showing its spectrum at four different points in
time during the explosion. It was one of the earliest plots I mad just after I
learned Python and matplotlib.

[sn_cosmo]: https://en.wikipedia.org/wiki/Supernova_Cosmology_Project
[2002cx]: https://en.wikipedia.org/wiki/SN_2002cx

[![The spectrum of Supernova 2002cx at four different times during the
explosion.][old_supernova]][old_supernova]

[old_supernova]: {{ file_dir }}/SN_2002cx_Spectra_log_old.svg

It is not a bad plot, it conveys the information it is required to, but it has
some problems. The spectra overlap a bit. A lot of the space is wasted with
large margins in order to fit the legend. The axes titles are wrong and do not
include the units they measure. The tick labels collide at the corner.

## Improvements

A few months ago I ran into the plot again while browsing Wikipedia, and
decided to update it using the decade of experience I have gained since. The
result is below:

[![The same spectrum of Supernova 2002cx at four different times during the
explosion, but updated to better convey the information.][new_supernova]][new_supernova]

[new_supernova]: {{ file_dir }}/SN_2002cx_Spectra_log.svg

Why is this plot an improvement? It fixes the obvious errors and reduces the
clutter so the information shines through. 

To start, I removed the legend and replaced it with a label by each spectra.
This not only helps you to identify the lines quicker, it cuts down on the
space needed. This let me cut the margins down to just what I need to display
the full range of data.

Then I fixed the axes labels to the indicate what they measure, for example adding
the units to the x-axis and relaying that it is the log of the flux on the
y-axis with an offset. I also removed the values on the y-axis because they
are meaningless; each spectrum is arbitrarily offset to prevent overlap and
area normalized.

Finally, I cleaned up a couple of things: the spectra no longer overlap, the
axes do not collide, the title and labels are larger to be more readable, and
I removed the spines on the top and right side to reduce the feeling of
clutter.

It is not perfect, I am still missing the units of the flux (because,
honestly, I forgot what they are) after all, but I think it is clearly better.
