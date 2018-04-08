---
layout: post
title: "Rise and Fall of Popular Names"
description: >
  The popularity of baby names rises and falls based on the tastes of each
  generation of parents. Are their preferences the same for boy's names as for
  girl's names? I plot the trends to find out!
image: /files/names/swedish_children.jpg
image_alt: >
  A photo of four Swedish children, two boys and two girls, taken sometime in
  the 1920s. The boys are wearing matching clothes, and the girls are wearing
  matching dresses.
---

{% capture file_dir %}/files/names{% endcapture %}

{% include lead_image.html %}

In the last few years I've named two sons, so I have been thinking about names
a lot. The only constraint my wife and I followed when picking names was that
they should _not_ be too popular! We determine which names to avoid by looking
at data from the [Social Security Administration][ssa], which has kept track
of the name of every child born in the United States since 1880 (as long as at
least 5 people shared the name, for privacy reasons).

[ssa]: https://en.wikipedia.org/wiki/Social_Security_Administration

Most people aren't like my wife and I: the top names are very, very popular!
But how has the popularity of the top names changed over time? I decided to
explore the trends by looking at names that were the most popular in the
United States for at least one year. The data is from the Social Security
Administration, and can be downloaded [here][data]. You can find the Jupyter
notebook used to perform this analysis [here][notebook] ([rendered on
Github][rendered]). The code uses blitting to significantly speed up the
rendering, a [technique I cover in another post][blitting].

{% capture notebook_uri %}{{ "Most Popular Names Blit Same Time.ipynb" | uri_escape }}{% endcapture %}

[data]: https://www.ssa.gov/oact/babynames/names.zip
[notebook]: {{ file_dir }}/{{ notebook_uri }}
[rendered]: https://github.com/agude/agude.github.io/blob/master{{ file_dir }}/{{ notebook_uri }}
[blitting]: {% post_url 2018-04-07-matplotlib_blitting_supernova %}

## Boy's Names

{% capture video_file %}{{ file_dir }}/most_popular_us_boy_names.mp4{% endcapture %}
{% include video.html file=video_file %}

[Click here for a static version of the boy's name plot.][boy_plot]

[boy_plot]: {{ file_dir }}/most_popular_us_boy_names.svg

The plot shows the fraction of boys born in a specific year given one of the
most popular names. When a name is the highest line on the chart, that name is
the most popular name in America during that time. We can not tell from the
plot which name is the second most popular in a given year because I have only
included names that reach the number one spot at some point. For example,
William is the second most popular name in 1920, but because it never reaches
the top spot it is not included in the plot.

Using the plot we can see that the most popular boy's names are timeless; they
retain the top spot for decades, and remain popular even a century later. They
are also [biblical][bible_names], with six out of the seven top names coming
from scripture.

[bible_names]: https://en.wikipedia.org/wiki/List_of_biblical_names

John is the top boy's name for four decades before being replaced by Robert.
Robert keeps the top spot for 16 years before James takes over, which stays at
the top for 14 years. David and Michael rise to peak together, and so the five
names share roughly equal popularity in the late 50s and early 60s.

While the other names decline together, Michael takes off and remains the top
name for almost four decades before being edged out by Jacob. By the time Noah
claims the most popular name title in 2013, all seven of the most popular boy's
names have come down to about the same popularity.

## Girl's Names

{% capture video_file %}{{ file_dir }}/most_popular_us_girl_names.mp4{% endcapture %}
{% include video.html file=video_file %}

[Click here for a static version of the girl's name plot.][girl_plot]

[girl_plot]: {{ file_dir }}/most_popular_us_girl_names.svg

By contrast, the most popular girl's names seem to be driven by fads: Linda,
Lisa, Jennifer, Jessica, and Ashley all have meteoric rises and almost as
rapid falls. In fact, Lisa, Jennifer, and Ashley are so obscure before their
ascendancy that there are entire years where no girls are given those names!

Mary, though, has staying power, with the biblical name holding the top spot
for 67 years before Linda (with the help of a [hit single][linda_song])
unseats it in 1947\. After Linda fades, Mary comes back for a decade before it
finally drops out of the most popular slot for good.

It is not until the late 90s that the fad trend is finally broken, with slow
rising Emily taking the top spot, to be quickly eclipsed by the trio of Emma,
Isabella, and Sophia, which are neck-and-neck through the 2000s.

[linda_song]: https://en.wikipedia.org/wiki/Linda_(1946_song)

## Thoughts and Observations

Why are the most popular girl's names driven by fads, but boy's names are not?
I have a theory: throughout history, far more men have been famous than women.
This shows up in biblical names as well, with Mary being essentially the only
women of importance in the Bible. This allows boy's names to survive
generation to generation as parents look to famous men for inspiration and
used their names. Parents of girls had fewer options, and so new names were
able to fill the void each generation, leading to their quick rise and fall.

One pattern that is evident for both boy's and girl's names is the declining
relative popularity of the top names. In the 1880s, the most popular name for
each gender was given to 8% or 9% of all children born that year! Even into
the 1980s the top names were given to about 4% of children. But now the top
names are given to only 1% of children! It may very well be that the growth of
mass communication---newspapers, then film and radio, followed by television,
and ultimately the Internet---exposed American parents to an ever larger pool
of names, thus allowing diversity to win out in the end.
