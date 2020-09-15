---
layout: post
title: "Interviewing in 2020: Observations and Thoughts"
description: >
  In the middle of the COVID-19 pandemic, I found myself looking for a data
  science job for the third time in my life. This post covers what I learned.
image: /files/patterns/naturalists_misc_vol_1_painted_snake.jpg
image_alt: >
  A drawing of an orange and black snake from The Naturalist's Miscellany
  Volume 1.
categories: python_patterns
---

{% include lead_image.html %}

Intuit laid off about 700 people across the company September 21st and I was
one of them.

I first interviewed for a job in data science job in 2015 right out of
[Insight][insight]. I interviewed again two years later with a little more
experience and confidence. 

[insight]: {% post_url 2018-08-21-should_i_go_to_insight %}

## Observations

### Salary Negotiation

The first conversation with every recruiter in 2017 involved talking about
present salary and future expectations. In 2020, not a single recruiter asked
about compensation until after they had made a verbal offer. This surprised me
because waiting to open negotiations until that late in the process offers the
candidate an advantage; the company has already spent considerable resources
in interviewing!

<!-- TODO #45: Update links to negotiation post -->

[California's 2018 law banning using salary history to determine an offer
salary][salary_law] could be the reason for this behavior, but it specifically
_does not_ ban asking about salary expectations. It might also be that the
more senior roles I'm interviewing for now are hard enough to hire for that
they do not want to reject candidates without a chance to negotiate.

[salary_law]: https://leginfo.legislature.ca.gov/faces/codes_displaySection.xhtml?sectionNum=432.3&lawCode=LAB

### Technical Phone Screens

In 2015 and 2017 I had real trouble with phone screens. Often they were
stereotypical _engineering_ interviews where I was asked to [invert a binary
search tree][tweet] or some other question that would never come up in my job
as a data scientist. I solved these when I had seen the problem before in my
studies or could come up with the _"trick"_ to solve it efficiently. I passed
about half of my phone screens.

[tweet]: https://twitter.com/mxcl/status/608682016205344768

In 2020, my experience was vastly different. I only got one question that was
even close to "invert this BST", and that was a mistake where I was given the
_software engineering_ phone screen accidentally.

All of the other phone screens involved reasonable questions that would come
up in a data scientist's day to day work like manipulating a dataset,
calculating some simple features, or implementing really simple algorithms or
metrics. With these more applied questions, I passed all of my phone screens!

### Virtual On-Sites

In 2017 on-sites were on site! In 2020 they have moved to being done over
video conferencing. I thought virtual on-sites would be less draining, but I
felt even more exhausted after them. I missed the opportunity to get lunch
with a team member, but I still felt I was able to connect with the
interviewers well.

There were fewer coding problems during the on-sites than previously and all
of them were done in an online editor instead of on a whiteboard. This worked
great! I actually found myself looking forward to the coding challenges
because, with the improvement of coding on _*an actual computer*_ they were a
nice break from the other interviews. Just like the phone screens these
questions were all directly applicable to the work I would be doing.

This time there were more open-ended interviews that dig into some problem the
business may have (like "How would you help us filter spam?") or go really
deep on a project I had worked on previously. I would get some of these
questions during my previous years of interviewing, but they felt much more
effective in the virtual format, perhaps because the lack of a whiteboard made
it so the interviewer and I had to have a conversation instead of me giving a
lecture.

This time interviewing was also the only time that companies asked [behavioral
questions][behave]; three of the five on-sites had them this time.

[behave]: https://en.wikipedia.org/wiki/Job_interview#Behavioral_interview_questions

## Results

I applied to seven companies using internal referrals from my network. Here is
how I did during each round:

{% comment %} This allows styling the table text without cutting and pasting a
lot of HTML. {% endcomment %}
{% capture pass %}<span style="color:ForestGreen">Pass</span>{% endcapture %}
{% capture fail %}<span style="color:Red">Fail</span>{% endcapture %}
{% capture declined %}<span style="color:DarkBlue">Declined</span>{% endcapture %}
{% capture accepted %}<span style="color:ForestGreen">Accepted</span>{% endcapture %}

| **Company**      | Prescreen | Phone Screen |                 On-Site | Offer |
|------------------|----------:|-------------:|------------------------:|------:|
| **DocuSign**     |  {{pass}} |     {{pass}} | {{declined}}[^docusign] |   --- |
| **Grand Rounds** |  {{pass}} |     {{pass}} |                {{fail}} |   --- |
| **Salesforce**   |  {{fail}} |          --- |                     --- |   --- |
| **Square**       |  {{pass}} |     {{pass}} |                {{pass}} |   --- |
| **Stripe**       |  {{pass}} |     {{pass}} |                {{fail}} |   --- |
| **Twitch**       |  {{pass}} |     {{pass}} |                {{pass}} |   --- |
| **Twitter**      |  {{pass}} |     {{pass}} |                {{fail}} |   --- |

I am very happy with how well phone screens went this time around, as
mentioned above. I also feel good about the on-site to offer rate. I felt that
the Twitch, Twitter, and Square interviews all went well, so I am disappointed
by the lack of an offer from Twitter.

The Stripe interview revealed the position to be less well aligned with my
skill set[^2] and career aspirations than I'd hope, so I think the reject
there is fair.

I generally do not apply to work for startups, for a variety of reasons
personal and [financial][sense]. I agreed to interview at Grand Rounds after a
friend reached out because I did not want to turn down any opportunities. In
the end we all knew it was a bad fit.

[sense]: https://zainamro.com/notes/working-for-a-startup-makes-less-sense


I'm excited to get to work at TODO:COMPANY and even more excited to be done
interviewing during a pandemic!

---

[^docusign]: DocuSign and I were unable to schedule an on-site before my other offers would have expired.
[^2]: The role was a little heavier on [the "analytics" side of data science than the "building" side][ab] which I prefer.

[ab]: https://www.dezyre.com/article/type-a-data-scientist-vs-type-b-data-scientist/194
