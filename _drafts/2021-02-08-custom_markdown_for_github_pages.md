---
layout: post
title: "Making Custom Markdown for Github Pages"
description: >
  I love Markdown, I take all my notes in it and write my blog in it. But
  sometimes you want to create new syntax; read on to find out how!
image: /files/jekyll/stansaab_censor_and_operator.jpg 
image_alt: >
  A black and white photo of a man in a short-sleeve collared shirt uses an
  osciliscope to adjust a circuit board on a Stansaab 'Censor' computer at
  Standard Radio's factory in Ulvsunda, Stockholm.
categories:
  - software-development
---

{% capture file_dir %}/files/jekyll/{% endcapture %}

[Markdown] is a great way to write; simple enough to be read as text, but with
the ability to fall back to full HTML if required. I have been using it for my
own notes for a decade and this site is written in Markdown using [Jekyll].

Markdown provides a lot of syntax to simplify HTML, like `**BOLD**` to create
`<strong>BOLD</strong>` text, or `> Quote` to create
`<blockquote>Quote</blockquote>`. Recently, for my [MiniFate] project, I
wanted to add a few custom `<span>` elements to highlight specific pieces of
the text. I could have fallen back to writing it out in HTML each time, but
doing so felt clunky when compared to how smooth writing Markdown normally is.

[Markdown]: https://en.wikipedia.org/wiki/Markdown
[Jekyll]: https://en.wikipedia.org/wiki/Jekyll_(software)
[MiniFate]: https://github.com/MiniFate/MiniFate

I created a way to define my own syntax based on [Anatol Broder's][ab]
[Compress] and [Sylvain Durand's][sd] post on [_Improving typography on
Jekyll_][it]. It uses [Liquid] to rewrite the web page **after** it has been
compiled, allowing complete control on formatting and allowing you to define
custom Markdown syntax. Since it uses only the default tools built in to
Jekyll, it works natively on [Github Pages]! Here is how it works:

[ab]: https://bro.doktorbro.net/
[Compress]: https://jch.penibelst.de/
[sd]: https://sylvaindurand.org/
[it]: https://sylvaindurand.org/improving-typography-on-jekyll/
[Liquid]: https://shopify.github.io/liquid/
[Github Pages]: https://pages.github.com/

## Layouts

The [order of interpretation][ooi] for to build a page in Jekyll is:

[ooi]: https://jekyllrb.com/tutorials/orderofinterpretation/

1. Substitute site and page variables.
2. Run Liquid functions.
3. Compile Markdown to HTML.
4. Push compiled HTML into its layout template, if there is one.
5. Write to file.

The problem is that Liquid runs before compiling, so we can't use Liquid
code embedded on a page to modify the final HTML. But there is a workaround:
the fully compiled HTML is pushed to a layout (if one is specified) and that
layout restarts the page build order! This means we can modify a page's HTML using Liquid written in the page's
layout template!

To define our custom syntax then, we just need to write a simple layout and
place it in `_layouts/substitute.html`:

{% raw %}
```liquid
{% comment %}
<!-- This is the code block to define custom syntax -->
{% endcomment %}
{% assign output = content
    | replace: '-!', '<u>'
    | replace: '!-', '</u>'
%}

{{output}}
```
{% endraw %}

Here `content` is the special variable that contains the compiled HTML from
the page that is using the template.

We then change our primary layout (probably `_layouts/default.html`) to
inherit from `substitute`:

{% raw %}
```html
---
layout: substitute
---

<!DOCTYPE html>
<html lang="en">
  <body>
    <main>
      {{ content }}
    </main>
  </body>
</html>
```
{% endraw %}

And that's it! All the customization is controlled by changing the Liquid code
in `substitute.html`. Below are some examples.

### Defining Custom Markup

We can now create custom markup. Markdown has no syntax for <u>Underline</u>,
but we can define some like this:

{% raw %}
```liquid
{% assign output = content
    | replace: '-!', '<u>'
    | replace: '!-', '</u>'
%}
```
{% endraw %}

Now `-!Underline!-` compiles to `<u>Underline</u>`. 

But we can go further: we can define anything we'd like in the substitution,
for example a `<span>`:

{% raw %}
```liquid
{% assign output = content
    | replace: '-!', '<span class="book-title">'
    | replace: '!-', '</span>'
%}
```
{% endraw %}

Which can be fully customized with CSS.

This method has two limitations:

- We have to use characters that the Markdown parser won't
  interpreted.[^reserved]
- We need to define unique opening and closing syntax to match the opening and
  closing HTML elements.

[^reserved]:
    This means you can't use `_`, `*`, `` ` ``, and `~~`. Some syntax
    characters like `#`, `>`, and `-` are OK as long as they aren't used at
    the start of a line.

We can avoid these constraints by overriding standard Markdown syntax.

### Overriding Markdown Syntax

I never use `~~Strike~~` in my writing, which inserts `<del>Strike</del>` to
denote text that has been removed. We can override it to insert
<u>Underline</u> instead as follows:

{% raw %}
```liquid
{% assign output = content
  | replace: '<del>', '<u>'
  | replace: '</del>', '</u>'
%}
```
{% endraw %}

Notice that I didn't replace `~~`, I replaced `<del>`. This is because the
template Liquid substitutes _after_ the Markdown is compiled to HTML, and so
`~~` has already been removed from the page.

### Replacement

Of course, we can replace **anything** using this method, not just custom
Markdown syntax or HTML elements. We can define a macro that is replaced by an
image or table. We can even reshape the page, for example, adding an `<hr>`
above the footnotes automatically like this:

{% raw %}
```liquid
{% assign output = content
  | replace: '<div class="footnotes" role="doc-endnotes">', '<hr><div class="footnotes" role="doc-endnotes">'
%}
```
{% endraw %}

## Conclusion

Using layouts gives us the full power of [Liquid] to update our web pages
after the HTML is compiled, and it works natively on Github pages! I hope you
use this to build awesome web pages and if you do let me know on Twitter: [@{{
site.author.twitter }}][twitter]

[twitter]: https://twitter.com/{{ site.author.twitter }}

---
