---
layout: post
title: "Vim: I still love hjkl"
description: >
  A lot of Vim users think you grow out of using hjkl for movement. After 17
  years, I haven't. Here's why.
image: /files/hjkl/c_l_sholes_type_writing_machine_patent.jpg
image_alt: >
  A crop of the 1896 patent for the C. L. Sholes Type Writing Machine, showing
  an overhead drawing of the keyboard.
categories:
  - opinions
---

{% capture file_dir %}/files/hjkl{% endcapture %}

I learned Vim in 2005 when I got my first job at Lawrence Berkeley Lab. I
needed to become comfortable working on the command line, which included
editing text files and scripts, so my mentor recommended the text editor he
used: [Vim][vim]. It has been my primary editor ever since.[^neovim]

[^neovim]: At least until 2015, when I switched to [Neovim][neovim]. Neovim is
    a fork of Vim with the goal of creating a modern open source project that
    is easy to contribute to, easy to maintain, and extend, all while adding
    new features and making the editor an embeddable library.

[vim]: https://www.vim.org
[neovim]: https://neovim.io

Most Vim users love tweaking their editor configurations and perfecting their
editing habits. This is referred to as [sharpening their saws][saw] by Drew
Neil. I am no exception of course---I made a [custom color scheme,
*Eldar*][eldar], to make Vim that much more perfect for me---but there is one
area where I am an iconoclast: 

I still love `hjkl`.

Let me explain:

[saw]: http://vimcasts.org/blog/2012/08/on-sharpening-the-saw/
[eldar]: {% post_url 2016-12-23-vim_eldar %}

## Movement

Moving around in Vim is a little different from other programs because there
are so many ways to do it. Most users start with the arrow keys, but they
quickly learn about using `hjkl` to move the cursor. Using `hjkl` might seem
unnatural but it starts the user down the path towards thinking in modes, and
besides it is nice to not have to move your hand off the home row.

Eventually, in the spirit of sharpening their saws, most users learn they can
use search, marks, and GOTOs to more efficiently "jump" to where they want to
go without mashing `jjjjjjjjj`. Some even argue that `hjkl` are irrelevant, as
done [here on Reddit][reddit][^reddit_quote] or [here on Stack Overflow][romainl][^so_quote].

[reddit]: https://www.reddit.com/r/vim/comments/qh0zfz/comment/hia2xmy/?context=3
[romainl]: https://stackoverflow.com/a/26704213/1342354

[^reddit_quote]: Text of the Reddit comment:
    > hjkl are irrelevant, it's like micro movements, I want big fat movements
    > that put exactly where I need to be to do what I want.
    > 
    > Each decision on how to navigate is informed by my intent for when I get
    > there. Snap decisions of course, I'm not sitting there working stuff out, it
    > just is automatic now.
    > 
    > hjkl are just to help you do basic text editing. hjkl vs arrow keys is like
    > asking whether you prefer to crawl or drag yourself in a running race, just
    > learn to run.

[^so_quote]: Text of the Stack Overflow comment:
    > The problem with the arrows is not that they are too far: the problem is
    > that they only allow you to move character-by-character and line-by-line.
    > And guess what? That is exactly what `hjkl` do. The only benefit of `hjkl`
    > over the arrows is that it saves that slight movement of the arm to and from
    > the arrows. Whether you think that benefit is worth the trouble is your
    > call. In my opinion, it isn't.
    > 
    > `hjkl` are only _marginally better_ than the arrows while Vim's more
    > advanced motions, `bBeEwWfFtT,;/?^$` and so on, offer a _huge_ advantage
    > over the arrows and `hjkl`.
    > 
    > FWIW, I use the arrows for small movements, in normal and insert mode, and
    > the advanced motions above for larger motions.
    > 
    > ```
    > mouse-using sucker everyone laughs at:  (move)↓↓↓↓↓↓↓↓↓↓→→→→→(move)
    > hjkl-obsessed hipster:                        jjjjjjjjjjlllll efficient
    > vimmer:                             /fo<CR>
    > ```

And they are right on one point: `hjkl` can't compete on pure speed of
movement. But they wrong when it comes to actually editing code.

## Code Editing

When I am editing code, I am not writing most of the time. I am reading. I am
thinking. I find `hjkl` amazingly effective for this.

Using `hjkl` lets me browse my code line by line, taking in the structure, the
layout, and considering what changes I am going to make. I feel more connected
with the logic of what the code describes than when I'm jumping quickly around
the file.

If you think about it, this is exactly the type of editing Vim was designed
for. Unlike most editors where you can just type and insert characters, Vim
forces you to decide that you are going to make an insertion and then move to
insert mode to do it. Then you immediately leave insert mode. Vim expects you
to spend only part of your time writing, it expects you to spend a lot of
time reading, reorganizing, and navigating your code. And I find the lazy
scrolling of `hjkl` to fit perfectly with this philosophy.
