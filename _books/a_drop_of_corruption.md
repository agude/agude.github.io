---
date: 2025-04-18 20:31:09 -0700
title: A Drop of Corruption
book_author: Robert Jackson Bennett
series: Shadow of the Leviathan
book_number: 2
rating: 4
image: /books/covers/a_drop_of_corruption.jpg
---

<cite class="book-title">{{ page.title }}</cite>, by <span
class="author-name">{{ page.book_author }}</span>, is the second <span
class="book-series">{{ page.series }}</span> book. This time, Din and Ana
track down a murderer in the northern Kingdom of Yarrow whose brilliance is
almost a match for Ana's own.

{% capture this_book %}<cite class="book-title">{{ page.title }}</cite>{% endcapture %}
{% capture the_author %}<span class="author-name">{{ page.book_author }}</span>{% endcapture %}
{% capture the_authors_lastname %}<span class="author-name">{{ page.book_author | split: " " | last }}</span>{% endcapture %}
{% capture the_authors %}{% include author_link.html name=page.book_author possessive=true %}{% endcapture %}
{% capture the_author_link %}{% include author_link.html name=page.book_author %}{% endcapture %}

{% capture book1 %}{% include book_link.html title="The Tainted Cup"%}{% endcapture %}

{% capture doyles %}{% include author_link.html name="Arthur Conan Doyle" possessive=true %}{% endcapture %}
{% capture final_problem %}{% include book_link.html title="The Final Problem"%}{% endcapture %}

{% capture fdr %}{% include book_link.html title="Fer-de-Lance"%}{% endcapture %}
{% capture nero_wolfe_series %}{% include series_link.html series="Nero Wolfe"%} series{% endcapture %}
{% capture stouts %}{% include author_link.html name="Rex Stout" possessive=true %}{% endcapture %}

{% capture sherlock_series %}{% include series_link.html series="Sherlock Holmes"%} series{% endcapture %}

{% capture martines %}{% include author_link.html name="Arkady Martine" possessive=true %}{% endcapture %}
{% capture empire %}{% include book_link.html title="A Memory Called Empire"%}{% endcapture %}

{% capture shakespeares %}{% include author_link.html name="William Shakespeare" possessive=true %}{% endcapture %}
{% capture macbeth %}{% include book_link.html title="Macbeth"%}{% endcapture %}

{% capture wolfes %}{% include author_link.html name="Gene Wolfe" possessive=true %}{% endcapture %}
{% capture claw %}{% include book_link.html title="The Claw of the Conciliator"%}{% endcapture %}

{% capture wattss %}{% include author_link.html name="Peter Watts" possessive=true %}{% endcapture %}
{% capture echopraxia %}{% include book_link.html title="Echopraxia"%}{% endcapture %}

In {{ this_book }}, Din and Ana travel to Yarrow to solve the murder of a
treasury officer. At first, it looks like the officer was abducted from his
heavily guarded and locked room, but Din and Ana quickly figure out that the
man everyone thought was the official was actually the murderer in disguise.
They realize he's been planning to sabotage the negotiations between the
Empire and Yarrow.

I really enjoyed the mystery and the introduction of a villain who could
challenge Ana's mind.[^moriarty] The slow reveal of the murderer's plot---from
a single killing, to theft, to terrorism meant to destabilize negotiations
between Yarrow and the Empire---kept me frantically turning pages to see what
came next. The fertilizer bomb was an eerie nod to real-world domestic
terrorism. The Shroud---a special containment structure used to butcher
leviathans---and the augurs who bore through the corpses using their
pattern-recognizing brains were fantastic additions to the world.

[^moriarty]:
    Although not quite her Moriarty---Holmes's archenemy from {{ doyles }} {{
    final_problem }}---as the murderer dies at the end of the book.

But I was disappointed by the setting. {{ the_authors_lastname }} made Yarrow
feel much closer to high fantasy as a critique of the genre's obsession with
autocratic rulers. That shift made it lose some of the biopunk weirdness that
made {{ book1 }} so engaging. The book referenced events from the first one,
but without enough context for me to recall them clearly. It's tough to
balance reminding the reader without over-explaining the last book, but it
left me wondering if the author was changing the story or if I'd just
forgotten the details.

The major theme of {{ book1 }} was that a state is made up of its people, and
each has a responsibility to put in the work to maintain it. {{ this_book }}
continues that theme but also adds a focus on the danger of authoritarian
rulers. The King of Yarrow is a slaver whose failures lead to the destruction
of his kingdom and people; the murderer---the pale king---isn't driven by
high-minded ideals but by ordinary greed; and Thelenai, the ranking imperial
in the area, lets her pride push her into reckless decisions that end up
creating the murderer in the first place.

In my review of {{ book1 }}, I said it was a "Holmesian detective story,"
which isn't quite right: {{ the_authors_lastname }} has clarified that he was
inspired by {{ stouts }} {{ nero_wolfe_series }}. I haven't read that series,
but it seems like a better fit.[^nero] Both Nero and Ana are armchair
detectives whose memory-enhanced partners do all the investigating. Clearly,
Ana isn't modeled on Holmes, who traipsed about all over England and Europe
doing much of the legwork himself.[^mycroft]

[^nero]:
    I'm a fan of mystery---I loved the {{ sherlock_series }} as a teen---so I
    might give the first {{ nero_wolfe_series }} book, {{ fdr }}, a try
    sometime soon.

[^mycroft]: Sherlock's older brother, Mycroft, _is_ an armchair detective.

I was reminded of a few previous reads:

- The court intrigue and dying monarch are similar to {{ martines }} {{ empire
  }}.

- Ana eating her grim feast to gain knowledge parallels Severian consuming
  Thecla's flesh to gain her memories in {{ wolfes }} {{ claw }}.

- The three augurs are like the witches in {{ shakespeares }} {{ macbeth }},
  who themselves draw from the three Fates.

- The triumvirate of augurs forming a single mind and being unable to
  communicate with normal humans is like the Bicamerals in {{ wattss }} {{
  echopraxia }}.

Although not as good as {{ book1 }}, I still had fun reading {{ this_book }}.
I'm looking forward to the third book.
