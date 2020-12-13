---
layout: post
title: "Data Science Interviews During the 2020 Pandemic"
description: >
  In the middle of the COVID-19 pandemic, I found myself looking for a data
  science job for the third time in my life. This post covers what I learned.
image: /files/2020-interviewing/nighhawks_crop.jpg
image_alt: >
  A crop of Hopper's Nighthawks, showing a man in a suit sitting alone at the
  counter of a diner.
categories:
  - interviewing
---

I started looking for a job this year because Intuit cut my old position as
part of [COVID-related][covid] layoffs. Consequently, I spent the last three
months preparing for and participating in job interviews.

[covid]: https://en.wikipedia.org/wiki/COVID-19_pandemic

The interview process was different from when I first interviewed as a young
data scientist right out of [Insight][insight], and even different from my
more recent interview experiences in 2017.

[insight]: {% post_url 2018-08-21-should_i_go_to_insight %}

## Observations

All of the interviews this year followed [the structure I outlined in my post
on not wasting a candidate's time][interviews], which I appreciated. To summarize, 
that structure is:

[interviews]: {% post_url 2017-09-18-interviews-respect-time %}

- **Prescreen**: A resume or recruiter screen of the candidate, often offline.
- **Technical Screen**: Either a call with a team member or a take-home 
  assignment to assess the candidate's technical skills.
- **On-site Interview Loop**: An all-day interview with multiple team members
  and the hiring manager.

Although all of the companies structured the interviews well, several failed
at the second area I emphasize in my post: **Communication**. One company took
an entire month to convey feedback from an interview step while another did
not get back to me about my on-site until I had emailed them several times.

### Salary Negotiation

The first conversation with every recruiter in 2017 involved talking about
present salary and future expectations. In 2020, not a single recruiter asked
about compensation until after they had made a verbal offer. This surprised me
because waiting to open negotiations until that late in the process offers the
candidate an advantage as they now know that the company has strong interest
in them. Previously I have tried to delay this conversation as long as
possible as part of my negotiation strategy, but this time the recruiters did
it for me!

{% comment %} TODO #45: Update links to negotiation post {% endcomment %}

This behavior might be explained by [California's new law which bans using
salary history to determine an offer][salary_law], but it specifically _does
not_ ban asking about salary expectations. It might be that the more senior
roles I'm interviewing for now are hard enough to find candidates for that the
companies don't want to reject anyone without a chance to get the candidate
[committed to the role][loss].

[salary_law]: https://leginfo.legislature.ca.gov/faces/codes_displaySection.xhtml?sectionNum=432.3&lawCode=LAB
[loss]: https://en.wikipedia.org/wiki/Loss_aversion

### Technical Screens

In 2015 and 2017 I had real trouble with the technical screens. Often they
were stereotypical _engineering_ interviews where I was asked to do something
difficult but irrelevant, like [invert a binary search tree][tweet]. I was
able to solve these problems when I had seen them before in my studies or
could come up with the _"trick"_ on the fly. I passed about half of my
technical screens.

[tweet]: https://twitter.com/mxcl/status/608682016205344768

In 2020, my experience was vastly different. Only one screen was even close to
"invert this BST", and that was a mistake where they later admitted that I was
given the _software engineering_ technical screen by mistake.

All of the other screens involved reasonable questions that would come up in a
data scientist's daily work, like manipulating a dataset, calculating some
features, or implementing really simple algorithms or metrics. With these more
applied questions, I passed all of my technical screens!

### Virtual On-Sites

In 2017 on-sites were on site! In 2020 they are done via video conferencing. I
thought virtual on-sites would be less draining, but I actually felt even more
exhausted after them. However,  I still felt I was able to connect on a
personal level with the interviewers, despite not being in the same place.

#### Whiteboard Coding

There were fewer coding problems during the on-sites than previously and all
of them were done in an online editor instead of on a whiteboard. This worked
great!

I found myself looking forward to the coding challenges because, with the
improvement of coding on **an actual computer**, they were a nice break from
the other interviews. Just like the technical screens, these questions were
all directly applicable to the work I would be doing.

#### Open-ended Problems and Behavioral Questions

This time there were more open-ended interviews that dug into some problem the
business had (for example "How would you help us filter spam?") or went really
deep exploring a project I had worked on previously. Although I was asked some
of these questions during my previous years of interviewing they felt much
more effective in the virtual format, perhaps because the lack of a whiteboard
made it so the interviewer and I had to have a conversation instead of me
giving a lecture.

This round of interviews was the first time I was asked [behavioral
questions][behave]. They were present in three of the five on-sites, including
one company that had 90 minutes of them!

[behave]: https://en.wikipedia.org/wiki/Job_interview#Behavioral_interview_questions

## Results

I applied to seven companies using internal referrals from my network. Here is
how I did during each round:

{% comment %} This allows styling the table text without cutting and pasting a
lot of HTML. {% endcomment %}
{% capture pass %}<span style="color:ForestGreen">Pass</span>{% endcapture %}
{% capture fail %}<span style="color:Red">Reject</span>{% endcapture %}
{% capture declined %}<span style="color:DarkBlue">Declined</span>{% endcapture %}
{% capture accepted %}<span style="color:ForestGreen">Accepted</span>{% endcapture %}

| **Company**      | Prescreen | Technical Screen |                 On-Site |        Offer |
|------------------|----------:|-----------------:|------------------------:|-------------:|
| **DocuSign**     |  {{pass}} |         {{pass}} | {{declined}}[^docusign] |          --- |
| **Grand Rounds** |  {{pass}} |         {{pass}} |                {{fail}} |          --- |
| **Salesforce**   |  {{fail}} |              --- |                     --- |          --- |
| **Square**       |  {{pass}} |         {{pass}} |                {{pass}} | {{accepted}} |
| **Stripe**       |  {{pass}} |         {{pass}} |                {{fail}} |          --- |
| **Twitch**       |  {{pass}} |         {{pass}} |                {{pass}} | {{declined}} |
| **Twitter**      |  {{pass}} |         {{pass}} |                {{fail}} |          --- |

I am very happy with how well the technical screens went this time around, as
mentioned above. I also feel good about the on-site to offer rate, although
more offers would always be better of course.

I felt three interviews went really well: Square, Twitch, and Twitter. I
thought I connected well with the teams and demonstrated that I had the skills
they were looking for. So I was disappointed to not get an offer from Twitter,
but excited for the offers from Square and Twitch.

The Stripe interview revealed the position to be less well aligned with my
skill set[^ab] and career aspirations than I'd hoped, so I think their
decision to not extend an offer was fair.

I generally do not apply to work for startups, for a variety of reasons both
personal and [financial][sense]. However, I agreed to interview at Grand
Rounds after a friend reached out because I did not want to turn down any
opportunities. In the end we all knew it was a bad fit.

[sense]: https://zainamro.com/notes/working-for-a-startup-makes-less-sense

So, after all that, I'm excited to get to work at Square and even more excited
to be done interviewing during a pandemic!

---

[^docusign]: DocuSign and I were unable to schedule an on-site before my other offers would have expired.
[^ab]: The role was a little heavier on [the "analytics" side of data science than the "building" side][ab] which I prefer.

[ab]: https://www.dezyre.com/article/type-a-data-scientist-vs-type-b-data-scientist/194
