---
layout: post
title: "A Career Involves Luck: My Annotated Resume"
description: >
  My career has been a great success so far and a lot of that success has been
  due to luck. In this post I catalog all the lucky breaks I can remember in
  the form of a resume.
image: /files/alt-resumes/landsknecht_playing_dice_by_theodor_alt_1913_sg468z.jpg
image_alt: >
  A pencil drawing of three Landsknecht mercenaries playing dice on top of a
  military snare drum.
categories:
  - career-advice
---

{% capture file_dir %}/files/alt-resumes/{% endcapture %}

<div class="resume" markdown="1">

<div class="fake-h1">Alexander Gude</div>

<div class="subtitle">Lucky Data Scientist / Machine Learning Engineer</div>

## Statement

I am currently a machine learning engineer at a major tech company. My career
has taken a winding path, but I am very happy with where I am and where I am
headed. I have worked hard, but that alone does not explain my success; I have
had many **lucky breaks**, times when some event completely outside of my
control worked out in my favor.

I think it is important to remember that no one is entirely self made; every
career has some element of luck involved. I have cataloged my lucky breaks on
this page in the form of a too-honest resume.

## Education

{% include resume_experience.html
  company="University of California, Berkeley"
  location="Berkeley, CA"
  position="BA, Physics (Honors), College of Letters and Sciences"
  dates="2004--2008"
%}

{% include resume_experience.html
  company="University of Minnesota"
  location="Minneapolis, MN"
  position="PhD, High Energy Particle Physics"
  dates="2009--2015"
%}

- My [GRE score was pretty bad][rejection]. In 2008 I was rejected from every
  grad school I applied to. In 2009, [Yuichi Kubota][yk] saw my application to
  Minnesota and thought "we can give him a shot". He did that for a lot of
  people my year.

[rejection]: {% post_url 2018-03-14-a_career_starts_with_rejection %}#to-grad-school
[yk]: https://www.physics.umn.edu/people/yk.html

## Experience

{% include resume_experience.html
  company="Supernova Cosmology Project"
  location="Berkeley, CA"
  position="Undergraduate Research Assistant"
  dates="2005-2009"
%}

- My friend's aunt worked at Lawrence Berkeley Labs as an executive assistant.
  My resume got passed to her (I don't even recall how exactly) where it
  eventually found its way to the [Supernova Cosmology Project][scp] under
  Nobel prize winner [Saul Perlmutter][saul]. Saul's post doc, Nao Suzuki,
  wanted a research assistant and invited me up to the lab.
- Weirdly, and lucky for me, Nao had decided not to use [IDL][idl_is_bad], the
  standard language for astrophysics software, and instead wanted to work with
  Python. We used Numarray and Numeric (which would later become Numpy),
  giving me a head start in the skills I'd need later for machine learning.
- Nao also thought I should learn a text editor and introduced me to the one
  he used: [Vim][vim]. It is my primary text editor to this day (I'm writing
  this post on it).

[scp]: https://en.wikipedia.org/wiki/Supernova_Cosmology_Project
[saul]: https://en.wikipedia.org/wiki/Saul_Perlmutter
[idl_is_bad]: https://en.wikipedia.org/wiki/IDL_(programming_language)
[vim]: https://en.wikipedia.org/wiki/Vim_(text_editor)

{% include resume_experience.html
  company="Insight Data Science"
  location="Palo Alto, CA"
  position="Data Scientist Fellow"
  dates="2015"
%}

- I had decided not to go through the faculty lottery and was trying to figure
  out my next steps. I was looking through my saved bookmarks one day when I
  clicked on a blog written by my former student instructor at Berkeley,
  [Jessica Kirkpatrick][jessica]. The top post was [_Career Profiles:
  Astronomer to Data Scientist_][jess_post].[^jk_post] Inside was a link to
  Insight Data Science. There were just two days until applications to Insight
  were due so I threw one together and was accepted.
- My advisor told me there was no way I would graduate by January, 2015 (he
  was right). I emailed Insight and asked if I could delay starting until the
  next session. They said yes. I have since learned their policy is not to do
  that. I'm glad someone made an exception.

[jessica]: https://twitter.com/berkeleyjess
[jess_post]: https://berkeleyjess.blogspot.com/2014/07/career-profiles-astronomer-to-data.html

[^jk_post]: The text of [_Career Profiles: Astronomer to Data Scientist_][jess_post]:

    > _What, if any, additional training did you complete in order to meet the
    > qualifications?_
    >
    > 1) I participated in Scicoder where I learned about databases. 
    > 
    > 2) I participated in a consulting internship where I learned about
    > working on interdisciplinary teams, tech/business applications of the
    > scientific method, and working with customers 
    > 
    > 3) I was accepted to (but didn't end up participating in) the **Insight
    > Data Science Fellows Program** where I would have learned more about the
    > transition from academia to tech, the tools used in data science /
    > analytics, and prepared for tech interviews. I got my job offer at
    > Yammer before this internship started so I participated as a
    > mentor/recruiter instead of a fellow.
    
{% include resume_experience.html
  company="Intuit"
  location="Mountain View, CA"
  position="Staff Data Scientist / Senior Data Science Manager"
  dates="2017--2020"
%}

- My manager and director both left Intuit just after I joined, leaving our
  team rudderless. It gave me an opportunity to step into a management role
  first unofficially, and then officially several months later.

{% include resume_experience.html
  company="Cash App"
  location="Remote"
  position="Machine Learning Engineer, Modeler"
  dates="2020--Present"
%}

- While [looking for a job][job] after being laid off during COVID, I called
  my friend and former coworker from Lab41, Patrick Callier, asking if he had
  a lead on any positions at Square. He suggested I should work for Cash App
  and introduced my to my current boss and skip-level (also both Insight
  Alumni). 


[job]: {% post_url 2020-09-21-interviewing_for_data_science_positions_in_2020 %}

</div>
