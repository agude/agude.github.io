---
layout: post
title: "Rise and Fall of Popular Names"
description: >
  The popularity of baby names rises and falls based on the tastes of each
  generation of parents. Are their preferences the same for boys names as for
  girls names? I plot the trends to find out!
image: /files/names/swedish_children.jpg
---

{% capture file_dir %}{{ site.url }}/files/names{% endcapture %}

![I photo of four Swedish children, two boys and two girls, taken sometime in
the 1920s.]({{ file_dir }}/swedish_children.jpg)

In the last few years I've named two sons, so I have been thinking about names
a lot recently. The only condition my wife and I had when picking names was
that they should _not_ be too popular! We figured out what names to avoid by
looking at data from the [Social Security Administration][ssa], which has kept
track of the name of every child born in the United States since 1880 (as long
as at least 5 people shared the name, for privacy reasons).

[ssa]: https://en.wikipedia.org/wiki/Social_Security_Administration

Most people, it turns out, aren't like my wife and I: the top names are very,
very popular! I decided to look at the *most* popular names for boys and girls
in the United States and see what interesting trends I could pull out. I have
restricted my exploration to only names that were the top most popular boy or
girl name in America for at least one year. The data is from the Social
Security Administration, and can be downloaded [here][data]. You can find the
Jupyter notebook used to perform this analysis [here][notebook] ([rendered on
Github][rendered]). 

[data]: https://www.ssa.gov/oact/babynames/names.zip
[notebook]: {{file_dir}}/Most Popular Names Blit Same Time.ipynb
[rendered]: https://github.com/agude/agude.github.io/blob/master/files/names/Most%20Popular%20Names%20Blit%20Same%20Time.ipynb

## Boys Names

<!--
The top boys names, and the year they first achieved that status, are:

- John (1880)
- Robert (1924)
- James (1940)
- Michael (1954)
- David (1960)
- Jacob (1999)
- Noah (2013)
-->

{% capture video_file %}{{ file_dir }}/most_popular_us_boy_names.mp4{% endcapture %}
{% include video.html file=video_file %}

[Click here for a static version of the boys name plot.][boy_plot]

[boy_plot]: {{ file_dir }}/most_popular_us_boy_names.svg

The most popular boys names are timeless; they retain the top spot for
decades, and remain popular even a century later. They are also
[biblical][bible_names], with six out of the seven top names coming from
scripture.

[bible_names]: https://en.wikipedia.org/wiki/List_of_biblical_names

John is the top boys name for four decades before being replaced by Robert. Robert
keeps the top spot for 16 years before James takes over, which stays at the
top for 14 years. David and Michael rise to peak together, and so the five
names share roughly equal popularity in the late 50s and early 60s.

While the other names decline together, Michael takes off and remains the top
name for almost four decades before being edged out by Jacob. By the time Noah
claims the most popular name title in 2013, all seven of the most popular boys
names have come down to about the same popularity.

## Girls Names

<!--
The top girls names, and the year they first achieved that status, are:

- Mary (1880)
- Linda (1947)
- Lisa (1962)
- Jennifer (1970)
- Jessica (1985)
- Ashley (1991)
- Emily (1996)
- Emma (2008)
- Isabella (2009)
- Sophia (2011)
-->

{% capture video_file %}{{ file_dir }}/most_popular_us_girl_names.mp4{% endcapture %}
{% include video.html file=video_file %}

[Click here for a static version of the girls name plot.][girl_plot]

[girl_plot]: {{ file_dir }}/most_popular_us_girl_names.svg

The most popular girls names are driven by fads: Linda, Lisa, Jennifer,
Jessica, and Ashley all have meteoric rises and almost as rapid falls. In
fact, Lisa, Jennifer, and Ashley are so obscure before their ascendancy that
there are entire years where no girls are given those names!

Mary though has staying power, with the biblical name holding the top spot for
67 years before Linda (with the help of a [hit single][linda_song]) unseats it
in 1947\. After Linda fades, Mary comes back for a decade before it finally
drops out of the most popular slot for good.

It is not until the late 90s that the fad trend is finally broken, with slow
rising Emily taking the top spot, to be quickly eclipsed by the trio of Emma,
Isabella, and Sophia which are neck-and-neck through the 2000s.

[linda_song]: https://en.wikipedia.org/wiki/Linda_(1946_song)

## Common Patterns

Why are the most popular girls names driven by fads, but boys names are not? I
have a theory: throughout history, far more men have been famous than women.
This shows up in biblical names as well, with Mary being essentially the only
women of importance. This allowed boys names to survive generation to
generation as parents look to famous men and use their names. Parents of girls
had fewer options, and so new names were able to fill the void each
generation, leading to the quick rise and fall.


One pattern that is evident for both boys and girls names is the declining
relative popularity of the top names. In the 1880s, the most popular name for
each gender was given to 8% or 9% of all children born that year! Even into
the 1980s the top names were given to about 4% of children. But now the top
names are given to only 1% of children! It seems that diversity won out in the
end.


