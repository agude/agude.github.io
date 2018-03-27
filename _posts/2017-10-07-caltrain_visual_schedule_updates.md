---
layout: post
title: "Updated Caltrain Visual Schedule"
description: >
  In July, Caltrain updated their weekend schedule to allow time to do track
  work, so I updated my Marey/Ibry/Serjev visual schedules to see how it
  changed!
image: /files/caltrain-schedule/an_outbound_sp_commuter_train_sequence_by_roger_puta.jpg
image_alt: >
  An outbound Southern Pacific Railroad commuter train leaving San Francisco.
  The train is grey with a bright red square painted on the front containing
  the letters "SP" in white.
---

{% capture file_dir %}/files/caltrain-schedule{% endcapture %}

On July 15, 2017, Caltrain changed their weekend schedule in order to allow
construction related to the [Peninsula Corridor Electrification
Project][pcep]. Instead of running hourly, trains now run roughly every 90
minutes---a fact I discovered when I showed up at the [San Antonio
station][sas] on the 15th and learned it would be another 20 minutes before my
train would arrive. This can make it a little frustrating when trying to get
to the city to have [avocado toast][at] with your friends.

[pcep]: https://en.wikipedia.org/wiki/Electrification_of_Caltrain
[sas]: https://en.wikipedia.org/wiki/San_Antonio_station_(Caltrain)
[at]: http://knowyourmeme.com/memes/avocado-toast

A new schedule is not all bad though; it means a chance to reuse the script I
developed to produce [visual schedules for Caltrain][lastpost]. You can find
the notebook [here][notebook] ([rendered on Github][rendered]). The schedule
data is from [Caltrain's developer site][dev].

{% capture notebook_uri %}{{ "20170715-Caltrain Marey Schedule.ipynb" | uri_escape }}{% endcapture %}

[lastpost]: {% post_url 2017-05-21-caltrain_visual_schedule %}
[notebook]: {{ file_dir }}/{{ notebook_uri }}
[rendered]: https://github.com/agude/agude.github.io/blob/master{{ file_dir }}/{{ notebook_uri }}
[dev]: http://www.caltrain.com/developer.html

# Saturday

The top schedule is the new July 15th one, the old schedule is below. Click to
enlarge.

[![Marey visual train schedule for caltrain on Saturday after the July 15 change][saturday_new]][saturday_new]
[![Marey visual train schedule for caltrain on Saturday before the July 15 change][saturday]][saturday]

[saturday]: {{ file_dir }}/caltrain_saturday_20170308.svg
[saturday_new]: {{ file_dir }}/caltrain_saturday_20170715.svg

The frequency of the trains has decreased to every 90 minutes, and the pair of
express trains now spend more time in San Francisco before departing again.
There is also an interesting pair of northbound trains that leave very close
together. These are required to keep the number of trains heading up the
peninsula the same as the number heading down.

# Sunday

Again, the top schedule is the new one, the bottom one is the old schedule.

[![Marey visual train schedule for caltrain on Sunday after the July 15 change][sunday_new]][sunday_new]
[![Marey visual train schedule for caltrain on Sunday before the July 15 change][sunday]][sunday]

[sunday]: {{ file_dir }}/caltrain_sunday_20170308.svg
[sunday_new]: {{ file_dir }}/caltrain_sunday_20170715.svg

The new Sunday schedule is identical to the new Saturday schedule, except that
the first and last northbound trains have been removed, along with the final
two southbound trains. Interestingly, the Sunday trains actually run a bit
later under the new schedule, with the last train leaving Diridon at just past
2200, instead of at 2100.
