---
layout: post
title: "How I Work: My Dotfiles"
description: >
image: /files/
image_alt: >
categories: how_i_work
---

{% include lead_image.html %}

I fell in love with using Linux in 2005 when I installed [Ubuntu][ubuntu]
[_Breezy Badger_][bb] alongside Windows XP on my college laptop. I loved the
power it gave me right out of the box with the command line.[^1] For the first
time it felt like I could make my computer do work for me instead of hoping
someone else had already come up with a way to do what I wanted.

[ubuntu]: TODO
[bb]: TODO

Of course, as soon as I got comfortable on the command line, I had to start
customizing. I started hacking my `.vimrc`, my `.bashrc`, everything under
`.config`. Pretty soon I realized customizing my environment wasn't worthwhile
if I couldn't take it with me, and so my dotfiles repository was born.

## My Dotfiles Repo

Most of the customizations for the command line live in hidden files that
begin with a dot, hence dotfiles. And as they are just text, storing them in
git makes perfect sense.

Now setting up my dotfiles on a new machine is as simple as:

{% highlight shell %}
git clone https://github.com/agude/dotfiles .dotfiles
cd .dotfiles
./install.sh
{% endhighlight shell %}

---
[^1]: It didn't hurt that [Amarok][amarok] was an **amazing** music player either.

[amarok]: TODO
