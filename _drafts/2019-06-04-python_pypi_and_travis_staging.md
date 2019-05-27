---
layout: post
title: "Using Travis Build Stages to Test Multiple Versions"
description: >
  Often when building packages, we want to test against multiple versions of
  the language, and then build the package once. I will show you how using
  Travis Stages.
image: /files/data-science-testing/brick_header.jpg
image_alt: >
  A pile of worn bricks covered in dust and chips of other bricks.
---

{% include lead_image.html %}

I recently finished a new Python program, [`wayback-machine-archiver`][wbma],
which I [describe in detail in another post][wbma_post]. It works on **many**
different versions of Python[^1], so it was 

I also wanted to automatically [publish it on Pypi][wbma_pypi], but only
_after_ all the tests in the many different versions had passed. Running a
bunch of tests, and then deploying you software is exactly what [Travis
Stages][travis_stages] was designed for. There was just one problem: I
couldn't find a good example of how to do it with multiple Python versions.
This post will explain how to do it.

[wbma]: https://github.com/agude/wayback-machine-archiver
[wbma_post]: TODO
[wbma_pypi]: https://pypi.org/project/wayback-machine-archiver/
[travis_stages]: https://docs.travis-ci.com/user/build-stages/

---

[^1]: 2.7, 3.4 through 3.7, the development versions of 3.7 and 3.8, the nightly release, and [pypy 2.7 and 3.5][pypy].

[pypy]: https://pypy.org/
