---
layout: post
title: "Making Custom Markdown for Github Pages"
description: >
  I love Markdown, I take all my notes in it and write my blog in it. But
  sometimes you want to create new syntax; read on to find out how!
image: /files/interview-prep/food_conservation_workers_at_comstock_hall_cornell_1917.jpg
image_alt: >
  A black and white photo of four women sitting at desks with typewriters,
  stacks of papers, and card catalogs.
categories:
  - software-development
---

{% capture file_dir %}/files/interview-prep{% endcapture %}

[Markdown] is a great way to write; simple enough to be read as text, with all
the power of HTML. I have been using it for my own notes for a decade and of
course this site is written in Markdown using [Jekyll].

Markdown provides a lot of syntax to simplify HTML, like `**BOLD**` to create
`<strong>BOLD</strong>` text, or `> Quote` to create
`<blockquote>Quote</blockquote>`. Recently, for my [MiniFate] project, I
wanted to add a few custom `<span>` elements to pick out specific pieces of
the text. I could have fallen back to writing it out in HTML eachtime, but
this clashed with how smooth writing Markdown normally is.

[Markdown]: https://en.wikipedia.org/wiki/Markdown
[Jekyll]: https://en.wikipedia.org/wiki/Jekyll_(software)
[MiniFate]: https://github.com/MiniFate/MiniFate

I looked for an alternative and discovered one based on [Anatol Broder][ab]
[Compress] and [Sylvain Durand's][sd] post on [_Improving Typograph on
Jekyll_][it]. It uses [Liquid] to re-write the webpage **after** it has been
compiled, allowing complete control on formatting and allowing you to define
custom Markdown syntax. Here is how it works:

[ab]: https://bro.doktorbro.net/
[Compress]: https://jch.penibelst.de/
[sd]: https://sylvaindurand.org/
[it]: https://sylvaindurand.org/improving-typography-on-jekyll/
[Liquid]: https://shopify.github.io/liquid/
