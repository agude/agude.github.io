---
layout: post
title: "How Fast Does a Raspberry Pi Reboot?"
description: >
  My Raspberry Pis have to reboot every evening to avoid a memory leak. As
  they say, when you have a memory leak, make animated plots to see how fast
  they reboot!
image: /files/raspberry-pi/raspberry_pi_2_b_by_evan-amos.jpg
image_alt: >
  A photo of a Raspberry Pi 2B computer on a white background.
---

{% capture file_dir %}{{ site.url }}/files/raspberry-pi{% endcapture %}

I own two [Raspberry Pis][pi] which are currently taped to my kitchen
cabinets. They perform a range of tasks that require an always-on, but
low-power, computer. The first one, named [Raspberry Pion][pion],[^1] seeds
open-source torrents 24/7. It is a slightly older (and hence slower)
[Raspberry Pi 2 Model B][pi2]. The second one, named [Raspberry
Kaon][kaon],[^2] runs a VPN that I connect to when using insecure wireless
networks away from home. It is a newer [Raspberry Pi 3 Model B][pi3].

[pi]: https://en.wikipedia.org/wiki/Raspberry_Pi
[pi2]: https://www.raspberrypi.org/products/raspberry-pi-2-model-b/
[pi3]: https://www.raspberrypi.org/products/raspberry-pi-3-model-b/
[pion]: https://twitter.com/RaspberryPion
[kaon]: https://twitter.com/RaspberryKaon

Both computers run [Ubuntu Mate 16.04 for the Raspberry Pi][mate], and both
suffer from a memory leak I have not been able to track down. My solution is
to reboot the computers at 0100 every night using a [cronjob][cron]. They
report their status to Twitter  when they come back online, which lets me know
that they have successfully rebooted and how long it took. [One of my
friends][charles] noticed that Raspberry Pion seemed to take a few seconds
longer than Raspberry Kaon, which prompted me to take a look.

[mate]: https://ubuntu-mate.org/raspberry-pi/
[cron]: https://en.wikipedia.org/wiki/Cron
[charles]: https://twitter.com/charles_uno

You can find the notebook [here][notebook] ([rendered on Github][rendered]).
Pion's tweet data is [here][pion_tweets], and Kaon's tweet data is
[here][kaon_tweets].

[notebook]: {{ file_dir }}/Rasperry Pi Reboot Times.ipynb
[rendered]: https://github.com/agude/agude.github.io/blob/master/files/raspberry-pi/Rasperry%20Pi%20Reboot%20Times.ipynb
[pion_tweets]: {{ file_dir }}/pion_tweets.csv
[kaon_tweets]: {{ file_dir }}/kaon_tweets.csv

## Reboot Times

The Raspberry Pis report the time they come back online to Twitter, [as
follows][example]:

[example]: https://twitter.com/RaspberryKaon/status/929272644498624513

![An example of the status Tweet sent by Raspberry Kaon][tweet]

[tweet]: {{ file_dir }}/20171111_reboot_tweet.png

The clocks on the Raspberry Pis are kept synchronized with a central server
using [NTP][ntp]. The network latency of sending the tweet is not an issue as
the timestamps are generated locally before being sent to Twitter. However,
the two machines differ in more than just their hardware: the Raspberry Pi 2
serves torrents meaning it has hundreds of network connections open which
might slow down its shutdown process. So this is not a completely fair
benchmark.

[ntp]: https://en.wikipedia.org/wiki/Network_Time_Protocol

I pulled down all the reboot announcement tweets from my two Raspberry Pis and
computed the time difference in seconds from 0100. I discarded any difference
over five minutes, as these were primarily cases where the Raspberry Pi
rebooted at some other time of the day. From these I created an animated
histogram comparing the reboot times of the two computers over the 10 months
they have been running. Each month is about one second of animation.

{% capture video_file %}{{ file_dir }}/raspberry_pi_reboot_times_2_vs_3_animation.mp4{% endcapture %}
{% include video.html file=video_file %}

[Here is a static image of the plot][plot] if you prefer.

[plot]: {{ file_dir }}/raspberry_pi_reboot_times_2_vs_3.svg

The Raspberry Pi 2 and 3 reboot with median times of 32 and 29 seconds
respectively. The peaks are quite sharp indicating that the time to reboot is
pretty consistent. There is a peak of fast reboots for the Pi 2 at
about 25 seconds, which seem to come in clumps, which I have no good
explanation for. You can also see when I move apartments in late August; I had
no internet for awhile and so the Raspberry Pis were not plugged in, leading
to a half a second of no updates!

## Animated Plots

A final note about animated plots: I am a huge fan of using animation to
represent the time axis because I think it makes the display of information
more intuitive. Using `FuncAnimation` from `matplotlib` was a bit tough (and I
think my code is far from optimal), but once I got it working it was a lot
faster than rendering the individual frames and creating the video afterwards.
In the future I hope to make more fun animations!

---

[^1]: From [pion][wiki_pion]; physicists have notoriously terrible senses of humor.
[^2]: After the [kaon][wiki_kaon], of course. If I get another, I'll have to name it something like [J/ψ][jpsi], and that just doesn't have the same ring to it.

[wiki_pion]: https://en.wikipedia.org/wiki/Pion
[wiki_kaon]: https://en.wikipedia.org/wiki/Kaon
[jpsi]: https://en.wikipedia.org/wiki/J/psi_meson
