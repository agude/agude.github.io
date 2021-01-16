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
wanted to add a few custom `<span>` elements to highlight specific pieces of
the text. I could have fallen back to writing it out in HTML each time, but
this clashed with how smooth writing Markdown normally is.

[Markdown]: https://en.wikipedia.org/wiki/Markdown
[Jekyll]: https://en.wikipedia.org/wiki/Jekyll_(software)
[MiniFate]: https://github.com/MiniFate/MiniFate

I looked for an alternative and discovered one based on [Anatol Broder's][ab]
[Compress] and [Sylvain Durand's][sd] post on [_Improving Typograph on
Jekyll_][it]. It uses [Liquid] to re-write the webpage **after** it has been
compiled, allowing complete control on formatting and allowing you to define
custom Markdown syntax. And since it uses only the default tools in Jekyll, it
works natively on Github Pages! Here is how it works:

[ab]: https://bro.doktorbro.net/
[Compress]: https://jch.penibelst.de/
[sd]: https://sylvaindurand.org/
[it]: https://sylvaindurand.org/improving-typography-on-jekyll/
[Liquid]: https://shopify.github.io/liquid/

## Layouts
The [order of interpretation][ooo] for Jekyll runs Liquid _before_ rendering
Markdown, which means you can't modify the HTML with Liquid. But pushing
content to a layout happens _after_ the HTML is fully rendered, and layouts
can contain their own Liquid, Markdown, and HTML. This allows us to run Liquid
on the fully rendered HTML!

[ooo]: https://jekyllrb.com/tutorials/orderofinterpretation/

We start with a very simple layout placed in `_layouts/substitute.html`:

{% raw %}
```liquid
---
layout: compress
---

<!-- This is the code block to define custom syntax -->
{% assign output = content
    | replace: '-!', '<u>'
    | replace: '!-', '</u>'
%}

{{output}}
```
{% endraw %}

Then we change our primary layout (probably `_layouts/default.html`) to
inherit from `substitute`:

{% raw %}
```html
---
layout: substitute
---

<!DOCTYPE html>
<html lang="en">
  <body>
    <main role="main">
      {{ content }}
    </main>
  </body>
</html>
```
{% endraw %}

And that's it! All the customization is in changing the Liquid in
`substitute.html`. Here are some examples.

### Defining Customer Markup

One thing we can do is define customer markup. Markdown has now syntax for
<u>Underline</u>, but we can define some like this:

{% raw %}
```liquid
{% assign output = content
    | replace: '-!', '<u>'
    | replace: '!-', '</u>'
%}
```
{% endraw %}

Now `-!Underline!-` is compiles to `<u>Underline</u>`. We can define anything
we'd like in the substitution, for example a full `<span>`:

{% raw %}
```liquid
{% assign output = content
    | replace: '-!', '<span class="book-title">'
    | replace: '!-', '</span>'
%}
```
{% endraw %}

Which can be fully customized with CSS.

There are two limitations to this method:

- We have to pick characters that the Markdown parser won't interpreted, so `_` and `*` would not work.
- We need define unique opening and closing syntax to match the opening and
  closing HTML elements.

We can avoid these constraints by overriding standard Markdown syntax.

### Overriding Markdown Syntax

I never use `~~Strike~~`, which insert `<del>Strike</del>` to mark text that
has been removed. Instead I can override it to be <u>Underline</u> as follows:

{% raw %}
```liquid
{% assign output = content
  | replace: '<del>', '<u>'
  | replace: '</del>', '</u>'
%}
```
{% endraw %}

Notice that I don't replace `~~`, I replace `<del>`. This is because the
template Liquid substitutes _after_ the Markdown is compiled to HTML.

### Replacement

Of course we can replace **anything** using this method, not just custom
Markdown syntax or HTML elements. We can define a macro that is replaced by an
image or table. We can even reshape the page, for example, adding an `<hr>`
above the footnotes automatically:

{% raw %}
```liquid
{% assign output = content
  | replace: '<div class="footnotes" role="doc-endnotes">', '<hr><div class="footnotes" role="doc-endnotes">'
%}
```
{% endraw %}

## Conclusion

Using layouts allows us to use the full power of [Liquid] to update our
webpage after the HTML is compiled, and it works natively on Github pages! If
you built 


